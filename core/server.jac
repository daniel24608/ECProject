"""The planner server: stores the trip and exposes it to every client.

This file is the `planner` service app (see jac.toml). The web app, the mobile
app, and the CLI all call the `def:pub` functions below, so they share one
backend and one data store. The planning rules themselves live in the other
core modules; this file only loads data, calls those rules, and saves.

There are no user accounts: `def:pub` calls without a login all use the same
shared graph, so every client sees the same single trip.
"""

import from datetime { date, timedelta }
import from core.models {
    Profile,
    Item,
    Proposal,
    ITEM_KINDS,
    FLAG_VALUES,
    REFUND_POLICIES
}
import from core.budget { Ledger, build_ledger }
import from core.validate { CheckResult, check_item, check_selected }
import from core.risk { RiskFlag, trip_risks }
import from core.backup { find_backup }
import from core.replan { plan_repair }
import from core.compare { Comparison, compare_swap, refund_loss }

"""The one stored trip. It hangs off `root`, which makes it persistent."""
node Trip {
    has profile: Profile,
        items: list[Item],
        proposals: list[Proposal],
        replan_notes: list[str],
        lost_money: float = 0.0,
        next_item_num: int = 1,
        next_proposal_num: int = 1;
}

"""A proposal plus the names and numbers a person needs to decide on it."""
obj ProposalView {
    has num: int = 0,
        source: str = "",
        status: str = "",
        reason: str = "",
        target_num: int = 0,
        target_name: str = "",
        replacement_num: int = 0,
        replacement_name: str = "",
        replacement_date: str = "",
        comparison: Comparison = Comparison();
}

"""Everything a client shows. Every endpoint returns one of these."""
obj TripView {
    has ok: bool = True,
        message: str = "",
        has_trip: bool = False,
        today: str = "",
        profile: Profile = Profile(),
        items: list[Item] = [],
        ledger: Ledger = Ledger(),
        checks: list[CheckResult] = [],
        risks: list[RiskFlag] = [],
        proposals: list[ProposalView] = [],
        replan_notes: list[str] = [];
}

# ---------------------------------------------------------------- helpers

"""Today's date as YYYY-MM-DD."""
def today_text -> str {
    return date.today().isoformat();
}

"""True when `text` is a real date in YYYY-MM-DD format."""
def is_valid_date(text: str) -> bool {
    try {
        _ = date.fromisoformat(text);
        return len(text) == 10;
    } except ValueError {
        return False;
    }
}

"""The stored trip, or None if no trip has been created yet."""
def find_trip -> Trip | None {
    trips = [root -->][?:Trip];
    if len(trips) == 0 {
        return None;
    }
    return trips[0];
}

"""The stored trip, creating an empty one the first time."""
def get_or_create_trip -> Trip {
    trip = find_trip();
    if trip is None {
        trip = Trip(profile=Profile(), items=[], proposals=[], replan_notes=[]);
        root ++> trip;
    }
    return trip;
}

"""Find an item by its number, or None."""
def find_item(items: list[Item], num: int) -> Item | None {
    for item in items {
        if item.num == num {
            return item;
        }
    }
    return None;
}

"""Find a proposal by its number, or None."""
def find_proposal(proposals: list[Proposal], num: int) -> Proposal | None {
    for proposal in proposals {
        if proposal.num == num {
            return proposal;
        }
    }
    return None;
}

"""Store the lists again so the database saves the changed items."""
def save_lists(trip: Trip, items: list[Item], proposals: list[Proposal]) {
    trip.items = list(items);
    trip.proposals = list(proposals);
}

"""Add a new pending proposal to the list and give it the next number."""
def add_proposal(
    trip: Trip,
    proposals: list[Proposal],
    source: str,
    target_num: int,
    replacement_num: int,
    reason: str
) {
    proposals.append(
        Proposal(
            num=trip.next_proposal_num,
            source=source,
            target_num=target_num,
            replacement_num=replacement_num,
            reason=reason,
            status="pending"
        )
    );
    trip.next_proposal_num = trip.next_proposal_num + 1;
}

