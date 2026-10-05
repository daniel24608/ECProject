"""The phone screen: trip summary, risks, proposals, disruptions, quick add.

It calls the same planner server functions as the web app and the CLI.
"""

import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, Switch }
import from "@jac/runtime" { BridgeError }
import type from core.views { TripView }
import from core.format { money, percent, to_number }
import from core.server {
    get_trip,
    seed_trip,
    add_item,
    disrupt_item,
    accept_proposal,
    reject_proposal
}
import from mobile.theme { styles }

"""A simple button: blue, grey, or orange."""
def Button(label: str, onPress: Callable[[], None], look: str = "blue") -> JsxElement {
    box = styles.button;
    text_style = styles.buttonText;
    if look == "grey" {
        box = styles.buttonGrey;
        text_style = styles.buttonTextDark;
    } elif look == "orange" {
        box = styles.buttonOrange;
    }
    return <Pressable style={box} onPress={onPress}><Text style={text_style}>{label}</Text></Pressable>;
}

def:pub TripScreen -> JsxElement {
    has view: TripView | None = None,
        problem: str = "",
        kind: str = "activity",
        name: str = "",
        item_date: str = "",
        cost: str = "",
        as_option: bool = False;

    """Show a fresh view from the server and clear any old problem."""
    def show(new_view: TripView) -> None {
        view = new_view;
        problem = "";
    }

    """Tell the user the server could not be reached."""
    def failed(e: BridgeError) -> None {
        problem = "Cannot reach the planner server. Is `jac run` running? (" + str(e) + ")";
    }

    async def load_trip -> None {
        try { show(await get_trip()); } except BridgeError as e { failed(e); }
    }

    async def load_sample -> None {
        try { show(await seed_trip()); } except BridgeError as e { failed(e); }
    }

    async def disrupt(num: int) -> None {
        try { show(await disrupt_item(num)); } except BridgeError as e { failed(e); }
    }

    async def accept(num: int) -> None {
        try { show(await accept_proposal(num)); } except BridgeError as e { failed(e); }
    }

    async def reject(num: int) -> None {
        try { show(await reject_proposal(num)); } except BridgeError as e { failed(e); }
    }

    """Add an item with just type, name, date, and cost (flags stay unknown)."""
    async def quick_add -> None {
        try {
            new_view = await add_item(
                kind=kind,
                name=name,
                item_date=item_date,
                cost=to_number(cost),
                selected=not as_option
            );
            show(new_view);
            if new_view.ok {
                name = "";
                cost = "";
            }
        } except BridgeError as e {
            failed(e);
        }
    }

    async can with entry {
        await load_trip();
    }

    <ScrollView style={styles.screen} contentContainerStyle={styles.body}>
        <Text style={styles.title}>Trip Planner</Text>
        <View style={styles.row}>
            <Button label="Load sample trip" onPress={load_sample}/>
            <Button label="Refresh" look="grey" onPress={load_trip}/>
        </View>

        {(<View style={styles.errorMessage}><Text style={styles.text}>{problem}</Text></View>) if problem else <View/>}
        {(<View style={styles.message if view.ok else styles.errorMessage}>
            <Text style={styles.text}>{view.message}</Text>
        </View>) if view and view.message else <View/>}
        {(<Text style={styles.muted}>Loading...</Text>) if not view and not problem else <View/>}
        {(<Text style={styles.muted}>No trip yet. Load the sample trip, or create one on the web or CLI.</Text>) if view and not view.has_trip else <View/>}

        {(<View style={{"gap": 12}}>
            <View style={styles.card}>
                <Text style={styles.heading}>{view.profile.destination}</Text>
                <Text style={styles.muted}>{view.profile.start_date + " to " + view.profile.end_date}</Text>
                <Text style={styles.text}>{"Usable budget " + money(view.ledger.usable_budget)}</Text>
                <Text style={styles.text}>{"Spent " + money(view.ledger.spent) + " (" + percent(view.ledger.percent_used) + ")"}</Text>
                <Text style={styles.bad if view.ledger.status == "over" else styles.good}>
                    {"Remaining " + money(view.ledger.remaining) + " · " + view.ledger.status.upper() + " budget"}
                </Text>
            </View>

            <View style={styles.card}>
                <Text style={styles.heading}>Proposals</Text>
                <Text style={styles.muted}>Suggestions only. Nothing is booked.</Text>
                {(<Text style={styles.muted}>Nothing to review.</Text>) if len(view.proposals) == 0 else <View/>}
                {[
                    <View key={proposal.num} style={{"gap": 4, "paddingTop": 8}}>
                        <Text style={styles.text}>
                            {("Repair" if proposal.source == "repair" else "Plan B") + " #" + str(proposal.num) + ": " + proposal.target_name + " -> " + proposal.replacement_name}
                        </Text>
                        <Text style={styles.muted}>{"Why: " + proposal.reason}</Text>
                        <Text style={styles.muted}>
                            {"Cash now " + money(proposal.comparison.cash_now) + " · refund loss " + (money(proposal.comparison.refund_loss) if proposal.comparison.refund_known else "unknown") + " · total " + money(proposal.comparison.projected_total)}
                        </Text>
                        <View style={styles.row}>
                            <Button label="Accept" onPress={lambda { accept(proposal.num); }}/>
                            <Button label="Reject" look="grey" onPress={lambda { reject(proposal.num); }}/>
                        </View>
                    </View>
                    for proposal in view.proposals
                ]}
            </View>

            <View style={styles.card}>
                <Text style={styles.heading}>Risks</Text>
                {(<Text style={styles.muted}>No risks found.</Text>) if len(view.risks) == 0 else <View/>}
                {[
                    <Text key={str(index)} style={styles.warn}>{"• " + flag.item_name + ": " + flag.reason}</Text>
                    for (index, flag) in enumerate(view.risks)
                ]}
            </View>

            <View style={styles.card}>
                <Text style={styles.heading}>Planned items</Text>
                {[
                    <View key={item.num} style={{"gap": 4, "paddingTop": 6}}>
                        <Text style={styles.text}>
                            {"#" + str(item.num) + " " + item.kind + ": " + item.name + (" (fixed)" if item.fixed else "") + (" (DISRUPTED)" if item.disrupted else "")}
                        </Text>
                        <Text style={styles.muted}>{item.date + " · " + money(item.cost + item.taxes_fees) + " · refund " + item.refund_policy}</Text>
                        {(<View style={styles.row}>
                            <Button label="Simulate disruption" look="orange" onPress={lambda { disrupt(item.num); }}/>
                        </View>) if not item.disrupted else <View/>}
                    </View>
                    for item in view.items if item.selected
                ]}
            </View>

            <View style={styles.card}>
                <Text style={styles.heading}>Quick add</Text>
                <View style={styles.row}>
                    {[
                        <Pressable key={choice} style={styles.chipOn if kind == choice else styles.chip} onPress={lambda { kind = choice; }}>
                            <Text style={styles.buttonText if kind == choice else styles.text}>{choice}</Text>
                        </Pressable>
                        for choice in ["hotel", "flight", "activity"]
                    ]}
                </View>
                <TextInput style={styles.input} placeholder="Name" value={name}
                    onChangeText={lambda (t: str) { name = t; }}/>
                <TextInput style={styles.input} placeholder="Date YYYY-MM-DD" value={item_date}
                    onChangeText={lambda (t: str) { item_date = t; }}/>
                <TextInput style={styles.input} placeholder="Cost in USD" value={cost} keyboardType="numeric"
                    onChangeText={lambda (t: str) { cost = t; }}/>
                <View style={styles.row}>
                    <Switch value={as_option} onValueChange={lambda (v: bool) { as_option = v; }}/>
                    <Text style={styles.text}>Just an option (not in the plan)</Text>
                </View>
                <Text style={styles.muted}>Flags start as unknown; edit details on the web or CLI.</Text>
                <Button label="Add item" onPress={quick_add}/>
            </View>
        </View>) if view and view.has_trip else <View/>}
    </ScrollView>
}
