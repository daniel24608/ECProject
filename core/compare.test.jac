"""Tests for the swap comparison."""

test "refund loss follows the refund policy" {
    assert refund_loss(Item(cost=100.0, refund_policy="refundable")) == (0.0, True);
    assert refund_loss(Item(cost=100.0, refund_policy="partial")) == (50.0, True);
    assert refund_loss(Item(cost=100.0, refund_policy="non-refundable")) == (100.0, True);
    assert refund_loss(Item(cost=100.0, refund_policy="unknown")) == (0.0, False);
}

test "projected total counts the original payment only once" {
    old = Item(num=1, cost=300.0, selected=True, refund_policy="partial");
    other = Item(num=2, cost=500.0, selected=True, refund_policy="refundable");
    new = Item(num=3, cost=200.0, selected=False);
    result = compare_swap([old, other, new], 0.0, old, new);
    assert result.cash_now == 200.0;
    assert result.refund_loss == 150.0;
    # 800 now - 300 old + 150 lost + 200 new
    assert result.projected_total == 850.0;
}
