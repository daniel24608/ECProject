"""What the server sends back to every client after each call.

These live in their own module (not in server.jac) so the web, mobile, and
CLI apps can use the types without reaching into the server app.
"""

import from core.models { Profile, Item }
import from core.budget { Ledger }
import from core.validate { CheckResult }
import from core.risk { RiskFlag }
import from core.compare { Comparison }

"""A proposal plus the names and numbers a person needs to decide on it."""
obj ProposalView {
    has num: int = 0,
        source: str = "",
        status: str = "",
        reason: str = "",
        target_num: int = 0,
        target_name: str = "",
        replacement_num: int = 0,
        replacement_name: str = "",
        replacement_date: str = "",
        comparison: Comparison = Comparison();
}

"""Everything a client shows. Every endpoint returns one of these."""
obj TripView {
    has ok: bool = True,
        message: str = "",
        has_trip: bool = False,
        today: str = "",
        profile: Profile = Profile(),
        items: list[Item] = [],
        ledger: Ledger = Ledger(),
        checks: list[CheckResult] = [],
        risks: list[RiskFlag] = [],
        proposals: list[ProposalView] = [],
        replan_notes: list[str] = [];
}