"""Item numbers that already have a pending repair proposal."""
def nums_with_pending_repair(proposals: list[Proposal]) -> list[int] {
    nums: list[int] = [];
    for proposal in proposals {
        if proposal.source == "repair" and proposal.status == "pending" {
            nums.append(proposal.target_num);
        }
    }
    return nums;
}

"""Replacements the traveler already rejected for one target item."""
def rejected_for(proposals: list[Proposal], target_num: int) -> list[int] {
    nums: list[int] = [];
    for proposal in proposals {
        if proposal.target_num == target_num and proposal.status == "rejected" {
            nums.append(proposal.replacement_num);
        }
    }
    return nums;
}

"""Why an item needs a Plan B: its risk flags and failed checks, joined."""
def plan_b_reason(trip: Trip, item: Item, risks: list[RiskFlag]) -> str {
    reasons: list[str] = [];
    for flag in risks {
        if flag.item_num == item.num {
            reasons.append(flag.reason);
        }
    }
    check = check_item(trip.profile, item);
    for text in check.reasons {
        reasons.append(text);
    }
    return "; ".join(reasons);
}

"""Rebuild the pending Plan B suggestions.

Old pending backups are dropped and new ones are made for every planned item
that has a risk flag or does not pass the hard filters. A replacement the
traveler already rejected is not suggested again for the same item.
"""
def refresh_backups(trip: Trip) {
    kept: list[Proposal] = [];
    for proposal in trip.proposals {
        is_pending_backup = proposal.source == "backup" and proposal.status == "pending";
        if not is_pending_backup {
            kept.append(proposal);
        }
    }

    # Number the new suggestions right after the proposals we kept.
    trip.next_proposal_num = 1;
    for proposal in kept {
        if proposal.num >= trip.next_proposal_num {
            trip.next_proposal_num = proposal.num + 1;
        }
    }

    risks = trip_risks(trip.profile, trip.items, trip.lost_money, today_text());
    skip_targets = nums_with_pending_repair(kept);
    for item in trip.items {
        if not item.selected or item.disrupted or item.num in skip_targets {
            continue;
        }
        reason = plan_b_reason(trip, item, risks);
        if reason == "" {
            continue;
        }
        skip_nums = rejected_for(kept, item.num);
        backup = find_backup(trip.profile, trip.items, item, skip_nums, "");
        if backup is not None {
            add_proposal(trip, kept, "backup", item.num, backup.num, reason);
        }
    }
    trip.proposals = kept;
}

"""Build the view a client shows, with fresh ledger, checks, risks, and comparisons."""
def build_view(trip: Trip | None, ok: bool, message: str) -> TripView {
    today = today_text();
    if trip is None {
        return TripView(ok=ok, message=message, has_trip=False, today=today);
    }

    proposal_views: list[ProposalView] = [];
    for proposal in trip.proposals {
        if proposal.status != "pending" {
            continue;
        }
        target = find_item(trip.items, proposal.target_num);
        replacement = find_item(trip.items, proposal.replacement_num);
        if target is None or replacement is None {
            continue;
        }
        proposal_views.append(
            ProposalView(
                num=proposal.num,
                source=proposal.source,
                status=proposal.status,
                reason=proposal.reason,
                target_num=target.num,
                target_name=target.name,
                replacement_num=replacement.num,
                replacement_name=replacement.name,
                replacement_date=replacement.date,
                comparison=compare_swap(trip.items, trip.lost_money, target, replacement)
            )
        );
    }

    return TripView(
        ok=ok,
        message=message,
        has_trip=True,
        today=today,
        profile=trip.profile,
        items=trip.items,
        ledger=build_ledger(trip.profile, trip.items, trip.lost_money),
        checks=check_selected(trip.profile, trip.items),
        risks=trip_risks(trip.profile, trip.items, trip.lost_money, today),
        proposals=proposal_views,
        replan_notes=trip.replan_notes
    );
}

