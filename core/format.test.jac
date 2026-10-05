"""Tests for the display helpers."""

test "money keeps two decimals and handles negatives" {
    assert money(1234.5) == "$1234.50";
    assert money(-20.0) == "-$20.00";
}

test "percent shows one decimal" {
    assert percent(90.27) == "90.3%";
}
