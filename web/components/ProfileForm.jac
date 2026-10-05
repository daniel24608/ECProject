"""The trip profile form. Creating a trip replaces the old one."""

import type from core.views { TripView }
import from core.server { init_trip }
import from core.format { to_number }

def:pub ProfileForm(onView: Callable[[TripView], None]) -> JsxElement {
    has destination: str = "",
        start_date: str = "",
        end_date: str = "",
        budget: str = "",
        contingency: str = "10",
        travelers: str = "1",
        with_kids: bool = False,
        with_pet: bool = False,
        needs_accessibility: bool = False,
        dietary_needs: str = "";

    """Send the form to the server and show the result."""
    async def submit(e: FormEvent) -> None {
        e.preventDefault();
        view = await init_trip(
            destination=destination,
            start_date=start_date,
            end_date=end_date,
            budget=to_number(budget),
            contingency_percent=to_number(contingency),
            travelers=int(to_number(travelers)),
            with_kids=with_kids,
            with_pet=with_pet,
            dietary_needs=dietary_needs,
            needs_accessibility=needs_accessibility
        );
        onView(view);
    }

    <section className="card">
        <h2>New trip</h2>
        <form onSubmit={submit} className="grid">
            <label>Destination
                <input value={destination} placeholder="Lisbon, Portugal"
                    onChange={lambda (e: ChangeEvent) { destination = e.target.value; }}/>
            </label>
            <label>Start date
                <input type="date" value={start_date}
                    onChange={lambda (e: ChangeEvent) { start_date = e.target.value; }}/>
            </label>
            <label>End date
                <input type="date" value={end_date}
                    onChange={lambda (e: ChangeEvent) { end_date = e.target.value; }}/>
            </label>
            <label>Total budget (USD)
                <input type="number" min="0" value={budget}
                    onChange={lambda (e: ChangeEvent) { budget = e.target.value; }}/>
            </label>
            <label>Contingency %
                <input type="number" min="0" max="99" value={contingency}
                    onChange={lambda (e: ChangeEvent) { contingency = e.target.value; }}/>
            </label>
            <label>Travelers
                <input type="number" min="1" value={travelers}
                    onChange={lambda (e: ChangeEvent) { travelers = e.target.value; }}/>
            </label>
            <label>Dietary needs (comma separated)
                <input value={dietary_needs} placeholder="vegetarian, nut allergy"
                    onChange={lambda (e: ChangeEvent) { dietary_needs = e.target.value; }}/>
            </label>
            <div className="checks">
                <label><input type="checkbox" checked={with_kids}
                    onChange={lambda (e: ChangeEvent) { with_kids = e.target.checked; }}/> Traveling with kids</label>
                <label><input type="checkbox" checked={with_pet}
                    onChange={lambda (e: ChangeEvent) { with_pet = e.target.checked; }}/> Traveling with a pet</label>
                <label><input type="checkbox" checked={needs_accessibility}
                    onChange={lambda (e: ChangeEvent) { needs_accessibility = e.target.checked; }}/> Needs accessibility</label>
            </div>
            <button type="submit">Create trip</button>
        </form>
    </section>
}
