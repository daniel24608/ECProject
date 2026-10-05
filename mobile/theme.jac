"""Colors and styles for the mobile app (React Native StyleSheet, no CSS)."""

import from "@jac/mobui" { StyleSheet }

obj Palette {
    has bg: str = "#f4f6f9",
        card: str = "#ffffff",
        border: str = "#dde2ea",
        text: str = "#1d2330",
        muted: str = "#667085",
        accent: str = "#2563eb",
        good: str = "#15803d",
        warn: str = "#b45309",
        bad: str = "#b91c1c";
}

glob:pub C: Palette = Palette();

glob:pub styles = StyleSheet.create({
    screen: {flex: 1, backgroundColor: C.bg},
    body: {padding: 16, gap: 12},
    title: {fontSize: 26, fontWeight: "bold", color: C.text},
    card: {
        backgroundColor: C.card,
        borderColor: C.border,
        borderWidth: 1,
        borderRadius: 12,
        padding: 14,
        gap: 6
    },
    heading: {fontSize: 18, fontWeight: "bold", color: C.text},
    text: {fontSize: 14, color: C.text},
    muted: {fontSize: 13, color: C.muted},
    good: {fontSize: 14, color: C.good},
    warn: {fontSize: 14, color: C.warn},
    bad: {fontSize: 14, color: C.bad},
    row: {flexDirection: "row", gap: 8, alignItems: "center", flexWrap: "wrap"},
    button: {
        backgroundColor: C.accent,
        borderRadius: 8,
        paddingVertical: 8,
        paddingHorizontal: 12,
        alignItems: "center"
    },
    buttonGrey: {
        backgroundColor: "#e5e7eb",
        borderRadius: 8,
        paddingVertical: 8,
        paddingHorizontal: 12,
        alignItems: "center"
    },
    buttonOrange: {
        backgroundColor: C.warn,
        borderRadius: 8,
        paddingVertical: 6,
        paddingHorizontal: 10,
        alignItems: "center"
    },
    buttonText: {color: "#ffffff", fontWeight: "bold", fontSize: 14},
    buttonTextDark: {color: C.text, fontWeight: "bold", fontSize: 14},
    chip: {
        borderColor: C.border,
        borderWidth: 1,
        borderRadius: 999,
        paddingVertical: 6,
        paddingHorizontal: 12
    },
    chipOn: {
        backgroundColor: C.accent,
        borderColor: C.accent,
        borderWidth: 1,
        borderRadius: 999,
        paddingVertical: 6,
        paddingHorizontal: 12
    },
    input: {
        borderColor: C.border,
        borderWidth: 1,
        borderRadius: 8,
        padding: 8,
        fontSize: 14,
        color: C.text,
        backgroundColor: "#ffffff"
    },
    message: {backgroundColor: "#dcfce7", borderRadius: 8, padding: 10},
    errorMessage: {backgroundColor: "#fee2e2", borderRadius: 8, padding: 10}
});