"""A view that only reports an error and changes nothing."""
def error_view(message: str) -> TripView {
    return build_view(find_trip(), False, message);
}

"""Turn "vegetarian, nut allergy" into ["vegetarian", "nut allergy"]."""
def split_list(text: str) -> list[str] {
    parts: list[str] = [];
    for piece in text.split(",") {
        cleaned = piece.strip();
        if cleaned != "" {
            parts.append(cleaned);
        }
    }
    return parts;
}

"""Check the profile form. Returns an error message, or "" when it is fine."""
def profile_error(profile: Profile) -> str {
    if profile.destination.strip() == "" {
        return "Destination is required.";
    }
    if not is_valid_date(profile.start_date) or not is_valid_date(profile.end_date) {
        return "Dates must look like YYYY-MM-DD.";
    }
    if profile.end_date < profile.start_date {
        return "The end date is before the start date.";
    }
    if profile.budget <= 0 {
        return "Budget must be more than 0.";
    }
    if profile.contingency_percent < 0 or profile.contingency_percent >= 100 {
        return "Contingency percent must be between 0 and 99.";
    }
    if profile.travelers < 1 {
        return "There must be at least 1 traveler.";
    }
    return "";
}

"""Check a new item. Returns an error message, or "" when it is fine."""
def item_error(item: Item) -> str {
    if item.kind not in ITEM_KINDS {
        return "Type must be one of: " + ", ".join(ITEM_KINDS) + ".";
    }
    if item.name.strip() == "" {
        return "Name is required.";
    }
    if not is_valid_date(item.date) {
        return "Date must look like YYYY-MM-DD.";
    }
    if item.cost < 0 or item.taxes_fees < 0 {
        return "Cost and taxes/fees cannot be negative.";
    }
    flags = [item.pet_friendly, item.kid_friendly, item.accessible, item.diet_friendly];
    for flag in flags {
        if flag not in FLAG_VALUES {
            return "Friendly/accessible flags must be yes, no, or unknown.";
        }
    }
    if item.refund_policy not in REFUND_POLICIES {
        return "Refund policy must be one of: " + ", ".join(REFUND_POLICIES) + ".";
    }
    if item.cancel_deadline != "" and not is_valid_date(item.cancel_deadline) {
        return "Cancellation deadline must look like YYYY-MM-DD (or be empty).";
    }
    return "";
}

# ---------------------------------------------------------------- endpoints

"""Return the current trip with its ledger, checks, risks, and proposals."""
def:pub get_trip -> TripView {
    return build_view(find_trip(), True, "");
}

"""Create (or replace) the trip profile. Clears all items and proposals.

Dietary needs may arrive as one comma-separated entry from a form, so they
are joined and split again into a clean list.
"""
def:pub init_trip(new_profile: Profile) -> TripView {
    profile = Profile(
        destination=new_profile.destination.strip(),
        start_date=new_profile.start_date.strip(),
        end_date=new_profile.end_date.strip(),
        budget=float(new_profile.budget),
        contingency_percent=float(new_profile.contingency_percent),
        travelers=int(new_profile.travelers),
        with_kids=new_profile.with_kids,
        with_pet=new_profile.with_pet,
        dietary_needs=split_list(", ".join(new_profile.dietary_needs)),
        needs_accessibility=new_profile.needs_accessibility
    );
    problem = profile_error(profile);
    if problem != "" {
        return error_view(problem);
    }

    trip = get_or_create_trip();
    trip.profile = profile;
    trip.items = [];
    trip.proposals = [];
    trip.replan_notes = [];
    trip.lost_money = 0.0;
    trip.next_item_num = 1;
    trip.next_proposal_num = 1;
    return build_view(trip, True, "Trip to " + profile.destination + " created.");
}

