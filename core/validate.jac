"""Hard-filter validation: does an item meet the traveler's must-have needs?

Each requirement gives "pass", "fail", or "unresolved". An item whose flag is
"unknown" is unresolved: we never assume it is fine.
"""

import from core.models { Profile, Item }

"""Result of checking one item against the hard requirements."""
obj CheckResult {
    has item_num: int = 0,
        item_name: str = "",
        status: str = "pass",
        reasons: list[str] = [];
}

"""Check one requirement against one yes/no/unknown flag on an item."""
def check_flag(required: bool, flag: str) -> str {
    if not required {
        return "pass";
    }
    if flag == "yes" {
        return "pass";
    }
    if flag == "no" {
        return "fail";
    }
    return "unresolved";
}

"""Check an item against every hard requirement in the profile.

The overall status is the worst one found: fail, then unresolved, then pass.
"""
def check_item(profile: Profile, item: Item) -> CheckResult {
    has_diet_needs = len(profile.dietary_needs) > 0;

    # Each row is (requirement name, is it required, the item's flag).
    rules = [
        ("pet friendly", profile.with_pet, item.pet_friendly),
        ("kid friendly", profile.with_kids, item.kid_friendly),
        ("accessible", profile.needs_accessibility, item.accessible),
        ("dietary needs", has_diet_needs, item.diet_friendly)
    ];

    reasons: list[str] = [];
    any_fail = False;
    any_unresolved = False;
    for (label, required, flag) in rules {
        result = check_flag(required, flag);
        if result == "fail" {
            any_fail = True;
            reasons.append("not " + label);
        } elif result == "unresolved" {
            any_unresolved = True;
            reasons.append(label + " is unknown");
        }
    }

    status = "pass";
    if any_fail {
        status = "fail";
    } elif any_unresolved {
        status = "unresolved";
    }
    return CheckResult(
        item_num=item.num, item_name=item.name, status=status, reasons=reasons
    );
}

"""Check every selected item in the plan."""
def check_selected(profile: Profile, items: list[Item]) -> list[CheckResult] {
    results: list[CheckResult] = [];
    for item in items {
        if item.selected {
            results.append(check_item(profile, item));
        }
    }
    return results;
}

"""True only when an item clearly passes every hard requirement."""
def passes_filters(profile: Profile, item: Item) -> bool {
    return check_item(profile, item).status == "pass";
}
