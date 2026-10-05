"""Compare a proposed swap: cash needed now, refund loss, projected trip total."""

import from core.models { Item }
import from core.budget { item_total, selected_total }

"""The numbers a traveler needs to judge one swap. Amounts are USD.

When the old item's refund policy is unknown, `refund_known` is False and
`refund_loss` is 0, so the projected total does not include that loss.
"""
obj Comparison {
    has cash_now: float = 0.0,
        refund_loss: float = 0.0,
        refund_known: bool = True,
        projected_total: float = 0.0;
}

"""Money lost when giving up an item, based on its refund policy.

Refundable loses nothing, partial loses half, non-refundable loses all.
Returns (loss, known); unknown policies return (0.0, False).
"""
def refund_loss(item: Item) -> tuple[float, bool] {
    full_price = item_total(item);
    if item.refund_policy == "refundable" {
        return (0.0, True);
    }
    if item.refund_policy == "partial" {
        return (full_price * 0.5, True);
    }
    if item.refund_policy == "non-refundable" {
        return (full_price, True);
    }
    return (0.0, False);
}

"""Compare replacing `target` with `replacement`.

The old payment is already in the current total, so we remove it once,
add back only the part we cannot get refunded, then add the new price.
This way the original payment is never counted twice.
"""
def compare_swap(items: list[Item], target: Item, replacement: Item) -> Comparison {
    current_total = selected_total(items);
    (loss, known) = refund_loss(target);
    cash_now = item_total(replacement);

    old_price_in_total = 0.0;
    if target.selected {
        old_price_in_total = item_total(target);
    }
    projected_total = current_total - old_price_in_total + loss + cash_now;

    return Comparison(
        cash_now=cash_now,
        refund_loss=loss,
        refund_known=known,
        projected_total=projected_total
    );
}
