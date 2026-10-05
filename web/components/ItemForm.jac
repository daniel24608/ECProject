"""Form for typing in a hotel, flight, or activity."""

import type from core.views { TripView }
import from core.server { add_item }
import from core.format { to_number }

"""A yes / no / unknown dropdown."""
def FlagSelect(label: str, value: str, onPick: Callable[[str], None]) -> JsxElement {
    <label>{label}
        <select value={value} onChange={lambda (e: ChangeEvent) { onPick(e.target.value); }}>
            <option value="unknown">unknown</option>
            <option value="yes">yes</option>
            <option value="no">no</option>
        </select>
    </label>
}

def:pub ItemForm(onView: Callable[[TripView], None]) -> JsxElement {
    has kind: str = "hotel",
        name: str = "",
        city: str = "",
        item_date: str = "",
        cost: str = "",
        taxes_fees: str = "0",
        pet_friendly: str = "unknown",
        kid_friendly: str = "unknown",
        accessible: str = "unknown",
        diet_friendly: str = "unknown",
        refund_policy: str = "unknown",
        cancel_deadline: str = "",
        fixed: bool = False,
        as_option: bool = False;

    """Send the item to the server; clear the name and cost if it was saved."""
    async def submit(e: FormEvent) -> None {
        e.preventDefault();
        view = await add_item(
            kind=kind,
            name=name,
            item_date=item_date,
            cost=to_number(cost),
            taxes_fees=to_number(taxes_fees),
            city=city,
            pet_friendly=pet_friendly,
            kid_friendly=kid_friendly,
            accessible=accessible,
            diet_friendly=diet_friendly,
            refund_policy=refund_policy,
            cancel_deadline=cancel_deadline,
            fixed=fixed,
            selected=not as_option
        );
        if view.ok {
            name = "";
            cost = "";
        }
        onView(view);
    }

    <section className="card">
        <h2>Add a hotel, flight, or activity</h2>
        <form onSubmit={submit} className="grid">
            <label>Type
                <select value={kind} onChange={lambda (e: ChangeEvent) { kind = e.target.value; }}>
                    <option value="hotel">hotel</option>
                    <option value="flight">flight</option>
                    <option value="activity">activity</option>
                </select>
            </label>
            <label>Name
                <input value={name} onChange={lambda (e: ChangeEvent) { name = e.target.value; }}/>
            </label>
            <label>City
                <input value={city} onChange={lambda (e: ChangeEvent) { city = e.target.value; }}/>
            </label>
            <label>Date
                <input type="date" value={item_date}
                    onChange={lambda (e: ChangeEvent) { item_date = e.target.value; }}/>
            </label>
            <label>Cost (USD)
                <input type="number" min="0" step="0.01" value={cost}
                    onChange={lambda (e: ChangeEvent) { cost = e.target.value; }}/>
            </label>
            <label>Taxes / fees (USD)
                <input type="number" min="0" step="0.01" value={taxes_fees}
                    onChange={lambda (e: ChangeEvent) { taxes_fees = e.target.value; }}/>
            </label>
            <FlagSelect label="Pet friendly" value={pet_friendly}
                onPick={lambda (v: str) { pet_friendly = v; }}/>
            <FlagSelect label="Kid friendly" value={kid_friendly}
                onPick={lambda (v: str) { kid_friendly = v; }}/>
            <FlagSelect label="Accessible" value={accessible}
                onPick={lambda (v: str) { accessible = v; }}/>
            <FlagSelect label="Fits dietary needs" value={diet_friendly}
                onPick={lambda (v: str) { diet_friendly = v; }}/>
            <label>Refund policy
                <select value={refund_policy}
                    onChange={lambda (e: ChangeEvent) { refund_policy = e.target.value; }}>
                    <option value="unknown">unknown</option>
                    <option value="refundable">refundable</option>
                    <option value="partial">partial</option>
                    <option value="non-refundable">non-refundable</option>
                </select>
            </label>
            <label>Cancellation deadline (optional)
                <input type="date" value={cancel_deadline}
                    onChange={lambda (e: ChangeEvent) { cancel_deadline = e.target.value; }}/>
            </label>
            <div className="checks">
                <label><input type="checkbox" checked={fixed}
                    onChange={lambda (e: ChangeEvent) { fixed = e.target.checked; }}/> Fixed (keep it no matter what)</label>
                <label><input type="checkbox" checked={as_option}
                    onChange={lambda (e: ChangeEvent) { as_option = e.target.checked; }}/> Just an option (not in the plan)</label>
            </div>
            <button type="submit">Add item</button>
        </form>
    </section>
}
