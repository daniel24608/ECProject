"""The whole web workflow on one page: profile, ledger, proposals, risks, items."""

import type from core.views { TripView }
import from core.server {
    get_trip,
    seed_trip,
    disrupt_item,
    accept_proposal,
    reject_proposal
}
import from web.components.LedgerCard { LedgerCard }
import from web.components.ItemsTable { ItemsTable }
import from web.components.RiskList { RiskList }
import from web.components.ProposalList { ProposalList }
import from web.components.ProfileForm { ProfileForm }
import from web.components.ItemForm { ItemForm }

def:pub TripPage -> JsxElement {
    has view: TripView | None = None,
        show_profile_form: bool = False;

    # Load the stored trip when the page opens.
    async can with entry {
        view = await get_trip();
    }

    """Show a fresh view from the server (every server call returns one)."""
    def show(new_view: TripView) -> None {
        view = new_view;
        if new_view.ok and new_view.has_trip {
            show_profile_form = False;
        }
    }

    async def load_sample -> None {
        show(await seed_trip());
    }

    async def disrupt(num: int) -> None {
        show(await disrupt_item(num));
    }

    async def accept(num: int) -> None {
        show(await accept_proposal(num));
    }

    async def reject(num: int) -> None {
        show(await reject_proposal(num));
    }

    <main className="page">
        <header className="top">
            <h1>Trip Planner</h1>
            <div>
                <button onClick={load_sample}>Load sample trip</button>
                {" "}
                <button className="secondary" onClick={lambda { show_profile_form = not show_profile_form; }}>
                    {"Hide new trip form" if show_profile_form else "New trip"}
                </button>
            </div>
        </header>
        {(<p className={"message" if view.ok else "message error"}>{view.message}</p>) if view and view.message else ""}
        {(<p>Loading...</p>) if not view else ""}
        {(<ProfileForm onView={show}/>) if view and (show_profile_form or not view.has_trip) else ""}
        {(<div>
            <LedgerCard view={view}/>
            <ProposalList view={view} onAccept={accept} onReject={reject}/>
            <RiskList view={view}/>
            <ItemsTable view={view} onDisrupt={disrupt}/>
            <ItemForm onView={show}/>
        </div>) if view and view.has_trip else ""}
    </main>
}
