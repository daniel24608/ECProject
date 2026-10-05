"""Replan after a disruption (for example, a cancelled flight).

1. Find a replacement for the disrupted item.
2. Look at the downstream items: planned items on the same day or later.
3. If the replacement arrives after a downstream item's date, that item is
   in conflict. Fixed items are kept and reported; others get a replacement.
"""

import from core.models { Profile, Item }
import from core.backup { find_backup }

"""One suggested swap produced by the replanner."""
obj Swap {
    has target_num: int = 0,
        replacement_num: int = 0,
        reason: str = "";
}

"""Everything the replanner found: swaps to propose plus readable notes."""
obj ReplanResult {
    has swaps: list[Swap] = [],
        notes: list[str] = [];
}

"""Planned items on the same day as the disrupted item or later, by date."""
def downstream_items(items: list[Item], disrupted: Item) -> list[Item] {
    found: list[Item] = [];
    for item in items {
        is_other = item.num != disrupted.num;
        is_planned = item.selected and not item.disrupted;
        if is_other and is_planned and item.date >= disrupted.date {
            found.append(item);
        }
    }
    found.sort(key=lambda (i: Item) -> str { return i.date; });
    return found;
}

"""Build the repair plan for one disrupted item."""
def plan_repair(profile: Profile, items: list[Item], disrupted: Item) -> ReplanResult {
    result = ReplanResult(swaps=[], notes=[]);
    used_nums: list[int] = [];

    # Step 1: replace the disrupted item itself.
    new_date = disrupted.date;
    replacement = find_backup(profile, items, disrupted, used_nums, "");
    if replacement is None {
        result.notes.append(
            "No replacement for " + disrupted.name + " passes the hard filters."
        );
    } else {
        used_nums.append(replacement.num);
        new_date = replacement.date;
        result.swaps.append(
            Swap(
                target_num=disrupted.num,
                replacement_num=replacement.num,
                reason=disrupted.name + " was disrupted"
            )
        );
        result.notes.append(
            "Replace " + disrupted.name + " with " + replacement.name + " (" + new_date + ")."
        );
    }

    # Step 2 and 3: check every downstream item against the new date.
    for item in downstream_items(items, disrupted) {
        label = item.name + " (" + item.date + ")";
        if item.date >= new_date {
            result.notes.append(label + ": still OK.");
        } elif item.fixed {
            result.notes.append(
                label + ": conflicts with the new date, but it is fixed so it is kept. Please review."
            );
        } else {
            fix = find_backup(profile, items, item, used_nums, new_date);
            if fix is None {
                result.notes.append(label + ": conflicts, and no later option was found.");
            } else {
                used_nums.append(fix.num);
                result.swaps.append(
                    Swap(
                        target_num=item.num,
                        replacement_num=fix.num,
                        reason=item.name + " is before the new arrival date " + new_date
                    )
                );
                result.notes.append(label + ": conflicts, move to " + fix.name + " (" + fix.date + ").");
            }
        }
    }
    return result;
}
