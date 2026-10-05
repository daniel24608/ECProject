"""Tests for hard-filter validation."""

test "unknown eligibility is unresolved, not accepted" {
    profile = Profile(with_pet=True);
    item = Item(num=1, name="Hotel", pet_friendly="unknown");
    result = check_item(profile, item);
    assert result.status == "unresolved";
    assert "pet friendly is unknown" in result.reasons;
}

test "a failed requirement beats an unknown one" {
    profile = Profile(with_pet=True, with_kids=True);
    item = Item(num=1, pet_friendly="unknown", kid_friendly="no");
    assert check_item(profile, item).status == "fail";
}

test "requirements the traveler does not have are ignored" {
    profile = Profile(with_pet=False, dietary_needs=[]);
    item = Item(num=1, pet_friendly="no", diet_friendly="no");
    assert check_item(profile, item).status == "pass";
}

test "dietary needs check the diet flag" {
    profile = Profile(dietary_needs=["vegetarian"]);
    assert check_item(profile, Item(diet_friendly="yes")).status == "pass";
    assert check_item(profile, Item(diet_friendly="no")).status == "fail";
}
