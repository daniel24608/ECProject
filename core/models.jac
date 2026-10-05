"""Data models shared by the server, web, mobile, and CLI.

These are plain `obj` types (not graph nodes) so they can travel over the
network to every client and can be built directly inside tests.
Money is in USD. Dates are strings in YYYY-MM-DD format.
"""

# Allowed values for the yes / no / unknown eligibility flags.
glob YES: str = "yes",
     NO: str = "no",
     UNKNOWN: str = "unknown";

# Allowed item types and refund policies.
glob ITEM_KINDS: list[str] = ["hotel", "flight", "activity"],
     FLAG_VALUES: list[str] = ["yes", "no", "unknown"],
     REFUND_POLICIES: list[str] = ["refundable", "partial", "non-refundable", "unknown"];

"""The traveler's trip profile, including the hard requirements."""
obj Profile {
    has destination: str = "",
        start_date: str = "",
        end_date: str = "",
        budget: float = 0.0,
        contingency_percent: float = 10.0,
        travelers: int = 1,
        with_kids: bool = False,
        with_pet: bool = False,
        dietary_needs: list[str] = [],
        needs_accessibility: bool = False;
}

"""One hotel, flight, or activity typed in by the user.

`selected` means it is part of the current plan. Items that are not selected
are kept as options that backups and repairs can choose from.
"""
obj Item {
    has num: int = 0,
        kind: str = "activity",
        name: str = "",
        city: str = "",
        date: str = "",
        cost: float = 0.0,
        taxes_fees: float = 0.0,
        pet_friendly: str = "unknown",
        kid_friendly: str = "unknown",
        accessible: str = "unknown",
        diet_friendly: str = "unknown",
        refund_policy: str = "unknown",
        cancel_deadline: str = "",
        fixed: bool = False,
        selected: bool = True,
        disrupted: bool = False;
}

"""A suggested swap: replace one item (the target) with another (the replacement).

`source` is "backup" for a Plan B suggestion or "repair" for a disruption fix.
`status` is "pending", "accepted", or "rejected".
"""
obj Proposal {
    has num: int = 0,
        source: str = "backup",
        target_num: int = 0,
        replacement_num: int = 0,
        reason: str = "",
        status: str = "pending";
}
