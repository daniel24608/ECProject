"""Mobile app entry point. Run with `jac run --dev --platform web mobile` (browser)
or `jac run --dev mobile` (phone via Expo). It talks to the server started by `jac run`.
"""

import from mobile.TripScreen { TripScreen }

def:pub app -> JsxElement {
    return <TripScreen/>;
}
