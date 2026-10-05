"""Rule-based risk flags for the selected items and the budget."""

import from datetime { date }
import from core.models { Profile, Item }
import from core.budget { build_ledger }

# A cancellation deadline this many days away (or fewer) is flagged.
glob DEADLINE_WARNING_DAYS: int = 7,
     BUDGET_WARNING_PERCENT: float = 90.0;

"""One risk: which item it is about and why. item_num is 0 for the whole trip."""
obj RiskFlag {
    has item_num: int = 0,
        item_name: str = "",
        reason: str = "";
}

"""Number of days from `today` to `deadline`. Both are YYYY-MM-DD strings."""
def days_between(today: str, deadline: str) -> int {
    start = date.fromisoformat(today);
    end = date.fromisoformat(deadline);
    return (end - start).days;
}

"""Risk flags for one item, based on its refund policy and deadline."""
def item_risks(item: Item, today: str) -> list[RiskFlag] {
    flags: list[RiskFlag] = [];
    if item.refund_policy == "non-refundable" {
        flags.append(
            RiskFlag(
                item_num=item.num,
                item_name=item.name,
                reason="non-refundable: money is lost if plans change"
            )
        );
    }
    if item.refund_policy == "unknown" {
        flags.append(
            RiskFlag(
                item_num=item.num,
                item_name=item.name,
                reason="refund policy is unknown: check the terms"
            )
        );
    }
    if item.cancel_deadline != "" {
        days_left = days_between(today, item.cancel_deadline);
        if days_left >= 0 and days_left <= DEADLINE_WARNING_DAYS {
            flags.append(
                RiskFlag(
                    item_num=item.num,
                    item_name=item.name,
                    reason="free cancellation ends in "
                    + str(days_left)
                    + " day(s) ("
                    + item.cancel_deadline
                    + ")"
                )
            );
        }
    }
    return flags;
}

"""All risk flags for the trip: every selected item plus the budget check."""
def trip_risks(
    profile: Profile, items: list[Item], lost_money: float, today: str
) -> list[RiskFlag] {
    flags: list[RiskFlag] = [];
    for item in items {
        if item.selected {
            flags = flags + item_risks(item, today);
        }
    }

    ledger = build_ledger(profile, items, lost_money);
    if ledger.percent_used > BUDGET_WARNING_PERCENT {
        flags.append(
            RiskFlag(
                item_num=0,
                item_name="Whole trip",
                reason="budget is "
                + str(round(ledger.percent_used))
                + "% used (over "
                + str(round(BUDGET_WARNING_PERCENT))
                + "%)"
            )
        );
    }
    return flags;
}
