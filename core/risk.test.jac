"""Tests for the rule-based risk flags."""

test "non-refundable and unknown policies are flagged" {
    profile = Profile(budget=10000.0);
    items = [
        Item(num=1, name="A", refund_policy="non-refundable"),
        Item(num=2, name="B", refund_policy="unknown"),
        Item(num=3, name="C", refund_policy="refundable")
    ];
    flags = trip_risks(profile, items, "2026-06-01");
    assert len(flags) == 2;
    assert flags[0].item_num == 1;
    assert flags[1].item_num == 2;
}

test "deadline within 7 days is flagged, later is not" {
    soon = Item(num=1, refund_policy="refundable", cancel_deadline="2026-06-05");
    later = Item(num=2, refund_policy="refundable", cancel_deadline="2026-06-20");
    assert len(item_risks(soon, "2026-06-01")) == 1;
    assert len(item_risks(later, "2026-06-01")) == 0;
}

test "budget over 90 percent used is flagged" {
    profile = Profile(budget=1000.0, contingency_percent=0.0);
    items = [Item(num=1, cost=950.0, refund_policy="refundable")];
    flags = trip_risks(profile, items, "2026-06-01");
    assert len(flags) == 1;
    assert flags[0].item_name == "Whole trip";
}