"""Add a hotel, flight, or activity typed in by the user.

The server gives the item its number and cleans up the text fields.
An item with `selected` False is kept as an option only.
"""
def:pub add_item(new_item: Item) -> TripView {
    trip = find_trip();
    if trip is None {
        return error_view("Create a trip first.");
    }
    item = Item(
        num=trip.next_item_num,
        kind=new_item.kind.strip().lower(),
        name=new_item.name.strip(),
        city=new_item.city.strip(),
        date=new_item.date.strip(),
        cost=float(new_item.cost),
        taxes_fees=float(new_item.taxes_fees),
        pet_friendly=new_item.pet_friendly.strip().lower(),
        kid_friendly=new_item.kid_friendly.strip().lower(),
        accessible=new_item.accessible.strip().lower(),
        diet_friendly=new_item.diet_friendly.strip().lower(),
        refund_policy=new_item.refund_policy.strip().lower(),
        cancel_deadline=new_item.cancel_deadline.strip(),
        fixed=new_item.fixed,
        selected=new_item.selected,
        disrupted=False
    );
    problem = item_error(item);
    if problem != "" {
        return error_view(problem);
    }

    items = list(trip.items);
    items.append(item);
    trip.items = items;
    trip.next_item_num = trip.next_item_num + 1;
    refresh_backups(trip);
    return build_view(trip, True, "Added #" + str(item.num) + " " + item.name + ".");
}

"""Mark a planned item as disrupted and propose repairs for it and later items."""
def:pub disrupt_item(num: int) -> TripView {
    trip = find_trip();
    if trip is None {
        return error_view("Create a trip first.");
    }
    item = find_item(trip.items, num);
    if item is None {
        return error_view("There is no item #" + str(num) + ".");
    }
    if not item.selected or item.disrupted {
        return error_view("Item #" + str(num) + " is not an active part of the plan.");
    }

    item.disrupted = True;
    result = plan_repair(trip.profile, trip.items, item);

    # Old pending suggestions for this item no longer apply.
    proposals: list[Proposal] = [];
    for proposal in trip.proposals {
        if proposal.status == "pending" and proposal.target_num == num {
            continue;
        }
        proposals.append(proposal);
    }
    for swap in result.swaps {
        add_proposal(
            trip, proposals, "repair", swap.target_num, swap.replacement_num, swap.reason
        );
    }

    save_lists(trip, trip.items, proposals);
    trip.replan_notes = result.notes;
    refresh_backups(trip);
    message = item.name + " marked as disrupted. " + str(len(result.swaps)) + " repair(s) proposed.";
    return build_view(trip, True, message);
}

"""Accept a proposal: the replacement joins the plan and the old item leaves it.

Only the stored (simulated) trip changes; nothing is really booked. Any money
the old item's refund policy says is lost is remembered in the ledger.
"""
def:pub accept_proposal(num: int) -> TripView {
    trip = find_trip();
    if trip is None {
        return error_view("Create a trip first.");
    }
    proposal = find_proposal(trip.proposals, num);
    if proposal is None or proposal.status != "pending" {
        return error_view("There is no pending proposal #" + str(num) + ".");
    }
    target = find_item(trip.items, proposal.target_num);
    replacement = find_item(trip.items, proposal.replacement_num);
    if target is None or replacement is None {
        return error_view("Proposal #" + str(num) + " points to a missing item.");
    }

    (loss, _known) = refund_loss(target);
    trip.lost_money = trip.lost_money + loss;
    target.selected = False;
    replacement.selected = True;
    proposal.status = "accepted";

    # Other pending proposals about these two items are now out of date.
    proposals: list[Proposal] = [];
    for other in trip.proposals {
        touches_same_item = (
            other.target_num == target.num
            or other.replacement_num == replacement.num
            or other.target_num == replacement.num
        );
        if other.status == "pending" and other.num != num and touches_same_item {
            continue;
        }
        proposals.append(other);
    }
    save_lists(trip, trip.items, proposals);
    refresh_backups(trip);
    message = "Accepted: " + replacement.name + " replaces " + target.name + ".";
    return build_view(trip, True, message);
}

