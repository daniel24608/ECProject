"""Shows Plan B suggestions and disruption repairs, each with Accept / Reject."""

import from core.views { TripView, ProposalView }
import from core.format { money }

"""Refund loss as text; an unknown policy stays unknown."""
def loss_text(proposal: ProposalView) -> str {
    if proposal.comparison.refund_known {
        return money(proposal.comparison.refund_loss);
    }
    return "unknown";
}

"""Projected trip total as text, noting an unknown refund loss."""
def total_text(proposal: ProposalView) -> str {
    text = money(proposal.comparison.projected_total);
    if not proposal.comparison.refund_known {
        text = text + " + unknown refund loss";
    }
    return text;
}

"""Short title such as "Repair #4" or "Plan B #1"."""
def title_text(proposal: ProposalView) -> str {
    label = "Repair" if proposal.source == "repair" else "Plan B";
    return label + " #" + str(proposal.num);
}

def:pub ProposalList(
    view: TripView,
    onAccept: Callable[[int], None],
    onReject: Callable[[int], None]
) -> JsxElement {
    <section className="card">
        <h2>Proposals to review</h2>
        <p className="muted">Suggestions only. Nothing is booked; accepting only updates this plan.</p>
        {(<p className="muted">Nothing to review right now.</p>) if len(view.proposals) == 0 else ""}
        {[
            <div className="proposal" key={proposal.num}>
                <p>
                    <span className={"badge bad" if proposal.source == "repair" else "badge"}>{title_text(proposal)}</span>
                    {" Replace #" + str(proposal.target_num) + " " + proposal.target_name}
                    {" with #" + str(proposal.replacement_num) + " " + proposal.replacement_name}
                    {" (" + proposal.replacement_date + ")"}
                </p>
                <p className="muted">{"Why: " + proposal.reason}</p>
                <table className="compare">
                    <tbody>
                        <tr>
                            <td>Cash needed now</td><td>{money(proposal.comparison.cash_now)}</td>
                            <td>Refund loss</td><td>{loss_text(proposal)}</td>
                            <td>Projected trip total</td><td>{total_text(proposal)}</td>
                        </tr>
                    </tbody>
                </table>
                <button onClick={lambda { onAccept(proposal.num); }}>Accept</button>
                {" "}
                <button className="secondary" onClick={lambda { onReject(proposal.num); }}>Reject</button>
            </div>
            for proposal in view.proposals
        ]}
        {(<div>
            <h3>Last replan</h3>
            <ul>{[<li key={str(index)}>{note}</li> for (index, note) in enumerate(view.replan_notes)]}</ul>
        </div>) if len(view.replan_notes) > 0 else ""}
    </section>
}
