"""Shows the trip profile and the budget ledger."""

import from core.views { TripView }
import from core.format { money, percent }

def:pub LedgerCard(view: TripView) -> JsxElement {
    profile = view.profile;
    ledger = view.ledger;
    needs = ", ".join(profile.dietary_needs);
    status_class = "badge bad" if ledger.status == "over" else "badge good";
    <section className="card">
        <h2>{profile.destination}</h2>
        <p className="muted">
            {profile.start_date + " to " + profile.end_date + " · " + str(profile.travelers) + " traveler(s)"}
        </p>
        <p>
            {"Hard requirements: kids " + ("yes" if profile.with_kids else "no")}
            {" · pet " + ("yes" if profile.with_pet else "no")}
            {" · accessibility " + ("yes" if profile.needs_accessibility else "no")}
            {" · diet " + (needs if needs else "none")}
        </p>
        <table className="ledger">
            <tbody>
                <tr><td>Total budget</td><td>{money(ledger.total_budget)}</td></tr>
                <tr>
                    <td>{"Contingency (" + str(profile.contingency_percent) + "%)"}</td>
                    <td>{"- " + money(ledger.contingency_amount)}</td>
                </tr>
                <tr><td>Usable budget</td><td>{money(ledger.usable_budget)}</td></tr>
                <tr><td>Spent (planned items + lost refunds)</td><td>{money(ledger.spent)}</td></tr>
                <tr className="strong"><td>Remaining</td><td>{money(ledger.remaining)}</td></tr>
            </tbody>
        </table>
        <p>
            <span className={status_class}>{ledger.status.upper() + " budget"}</span>
            {" " + percent(ledger.percent_used) + " of the usable budget used"}
        </p>
    </section>
}
