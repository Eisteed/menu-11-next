#!/usr/bin/env bash
# Swin-11 static checks. Run from anywhere: ./tests/run.sh [--smoke]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== qmllint =="
QMLLINT="${QMLLINT:-}"
if [ -z "$QMLLINT" ]; then
    for candidate in /usr/lib/qt6/bin/qmllint "$(command -v qmllint6 || true)" "$(command -v qmllint || true)"; do
        if [ -n "$candidate" ] && [ -x "$candidate" ] && "$candidate" --help >/dev/null 2>&1; then
            QMLLINT="$candidate"
            break
        fi
    done
fi
[ -n "$QMLLINT" ] || fail "qmllint not found (install qt6-declarative-dev-tools or qtdeclarative5-dev-tools)"
while IFS= read -r -d '' f; do
    out="$("$QMLLINT" "$f" 2>&1)" || fail "qmllint failed on $f: $out"
    if [ -n "$out" ]; then
        echo "$out" | sed -n 's/^\(Error\|Warning\):/  \1:/p' | awk 'NR <= 3'
    fi
done < <(find contents -name '*.qml' -print0 | sort -z)
echo "  no qmllint errors (Qt6 style warnings are informational)"

echo "== XML =="
python3 - <<'PY'
import xml.dom.minidom
xml.dom.minidom.parse("contents/config/main.xml")
print("  main.xml OK")
PY

echo "== JS syntax =="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for f in contents/ui/code/*.js contents/ui/*.js; do
    grep -v '^\.pragma library$' "$f" > "$TMP/$(basename "$f")"
    node --check "$TMP/$(basename "$f")" >/dev/null || fail "syntax error in $f"
done
echo "  all JS parse OK"

echo "== calculator unit tests =="
cp "$TMP/Calculator.js" "$TMP/calculator-test.js"
cat >> "$TMP/calculator-test.js" <<'JS'
const cases = [
  ["2+2", 4], ["2*(3+4)", 14], ["10/4", 2.5], ["1+2*3", 7],
  ["2^3^2", 512], ["1/0", NaN], ["2+", NaN], ["abc", NaN],
  ["'; touch /tmp/nope; echo '", NaN]
];
for (const [expr, want] of cases) {
  const got = evaluate(expr);
  if (!(Number.isNaN(got) && Number.isNaN(want)) && got !== want)
    throw new Error(expr + ": expected " + want + ", got " + got);
}
JS
node "$TMP/calculator-test.js" || fail "Calculator.js unit tests"
echo "  calculator OK (including injection strings rejected)"

echo "== config sync wiring =="
grep -q 'syncConfigAcrossPanels' contents/config/main.xml || fail "sync toggle missing from main.xml"
grep -q 'SharedConfig' contents/ui/main.qml || fail "SharedConfig not instantiated"
grep -q 'swin11-shared.conf' README.md || fail "sync feature undocumented"
echo "  sync wiring OK"

if [ "${1:-}" = "--smoke" ]; then
    echo "== runtime smoke ( Plasma session required ) =="
    command -v kpackagetool6 >/dev/null || fail "kpackagetool6 missing"
    kpackagetool6 --type Plasma/Applet --upgrade . >/dev/null || fail "install failed"
    MARK="$(date '+%Y-%m-%d %H:%M:%S')"
    QT_QPA_PLATFORM=xcb timeout 15 plasmawindowed menu.11.next >/dev/null 2>&1 || true
    BAD="$(journalctl --user --since "$MARK" --no-pager 2>/dev/null \
          | grep -E 'ReferenceError|TypeError|is not a function' || true)"
    [ -z "$BAD" ] || fail "runtime errors:$BAD"
    echo "  runtime clean"
fi

echo "ALL CHECKS PASSED"
