"""Shows the rule-based risk flags."""

import from core.views { TripView }

def:pub RiskList(view: TripView) -> JsxElement {
    <section className="card">
        <h2>Risk flags</h2>
        {(<p className="muted">No risks found.</p>) if len(view.risks) == 0 else ""}
        <ul>
            {[
                <li key={str(index)}>
                    <strong>{(("#" + str(flag.item_num) + " ") if flag.item_num > 0 else "") + flag.item_name}</strong>
                    {": " + flag.reason}
                </li>
                for (index, flag) in enumerate(view.risks)
            ]}
        </ul>
    </section>
}
