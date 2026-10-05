"""The `trip` command-line client.

Every command calls the planner server (the same one the web and mobile apps
use), so it needs `jac run` to be running in another terminal.
Run it with:  jac run cli -- <command> [options]
"""

import argparse;
import asyncio;
import os;
import sys;
import from jaclang.server { sv_client }
import from jaclang.server.bridge { BridgeError }
import from core.views { TripView }
import from core.server {
    get_trip,
    init_trip,
    add_item,
    disrupt_item,
    accept_proposal,
    reject_proposal,
    seed_trip
}
import from cli.show {
    show_message,
    show_summary,
    show_items,
    show_risks,
    show_replan_notes
}

glob DEFAULT_SERVER: str = "http://localhost:8000/api/planner";

"""Build the argument parser with one sub-command per action."""
def build_parser -> argparse.ArgumentParser {
    parser = argparse.ArgumentParser(
        prog="trip", description="Travel planner CLI (talks to the running server)."
    );
    parser.add_argument(
        "--server",
        `default=os.environ.get("TRIP_SERVER", DEFAULT_SERVER),
        help="planner server URL (default " + DEFAULT_SERVER + ")"
    );
    commands = parser.add_subparsers(dest="command", metavar="<command>", required=True);

    commands.add_parser("seed", help="load the sample Lisbon trip");
    commands.add_parser("status", help="show the trip, items, and budget");
    commands.add_parser("risks", help="show risk flags and pending proposals");

    init = commands.add_parser("init", help="create a new trip (replaces the old one)");
    init.add_argument("destination");
    init.add_argument("--start", required=True, help="start date YYYY-MM-DD");
    init.add_argument("--end", required=True, help="end date YYYY-MM-DD");
    init.add_argument("--budget", `type=float, required=True, help="total budget in USD");
    init.add_argument("--contingency", `type=float, `default=10.0, help="percent kept aside (default 10)");
    init.add_argument("--travelers", `type=int, `default=1);
    init.add_argument("--kids", action="store_true", help="traveling with kids");
    init.add_argument("--pet", action="store_true", help="traveling with a pet");
    init.add_argument("--accessible", action="store_true", help="needs accessibility");
    init.add_argument("--diet", `default="", help='dietary needs, e.g. "vegetarian, nut allergy"');

    add = commands.add_parser("add-item", help="add a hotel, flight, or activity");
    add.add_argument("kind", choices=["hotel", "flight", "activity"]);
    add.add_argument("name");
    add.add_argument("--date", required=True, help="YYYY-MM-DD");
    add.add_argument("--cost", `type=float, required=True);
    add.add_argument("--taxes", `type=float, `default=0.0, help="taxes and fees");
    add.add_argument("--city", `default="");
    flag_choices = ["yes", "no", "unknown"];
    add.add_argument("--pet-ok", choices=flag_choices, `default="unknown");
    add.add_argument("--kid-ok", choices=flag_choices, `default="unknown");
    add.add_argument("--accessible", choices=flag_choices, `default="unknown");
    add.add_argument("--diet-ok", choices=flag_choices, `default="unknown");
    add.add_argument(
        "--refund",
        choices=["refundable", "partial", "non-refundable", "unknown"],
        `default="unknown"
    );
    add.add_argument("--deadline", `default="", help="cancellation deadline YYYY-MM-DD");
    add.add_argument("--fixed", action="store_true", help="keep this item no matter what");
    add.add_argument("--option", action="store_true", help="save as an option, not in the plan");

    disrupt = commands.add_parser("disrupt", help="simulate a disruption on an item");
    disrupt.add_argument("item", `type=int, help="item number");
    accept = commands.add_parser("accept", help="accept a proposal");
    accept.add_argument("proposal", `type=int, help="proposal number");
    reject = commands.add_parser("reject", help="reject a proposal (nothing changes)");
    reject.add_argument("proposal", `type=int, help="proposal number");
    return parser;
}

"""Call the server for one command and return the trip view it sends back."""
async def call_server(args: argparse.Namespace) -> TripView {
    command = args.command;
    if command == "seed" {
        return await seed_trip();
    }
    if command == "init" {
        return await init_trip(
            destination=args.destination,
            start_date=args.start,
            end_date=args.end,
            budget=args.budget,
            contingency_percent=args.contingency,
            travelers=args.travelers,
            with_kids=args.kids,
            with_pet=args.pet,
            dietary_needs=args.diet,
            needs_accessibility=args.accessible
        );
    }
    if command == "add-item" {
        return await add_item(
            kind=args.kind,
            name=args.name,
            item_date=args.date,
            cost=args.cost,
            taxes_fees=args.taxes,
            city=args.city,
            pet_friendly=args.pet_ok,
            kid_friendly=args.kid_ok,
            accessible=args.accessible,
            diet_friendly=args.diet_ok,
            refund_policy=args.refund,
            cancel_deadline=args.deadline,
            fixed=args.fixed,
            selected=not args.option
        );
    }
    if command == "disrupt" {
        return await disrupt_item(args.item);
    }
    if command == "accept" {
        return await accept_proposal(args.proposal);
    }
    if command == "reject" {
        return await reject_proposal(args.proposal);
    }
    return await get_trip();
}

"""Print the right parts of the view for each command."""
def print_result(command: str, view: TripView) {
    show_message(view);
    if not view.has_trip {
        print("No trip yet. Try:  jac run cli -- seed");
        return;
    }
    if command in ["seed", "init", "add-item", "status", "accept"] {
        show_summary(view);
        show_items(view);
    }
    if command in ["seed", "risks", "disrupt", "accept", "reject"] {
        show_risks(view);
    }
    if command == "disrupt" {
        show_replan_notes(view);
    }
}

"""Run one command. Returns the exit code (0 means success)."""
async def main(argv: list[str]) -> int {
    args = build_parser().parse_args(argv);
    sv_client.register("planner", args.server);
    try {
        view = await call_server(args);
    } except BridgeError as e {
        print("Could not talk to the planner server at " + args.server, file=sys.stderr);
        print("Is it running? Start it with `jac run` in the project folder.", file=sys.stderr);
        print("Details: " + str(e), file=sys.stderr);
        return 3;
    }
    print_result(args.command, view);
    return 0 if view.ok else 1;
}

with entry:__main__ {
    sys.`exit(asyncio.run(main(sys.argv[1:])));
}
