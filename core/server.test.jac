"""Tests for rejecting proposals on the server.

This is one test on purpose: `jac test` runs test blocks in parallel, and every
step here changes the same stored trip, so the steps must run in order.
In the sample trip, item #1 is the TAP flight and item #2 is the Alfama hotel,
whose Plan B is Baixa Budget Inn.
"""

"""The pending proposal for one target item, or None."""
def pending_for(view: TripView, target_num: int) -> ProposalView | None {
    for proposal in view.proposals {
        if proposal.target_num == target_num {
            return proposal;
        }
    }
    return None;
}

test "rejecting a Plan B offers the next option and keeps the rest" {
    seed_trip();
    add_item(
        kind="hotel", name="Graca Guesthouse", item_date=days_from_today(30),
        cost=500.0, kid_friendly="yes", diet_friendly="yes",
        refund_policy="refundable", selected=False
    );
    before = get_trip();
    first = pending_for(before, 2);
    flight = pending_for(before, 1);
    assert first is not None and flight is not None;
    assert first.replacement_name == "Baixa Budget Inn";

    # Step 1: rejecting Baixa offers the next hotel right away.
    after = reject_proposal(first.num);
    assert after.ok;
    second = pending_for(after, 2);
    assert second is not None;
    assert second.replacement_name == "Graca Guesthouse";
    assert "Graca Guesthouse" in after.message;

    # Other proposals keep their numbers, and the plan itself is unchanged.
    flight_after = pending_for(after, 1);
    assert flight_after is not None and flight_after.num == flight.num;
    assert after.ledger.spent == before.ledger.spent;

    # Step 2: rejecting the last option leaves no hotel suggestion and says so.
    last = reject_proposal(second.num);
    assert pending_for(last, 2) is None;
    assert "No other option" in last.message;
}
