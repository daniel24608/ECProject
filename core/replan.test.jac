"""Tests for disruption replanning."""

def sample_items -> list[Item] {
    return [
        Item(num=1, kind="flight", name="Flight A", date="2026-06-01", selected=True),
        Item(num=2, kind="hotel", name="Hotel A", date="2026-06-01", selected=True),
        Item(num=3, kind="activity", name="Museum", date="2026-06-01", selected=True, fixed=True),
        Item(num=4, kind="activity", name="Boat", date="2026-06-03", selected=True),
        Item(num=5, kind="flight", name="Flight B", date="2026-06-02", selected=False, cost=400.0),
        Item(num=6, kind="hotel", name="Hotel B", date="2026-06-02", selected=False, cost=150.0)
    ];
}

test "downstream items are planned items on the same day or later" {
    items = sample_items();
    found = downstream_items(items, items[0]);
    nums = [i.num for i in found];
    assert nums == [2, 3, 4];
}

test "replan replaces the disrupted item and fixes conflicts, keeping fixed items" {
    items = sample_items();
    result = plan_repair(Profile(), items, items[0]);
    targets = [s.target_num for s in result.swaps];
    assert targets == [1, 2];
    assert result.swaps[0].replacement_num == 5;
    assert result.swaps[1].replacement_num == 6;
    # the fixed museum ticket is never swapped
    assert 3 not in targets;
}
