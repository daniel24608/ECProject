"""Small display helpers shared by the web, mobile, and CLI clients."""

"""Money as text, for example 1234.5 -> "$1234.50" and -20 -> "-$20.00"."""
def money(amount: float) -> str {
    if amount < 0 {
        return "-$" + f"{-amount:.2f}";
    }
    return "$" + f"{amount:.2f}";
}

"""A percent as text with one decimal, for example 90.27 -> "90.3%"."""
def percent(value: float) -> str {
    return f"{value:.1f}" + "%";
}

"""Turn a number box's text into a float (an empty box counts as 0)."""
def to_number(text: str) -> float {
    if text.strip() == "" {
        return 0.0;
    }
    return float(text);
}
