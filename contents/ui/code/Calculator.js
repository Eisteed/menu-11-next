/*
 * Small, bounded arithmetic evaluator used by the "/" command palette.
 *
 * Security note: this intentionally does NOT use eval()/Function(). Only
 * numbers and the operators + - * / % ^ ( ) are accepted; the result is
 * always a finite number, so it can never contain shell metacharacters.
 */

.pragma library

var MAX_EXPRESSION_LENGTH = 256

function tokenize(src) {
    var out = []
    for (var i = 0; i < src.length; i++) {
        var c = src.charAt(i)
        if (c >= "0" && c <= "9") {
            var j = i + 1
            while (j < src.length && ((src.charAt(j) >= "0" && src.charAt(j) <= "9") || src.charAt(j) === "."))
                j++
            var num = parseFloat(src.slice(i, j))
            if (isNaN(num))
                return null
            out.push(num)
            i = j - 1
        } else if ("+-*/%^()".indexOf(c) !== -1) {
            out.push(c)
        } else {
            return null
        }
    }
    return out.length ? out : null
}

// Returns a finite number, or NaN for invalid/overflowing input.
function evaluate(expression) {
    if (typeof expression !== "string" || expression.length === 0 || expression.length > MAX_EXPRESSION_LENGTH)
        return NaN

    var tokens = tokenize(expression.replace(/\s+/g, ""))
    if (!tokens)
        return NaN

    var pos = 0

    function peek() { return pos < tokens.length ? tokens[pos] : null }
    function take() { return tokens[pos++] }

    function parseExpression() {
        var value = parseTerm()
        while (peek() === "+" || peek() === "-") {
            var op = take()
            var rhs = parseTerm()
            value = op === "+" ? value + rhs : value - rhs
        }
        return value
    }

    function parseTerm() {
        var value = parseUnary()
        while (peek() === "*" || peek() === "/" || peek() === "%") {
            var op = take()
            var rhs = parseUnary()
            if ((op === "/" || op === "%") && rhs === 0)
                return NaN
            value = op === "*" ? value * rhs : (op === "/" ? value / rhs : value % rhs)
        }
        return value
    }

    function parseUnary() {
        var t = peek()
        if (t === "+") { take(); return parseUnary() }
        if (t === "-") { take(); return -parseUnary() }
        return parsePower()
    }

    function parsePower() {
        var base = parsePrimary()
        if (peek() === "^") {
            take()
            return Math.pow(base, parseUnary())
        }
        return base
    }

    function parsePrimary() {
        var t = take()
        if (t === "(") {
            var value = parseExpression()
            if (take() !== ")")
                return NaN
            return value
        }
        if (typeof t === "number")
            return t
        return NaN
    }

    var result = parseExpression()
    if (pos !== tokens.length || !isFinite(result))
        return NaN
    return result
}
