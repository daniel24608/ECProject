"""Lists planned items (with their hard-filter result) and the other options."""

import from core.models { Item }
import from core.views { TripView }
import from core.format { money }

"""Hard-filter text for one item, for example "unresolved: pet friendly is unknown"."""
def check_text(view: TripView, item: Item) -> str {
    for check in view.checks {
        if check.item_num == item.num {
            if len(check.reasons) == 0 {
                return check.status;
            }
            return check.status + ": " + ", ".join(check.reasons);
        }
    }
    return "";
}

"""CSS class for a check result, so pass / fail / unresolved get colors."""
def check_class(text: str) -> str {
    if text.startswith("fail") {
        return "bad";
    }
    if text.startswith("unresolved") {
        return "warn";
    }
    return "good";
}

"""Refund policy plus the cancellation deadline when there is one."""
def refund_text(item: Item) -> str {
    if item.cancel_deadline != "" {
        return item.refund_policy + " (cancel by " + item.cancel_deadline + ")";
    }
    return item.refund_policy;
}

def:pub ItemsTable(view: TripView, onDisrupt: Callable[[int], None]) -> JsxElement {
    planned = [item for item in view.items if item.selected];
    options = [item for item in view.items if not item.selected];
    <section className="card">
        <h2>Itinerary</h2>
        <table>
            <thead>
                <tr>
                    <th>#</th><th>Type</th><th>Name</th><th>Date</th><th>Total</th>
                    <th>Refund</th><th>Hard filters</th><th></th>
                </tr>
            </thead>
            <tbody>
                {[
                    <tr key={item.num} className={"disrupted" if item.disrupted else ""}>
                        <td>{str(item.num)}</td>
                        <td>{item.kind}</td>
                        <td>
                            {item.name + " "}
                            {(<span className="badge">fixed</span>) if item.fixed else ""}
                            {(<span className="badge bad">disrupted</span>) if item.disrupted else ""}
                        </td>
                        <td className="nowrap">{item.date}</td>
                        <td>{money(item.cost + item.taxes_fees)}</td>
                        <td>{refund_text(item)}</td>
                        <td className={check_class(check_text(view, item))}>{check_text(view, item)}</td>
                        <td>
                            {(<button className="small" onClick={lambda { onDisrupt(item.num); }}>Simulate disruption</button>) if not item.disrupted else ""}
                        </td>
                    </tr>
                    for item in planned
                ]}
            </tbody>
        </table>
        <h3>Other options (not in the plan)</h3>
        {(<p className="muted">No other options yet. Add some so backups can be found.</p>) if len(options) == 0 else ""}
        <ul className="options">
            {[
                <li key={item.num}>
                    {"#" + str(item.num) + " " + item.kind + ": " + item.name + " · " + item.date + " · " + money(item.cost + item.taxes_fees) + " · refund " + item.refund_policy + (" · disrupted" if item.disrupted else "")}
                </li>
                for item in options
            ]}
        </ul>
    </section>
}
