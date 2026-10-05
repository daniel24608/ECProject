"""Tests for Plan B backup selection."""

test "backup is the cheapest same-type option that passes filters" {
    profile = Profile(with_pet=True);
    target = Item(num=1, kind="hotel", selected=True, pet_friendly="yes");
    items = [
        target,
        Item(num=2, kind="hotel", selected=False, cost=200.0, pet_friendly="yes"),
        Item(num=3, kind="hotel", selected=False, cost=100.0, pet_friendly="yes"),
        Item(num=4, kind="hotel", selected=False, cost=50.0, pet_friendly="unknown"),
        Item(num=5, kind="flight", selected=False, cost=10.0, pet_friendly="yes")
    ];
    best = find_backup(profile, items, target, [], "");
    assert best is not None;
    assert best.num == 3;
}

test "no backup when nothing passes" {
    profile = Profile(with_pet=True);
    target = Item(num=1, kind="hotel");
    items = [target, Item(num=2, kind="hotel", selected=False, pet_friendly="no")];
    assert find_backup(profile, items, target, [], "") is None;
}
