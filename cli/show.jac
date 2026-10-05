"""Printing helpers for the CLI. They only format data; no planning logic."""

import from core.views { TripView, ProposalView }

"""Money as text, for example 1234.5 -> "$1,234.50"."""
def money(amount: float) -> str {
    if amount < 0 {
        return "-$" + f"{-amount:,.2f}";
    }
    return "$" + f"{amount:,.2f}";
}

"""Print the server's message, marked as an error when the call failed."""
def show_message(view: TripView) {
    if view.message == "" {
        return;
    }
    if view.ok {
        print(view.message);
    } else {
        print("Error: " + view.message);
    }
}

"""Print the trip profile and the budget ledger."""
def show_summary(view: TripView) {
    profile = view.profile;
    print("");
    print("Trip to " + profile.destination + "  (" + profile.start_date + " to " + profile.end_date + ")");
    needs: list[str] = [];
    if profile.with_kids {
        needs.append("kids");
    }
    if profile.with_pet {
        needs.append("pet");
    }
    if profile.needs_accessibility {
        needs.append("accessibility");
    }
    for diet in profile.dietary_needs {
        needs.append(diet);
    }
    needs_text = ", ".join(needs) if len(needs) > 0 else "none";
    print("Travelers: " + str(profile.travelers) + "   Hard requirements: " + needs_text);

    ledger = view.ledger;
    print("");
    print("Budget " + money(ledger.total_budget)
        + " - contingency " + money(ledger.contingency_amount)
        + " = usable " + money(ledger.usable_budget));
    print("Spent " + money(ledger.spent)
        + "   Remaining " + money(ledger.remaining)
        + "   (" + str(round(ledger.percent_used, 1)) + "% used, " + ledger.status.upper() + " budget)");
}

"""Print every item, planned items first, with its hard-filter result."""
def show_items(view: TripView) {
    status_by_num: dict[int, str] = {};
    for check in view.checks {
        text = check.status;
        if len(check.reasons) > 0 {
            text = text + " (" + ", ".join(check.reasons) + ")";
        }
        status_by_num[check.item_num] = text;
    }

    print("");
    print("Planned items:");
    for item in view.items {
        if item.selected {
            tags = "";
            if item.fixed {
                tags = tags + " [fixed]";
            }
            if item.disrupted {
                tags = tags + " [DISRUPTED]";
            }
            check_text = status_by_num.get(item.num, "");
            print("  #" + str(item.num) + " " + item.kind + ": " + item.name + tags);
            print("      " + item.date + "  " + money(item.cost + item.taxes_fees)
                + "  refund: " + item.refund_policy + "  check: " + check_text);
        }
    }
    print("Other options (not in the plan):");
    for item in view.items {
        if not item.selected {
            print("  #" + str(item.num) + " " + item.kind + ": " + item.name
                + "  " + item.date + "  " + money(item.cost + item.taxes_fees));
        }
    }
}

"""Print one proposal with its comparison numbers."""
def show_proposal(proposal: ProposalView) {
    numbers = proposal.comparison;
    loss_text = money(numbers.refund_loss);
    total_text = money(numbers.projected_total);
    if not numbers.refund_known {
        loss_text = "unknown";
        total_text = total_text + " + unknown refund loss";
    }
    label = "Plan B" if proposal.source == "backup" else "Repair";
    print("  [" + str(proposal.num) + "] " + label + ": replace #" + str(proposal.target_num)
        + " " + proposal.target_name + " with #" + str(proposal.replacement_num)
        + " " + proposal.replacement_name + " (" + proposal.replacement_date + ")");
    print("      why: " + proposal.reason);
    print("      cash needed now " + money(numbers.cash_now)
        + " | refund loss " + loss_text + " | projected trip total " + total_text);
}

"""Print the risk flags and the pending proposals."""
def show_risks(view: TripView) {
    print("");
    print("Risk flags:");
    if len(view.risks) == 0 {
        print("  none");
    }
    for flag in view.risks {
        where = "#" + str(flag.item_num) + " " + flag.item_name if flag.item_num > 0 else flag.item_name;
        print("  - " + where + ": " + flag.reason);
    }
    print("");
    print("Proposals waiting for you (suggestions only, nothing is booked):");
    if len(view.proposals) == 0 {
        print("  none");
    }
    for proposal in view.proposals {
        show_proposal(proposal);
    }
}

"""Print the notes from the last replan."""
def show_replan_notes(view: TripView) {
    if len(view.replan_notes) == 0 {
        return;
    }
    print("");
    print("Replan notes:");
    for note in view.replan_notes {
        print("  - " + note);
    }
}
