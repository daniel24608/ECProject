"""Web app entry point. `jac run` serves this page and the planner server."""

import "./styles.css";
import from web.components.TripPage { TripPage }

def:pub app -> JsxElement {
    return <TripPage/>;
}
