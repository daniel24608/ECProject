"""Plan B: pick the cheapest other entered option that can replace an item."""

import from core.models { Profile, Item }
import from core.budget { item_total }
import from core.validate { passes_filters }

"""True when `option` could stand in for `target`.

It must be the same type, not the target itself, not already in the plan,
not disrupted, not on the skip list, not earlier than `earliest_date`
(when one is given), and it must pass every hard filter.
"""
def can_replace(
    profile: Profile,
    target: Item,
    option: Item,
    skip_nums: list[int],
    earliest_date: str
) -> bool {
    if option.kind != target.kind {
        return False;
    }
    if option.num == target.num or option.selected or option.disrupted {
        return False;
    }
    if option.num in skip_nums {
        return False;
    }
    if earliest_date != "" and option.date < earliest_date {
        return False;
    }
    return passes_filters(profile, option);
}

"""Cheapest option that can replace `target`, or None if there is none.

Dates are YYYY-MM-DD strings, so comparing them as text also compares them
in time order.
"""
def find_backup(
    profile: Profile,
    items: list[Item],
    target: Item,
    skip_nums: list[int],
    earliest_date: str
) -> Item | None {
    best: Item | None = None;
    for option in items {
        if can_replace(profile, target, option, skip_nums, earliest_date) {
            if best is None or item_total(option) < item_total(best) {
                best = option;
            }
        }
    }
    return best;
}