"""Reject a proposal. The plan itself does not change."""
def:pub reject_proposal(num: int) -> TripView {
    trip = find_trip();
    if trip is None {
        return error_view("Create a trip first.");
    }
    proposal = find_proposal(trip.proposals, num);
    if proposal is None or proposal.status != "pending" {
        return error_view("There is no pending proposal #" + str(num) + ".");
    }
    proposal.status = "rejected";
    save_lists(trip, trip.items, trip.proposals);
    return build_view(trip, True, "Rejected proposal #" + str(num) + ". The plan is unchanged.");
}

# ---------------------------------------------------------------- sample data

"""A date `days` from today, as YYYY-MM-DD."""
def days_from_today(days: int) -> str {
    return (date.today() + timedelta(days=days)).isoformat();
}

"""The sample items: four planned items, then five options to choose from."""
def sample_items(start: int) -> list[Item] {
    day0 = days_from_today(start);
    day1 = days_from_today(start + 1);
    day2 = days_from_today(start + 2);
    day3 = days_from_today(start + 3);
    return [
        # Planned items.
        Item(
            kind="flight", name="TAP 204 Detroit to Lisbon", city="Lisbon",
            date=day0, cost=1100.0, taxes_fees=120.0, kid_friendly="yes",
            diet_friendly="yes", refund_policy="non-refundable"
        ),
        Item(
            kind="hotel", name="Alfama Family Suites", city="Lisbon",
            date=day0, cost=640.0, taxes_fees=60.0, kid_friendly="yes",
            diet_friendly="yes", refund_policy="partial",
            cancel_deadline=days_from_today(3)
        ),
        Item(
            kind="activity", name="Oceanarium tickets", city="Lisbon",
            date=day1, cost=80.0, kid_friendly="yes", diet_friendly="yes",
            refund_policy="refundable", fixed=True
        ),
        Item(
            kind="activity", name="Sintra palace day tour", city="Sintra",
            date=day2, cost=150.0, taxes_fees=10.0, kid_friendly="unknown",
            diet_friendly="yes", refund_policy="unknown"
        ),
        # Options that are not in the plan yet.
        Item(
            kind="flight", name="United 88 Detroit to Lisbon (next day)",
            city="Lisbon", date=day1, cost=980.0, taxes_fees=110.0,
            kid_friendly="yes", diet_friendly="yes", refund_policy="refundable",
            selected=False
        ),
        Item(
            kind="hotel", name="Baixa Budget Inn", city="Lisbon", date=day1,
            cost=420.0, taxes_fees=40.0, kid_friendly="yes", diet_friendly="yes",
            refund_policy="refundable", selected=False
        ),
        Item(
            kind="hotel", name="Rossio Adults-Only Boutique", city="Lisbon",
            date=day0, cost=300.0, taxes_fees=30.0, kid_friendly="no",
            diet_friendly="yes", refund_policy="refundable", selected=False
        ),
        Item(
            kind="activity", name="Sintra family tour", city="Sintra", date=day3,
            cost=170.0, taxes_fees=10.0, kid_friendly="yes", diet_friendly="yes",
            refund_policy="refundable", selected=False
        ),
        Item(
            kind="activity", name="Tram 28 ride", city="Lisbon", date=day2,
            cost=20.0, kid_friendly="unknown", diet_friendly="yes",
            refund_policy="refundable", selected=False
        )
    ];
}

"""Replace the trip with a sample Lisbon trip so the demo is instant.

Dates are relative to today so the 7-day deadline rule always has something
to flag.
"""
def:pub seed_trip -> TripView {
    start = 30;
    profile = Profile(
        destination="Lisbon, Portugal",
        start_date=days_from_today(start),
        end_date=days_from_today(start + 4),
        budget=4000.0,
        contingency_percent=10.0,
        travelers=2,
        with_kids=True,
        with_pet=False,
        dietary_needs=["vegetarian"],
        needs_accessibility=False
    );
    view = init_trip(profile);
    if not view.ok {
        return view;
    }
    for item in sample_items(start) {
        add_item(item);
    }
    return build_view(find_trip(), True, "Loaded the sample Lisbon trip.");
}
