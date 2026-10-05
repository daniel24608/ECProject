"""Tests for the budget ledger."""

test "ledger sets aside the contingency and sums selected items" {
    profile = Profile(budget=1000.0, contingency_percent=10.0);
    items = [
        Item(num=1, cost=300.0, taxes_fees=50.0, selected=True),
        Item(num=2, cost=999.0, taxes_fees=0.0, selected=False)
    ];
    ledger = build_ledger(profile, items);
    assert ledger.contingency_amount == 100.0;
    assert ledger.usable_budget == 900.0;
    assert ledger.spent == 350.0;
    assert ledger.remaining == 550.0;
    assert ledger.status == "under";
}

test "ledger reports over budget" {
    profile = Profile(budget=500.0, contingency_percent=10.0);
    items = [Item(num=1, cost=460.0, taxes_fees=0.0, selected=True)];
    ledger = build_ledger(profile, items);
    assert ledger.remaining == -10.0;
    assert ledger.status == "over";
}
