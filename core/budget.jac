"""Budget ledger: how much the selected items cost compared with the budget."""

import from core.models { Profile, Item }

"""Totals for the trip budget. All amounts are USD."""
obj Ledger {
    has total_budget: float = 0.0,
        contingency_amount: float = 0.0,
        usable_budget: float = 0.0,
        spent: float = 0.0,
        remaining: float = 0.0,
        percent_used: float = 0.0,
        status: str = "under";
}

"""Full price of one item: its cost plus its taxes and fees."""
def item_total(item: Item) -> float {
    return item.cost + item.taxes_fees;
}

"""Sum of the full price of every selected (planned) item."""
def selected_total(items: list[Item]) -> float {
    total = 0.0;
    for item in items {
        if item.selected {
            total = total + item_total(item);
        }
    }
    return total;
}

"""Build the ledger.

The contingency is set aside first, so the usable budget is the total budget
minus the contingency. Status is "over" when spending passes the usable budget.
"""
def build_ledger(profile: Profile, items: list[Item]) -> Ledger {
    contingency_amount = profile.budget * profile.contingency_percent / 100.0;
    usable_budget = profile.budget - contingency_amount;
    spent = selected_total(items);
    remaining = usable_budget - spent;

    percent_used = 0.0;
    if usable_budget > 0 {
        percent_used = spent / usable_budget * 100.0;
    }

    status = "under";
    if remaining < 0 {
        status = "over";
    }

    return Ledger(
        total_budget=profile.budget,
        contingency_amount=contingency_amount,
        usable_budget=usable_budget,
        spent=spent,
        remaining=remaining,
        percent_used=percent_used,
        status=status
    );
}
