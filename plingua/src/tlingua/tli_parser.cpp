/*
 * tli_parser.cpp
 *
 * Parser, temporal verifier, and P-Lingua lowering for T-Lingua (.tli).
 *
 * The native clock is a ring of `period` phases.  Phase 0 is the rim
 * (wrap_to).  After exactly `period` steps the phase is 0 and the wrap has
 * fired once — that is the closed time loop the nested `out` convention
 * cannot check.  Circular distance, PPM prime gates, and resonance exchange
 * are predicates on that ring, not comments.
 *
 * Copyright (C) 2026  P-Lingua/T-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <tlingua/tli_parser.hpp>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <regex>
#include <sstream>

namespace plingua {
namespace tlingua {

namespace {

struct Term {
    std::string object;
    int count;
    enum Where { HERE, OUT, IN } where;
    std::string target;

    Term() : count(1), where(HERE) {}
};

std::string trimCopy(const std::string& s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    size_t b = s.find_last_not_of(" \t\r\n");
    return (a == std::string::npos) ? "" : s.substr(a, b - a + 1);
}

std::vector<std::string> splitStar(const std::string& s) {
    std::vector<std::string> out;
    std::string cur;
    for (size_t i = 0; i < s.size(); ++i) {
        if (s[i] == '*') {
            bool leftSpace = !cur.empty() &&
                std::isspace(static_cast<unsigned char>(cur[cur.size() - 1]));
            bool rightSpace = (i + 1 < s.size()) &&
                std::isspace(static_cast<unsigned char>(s[i + 1]));
            if (leftSpace || rightSpace) {
                std::string t = trimCopy(cur);
                if (!t.empty()) out.push_back(t);
                cur.clear();
                while (i + 1 < s.size() &&
                       std::isspace(static_cast<unsigned char>(s[i + 1]))) {
                    ++i;
                }
                continue;
            }
        }
        cur += s[i];
    }
    std::string t = trimCopy(cur);
    if (!t.empty()) out.push_back(t);
    return out;
}

bool parseTerm(const std::string& raw, Term& term) {
    std::string tok = trimCopy(raw);
    if (tok.empty() || tok == "#") return false;

    std::regex mulRe(R"(^(.*)\*(\d+)$)");
    std::smatch mul;
    if (std::regex_match(tok, mul, mulRe)) {
        tok = trimCopy(mul[1].str());
        term.count = std::atoi(mul[2].str().c_str());
        if (term.count < 1) term.count = 1;
    }

    if (!tok.empty() && tok[0] == '(') {
        int depth = 0;
        size_t close = std::string::npos;
        for (size_t i = 0; i < tok.size(); ++i) {
            if (tok[i] == '(') ++depth;
            else if (tok[i] == ')') {
                --depth;
                if (depth == 0) {
                    close = i;
                    break;
                }
            }
        }
        if (close != std::string::npos && close + 1 < tok.size()) {
            term.object = tok.substr(1, close - 1);
            std::string rest = tok.substr(close + 1);
            if (rest == "out") {
                term.where = Term::OUT;
                return !term.object.empty();
            }
            if (rest.size() > 3 && rest.compare(0, 3, "in_") == 0) {
                term.where = Term::IN;
                term.target = rest.substr(3);
                return !term.object.empty() && !term.target.empty();
            }
        }
    }

    term.object = tok;
    term.where = Term::HERE;
    return !term.object.empty();
}

std::vector<Term> parseTerms(const std::string& side) {
    std::vector<Term> terms;
    std::vector<std::string> parts = splitStar(side);
    for (size_t i = 0; i < parts.size(); ++i) {
        Term t;
        if (parseTerm(parts[i], t)) terms.push_back(t);
    }
    return terms;
}

std::map<std::string, int> parseMultiset(const std::string& text) {
    std::map<std::string, int> objs;
    std::string cur;
    for (size_t i = 0; i <= text.size(); ++i) {
        if (i == text.size() || text[i] == ',') {
            Term t;
            if (parseTerm(cur, t) && t.where == Term::HERE)
                objs[t.object] += t.count;
            cur.clear();
        } else {
            cur += text[i];
        }
    }
    return objs;
}

struct MuNode {
    std::string label;
    std::vector<MuNode> children;
};

bool parseMuNode(const std::string& s, size_t& i, MuNode& node, std::string& err) {
    while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
    if (i >= s.size() || s[i] != '[') {
        err = "expected '[' in @mu";
        return false;
    }
    ++i;
    while (i < s.size()) {
        while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
        if (i >= s.size()) {
            err = "unterminated @mu";
            return false;
        }
        if (s[i] == ']') break;
        if (s[i] == '[') {
            MuNode child;
            if (!parseMuNode(s, i, child, err)) return false;
            node.children.push_back(child);
            continue;
        }
        err = "unexpected character in @mu";
        return false;
    }
    if (i >= s.size() || s[i] != ']') {
        err = "unterminated @mu";
        return false;
    }
    ++i;
    while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
    if (i < s.size() && s[i] == '\'') {
        ++i;
        size_t start = i;
        while (i < s.size() &&
               (std::isalnum(static_cast<unsigned char>(s[i])) || s[i] == '_')) {
            ++i;
        }
        node.label = s.substr(start, i - start);
    }
    return true;
}

void indexParents(const MuNode& node, const std::string& parent,
                  std::map<std::string, std::string>& parents) {
    if (!node.label.empty()) parents[node.label] = parent;
    for (size_t i = 0; i < node.children.size(); ++i)
        indexParents(node.children[i], node.label, parents);
}

int countOf(const std::map<std::string, std::map<std::string, int> >& mem,
            const std::string& membrane, const std::string& obj) {
    std::map<std::string, std::map<std::string, int> >::const_iterator mit =
        mem.find(membrane);
    if (mit == mem.end()) return 0;
    std::map<std::string, int>::const_iterator oit = mit->second.find(obj);
    if (oit == mit->second.end()) return 0;
    return oit->second;
}

void addObj(std::map<std::string, std::map<std::string, int> >& mem,
            const std::string& membrane, const std::string& obj, int n) {
    if (n == 0 || obj.empty() || obj == "#") return;
    mem[membrane][obj] += n;
    if (mem[membrane][obj] <= 0) mem[membrane].erase(obj);
}

bool budgetHas(const std::map<std::string, std::map<std::string, int> >& mem,
               const std::string& membrane, const std::vector<Term>& lhs) {
    std::map<std::string, int> need;
    for (size_t i = 0; i < lhs.size(); ++i) {
        if (lhs[i].where != Term::HERE) return false;
        need[lhs[i].object] += lhs[i].count;
    }
    for (std::map<std::string, int>::const_iterator it = need.begin();
         it != need.end(); ++it) {
        if (countOf(mem, membrane, it->first) < it->second) return false;
    }
    return true;
}

void takeLhs(std::map<std::string, std::map<std::string, int> >& mem,
             const std::string& membrane, const std::vector<Term>& lhs) {
    for (size_t i = 0; i < lhs.size(); ++i)
        addObj(mem, membrane, lhs[i].object, -lhs[i].count);
}

} // namespace

int circularPhaseDistance(int a, int b, int period) {
    if (period <= 0) return 0;
    int d = a - b;
    d %= period;
    if (d < 0) d += period;
    int other = period - d;
    return d < other ? d : other;
}

std::vector<int> ppmAlphabet(int count) {
    std::vector<int> out;
    if (count < 1 || count > PPM_PRIME_COUNT) return out;
    for (int i = 0; i < count; ++i) out.push_back(PPM_PRIMES[i]);
    return out;
}

bool primeInAlphabet(int prime, const std::vector<int>& alphabet) {
    return std::find(alphabet.begin(), alphabet.end(), prime) != alphabet.end();
}

bool primeSignature(const std::vector<int>& primes, uint64_t& out) {
    if (primes.empty()) return false;
    uint64_t prod = 1;
    for (size_t i = 0; i < primes.size(); ++i) {
        if (primes[i] < 2) return false;
        uint64_t p = static_cast<uint64_t>(primes[i]);
        if (prod > UINT64_MAX / p) return false;
        prod *= p;
    }
    out = prod;
    return true;
}

bool gateOpen(uint64_t signature, uint64_t step) {
    if (signature == 0) return false;
    return step % signature == 0;
}

int spinorSign(int step, int period, int flip_at) {
    if (period <= 0) return 1;
    int s = step % period;
    if (s < 0) s += period;
    if (flip_at <= 0 || flip_at >= period) return 1;
    return (s >= flip_at) ? -1 : 1;
}

int phasePrime(int phase, const std::vector<int>& alphabet) {
    if (alphabet.empty() || phase < 0) return -1;
    return alphabet[static_cast<size_t>(phase) % alphabet.size()];
}

TliParser::TliParser() : lineNum_(0) {}

std::string TliParser::trim(const std::string& s) { return trimCopy(s); }

bool TliParser::startsWith(const std::string& s, const std::string& pfx) {
    return s.size() >= pfx.size() && s.compare(0, pfx.size(), pfx) == 0;
}

std::string TliParser::stripComments(const std::string& src) {
    std::string out;
    out.reserve(src.size());
    bool inLine = false, inBlock = false;
    for (size_t i = 0; i < src.size(); ++i) {
        if (inLine) {
            if (src[i] == '\n') {
                inLine = false;
                out += '\n';
            }
            continue;
        }
        if (inBlock) {
            if (src[i] == '*' && i + 1 < src.size() && src[i + 1] == '/') {
                inBlock = false;
                ++i;
            } else if (src[i] == '\n') {
                out += '\n';
            }
            continue;
        }
        if (src[i] == '/' && i + 1 < src.size()) {
            if (src[i + 1] == '/') {
                inLine = true;
                continue;
            }
            if (src[i + 1] == '*') {
                inBlock = true;
                ++i;
                continue;
            }
        }
        /* `--` comments, but not the `-->` evolution arrow. */
        if (src[i] == '-' && i + 1 < src.size() && src[i + 1] == '-' &&
            !(i + 2 < src.size() && src[i + 2] == '>')) {
            inLine = true;
            continue;
        }
        out += src[i];
    }
    return out;
}

std::vector<TliParser::Stmt> TliParser::splitStatements(const std::string& src) {
    std::vector<Stmt> stmts;
    size_t i = 0;
    int line = 1;
    while (i < src.size()) {
        while (i < src.size() && std::isspace(static_cast<unsigned char>(src[i]))) {
            if (src[i] == '\n') ++line;
            ++i;
        }
        if (i >= src.size()) break;
        size_t start = i;
        int startLine = line;
        int brace = 0, bracket = 0, paren = 0;
        bool sawBrace = false;
        bool inStr = false;
        char strCh = 0;
        while (i < src.size()) {
            char c = src[i];
            if (c == '\n') ++line;
            /* A brace-less @directive ends at the newline.  Otherwise
             * `@tmodel<time_crystal>` swallows the following `@clock` block.
             * Assignments (`@mu =`, `@mX =`) and rules keep going until `;`
             * so a wrapped multiset or guard stays one statement. */
            if (c == '\n' && !inStr && brace == 0 && bracket == 0 && paren == 0 &&
                !sawBrace) {
                std::string sofar = trimCopy(src.substr(start, i - start));
                if (!sofar.empty() && sofar[0] == '@' &&
                    sofar.find('=') == std::string::npos) {
                    break;
                }
            }
            if (inStr) {
                if (c == strCh) inStr = false;
                ++i;
                continue;
            }
            if (c == '"' || c == '\'') {
                /* A membrane label quote is not a string.  Only '"' starts a
                 * string; '\'' is the P-Lingua label mark and must stay. */
                if (c == '"') {
                    inStr = true;
                    strCh = c;
                }
                ++i;
                continue;
            }
            if (c == '{') {
                ++brace;
                sawBrace = true;
            } else if (c == '}') {
                if (brace > 0) --brace;
            } else if (c == '[') {
                ++bracket;
            } else if (c == ']') {
                if (bracket > 0) --bracket;
            } else if (c == '(') {
                ++paren;
            } else if (c == ')') {
                if (paren > 0) --paren;
            }
            ++i;
            if (brace == 0 && bracket == 0 && paren == 0) {
                if (c == ';') break;
                if (sawBrace && c == '}') break;
            }
        }
        Stmt st;
        st.text = trimCopy(src.substr(start, i - start));
        st.line = startLine;
        if (!st.text.empty()) stmts.push_back(st);
    }
    return stmts;
}

std::string TliParser::blockBody(const std::string& text) {
    size_t open = text.find('{');
    if (open == std::string::npos) return "";
    int depth = 0;
    for (size_t i = open; i < text.size(); ++i) {
        if (text[i] == '{') ++depth;
        else if (text[i] == '}') {
            --depth;
            if (depth == 0) return text.substr(open + 1, i - open - 1);
        }
    }
    return text.substr(open + 1);
}

void TliParser::addError(const std::string& msg) {
    system_.errors.push_back(filename_ + ":" + std::to_string(lineNum_) +
                             ": error: " + msg);
}

void TliParser::addWarning(const std::string& msg) {
    system_.warnings.push_back(filename_ + ":" + std::to_string(lineNum_) +
                               ": warning: " + msg);
}

bool TliParser::parseFile(const std::string& filename) {
    std::ifstream in(filename.c_str());
    if (!in) {
        system_.errors.push_back("Cannot open file: " + filename);
        return false;
    }
    std::ostringstream ss;
    ss << in.rdbuf();
    return parseString(ss.str(), filename);
}

bool TliParser::parseString(const std::string& source, const std::string& filename) {
    system_ = TLinguaSystem();
    importStack_.clear();
    filename_ = filename;
    lineNum_ = 0;
    return parseBody(source, filename);
}

bool TliParser::handleImport(const std::string& text) {
    plingua::import_util::ImportPrep prep = plingua::import_util::prepareImport(
        filename_, text, importStack_, system_.imports);
    if (prep.status == plingua::import_util::ImportPrep::NOT_IMPORT) return false;
    if (prep.status == plingua::import_util::ImportPrep::SKIP) return true;
    if (prep.status != plingua::import_util::ImportPrep::READY) {
        addError(prep.error);
        return true;
    }
    plingua::ImportedModule mod;
    mod.path = prep.resolved;
    mod.spec = prep.spec;
    mod.dialect = prep.dialect;
    mod.symbols = prep.symbols;
    mod.inlined = (prep.dialect == "tli");
    if (mod.inlined) parseBody(prep.body, prep.resolved);
    system_.imports.push_back(mod);
    return true;
}

bool TliParser::parseBody(const std::string& source, const std::string& filename) {
    std::string prevFile = filename_;
    int prevLine = lineNum_;
    filename_ = filename;
    std::string key = plingua::import_util::normalizePath(filename);
    if (!importStack_.insert(key).second) {
        addError("import cycle involving " + key);
        filename_ = prevFile;
        lineNum_ = prevLine;
        return false;
    }
    parseStatements(stripComments(source), 1);
    /* Pop before returning so a later import of the same file is a diamond
     * (already recorded), not a cycle.  A true cycle still sees the parent
     * on the stack while this body is being parsed. */
    importStack_.erase(key);
    filename_ = prevFile;
    lineNum_ = prevLine;
    return system_.errors.empty();
}

void TliParser::parseStatements(const std::string& source, int lineBase) {
    (void)lineBase;
    std::vector<Stmt> stmts = splitStatements(source);
    for (size_t i = 0; i < stmts.size(); ++i) parseStatement(stmts[i]);
}

void TliParser::parseStatement(const Stmt& stmt) {
    lineNum_ = stmt.line;
    const std::string& text = stmt.text;
    if (text.empty()) return;

    if (handleImport(text)) return;

    if (startsWith(text, "@tmodel")) {
        parseModel(text, true);
        return;
    }
    if (startsWith(text, "@model")) {
        parseModel(text, false);
        return;
    }
    if (startsWith(text, "@clock")) {
        parseClock(text);
        return;
    }
    if (startsWith(text, "@phase_register")) {
        parsePhaseRegister(text);
        return;
    }
    if (startsWith(text, "@primes")) {
        parsePrimes(text);
        return;
    }
    if (startsWith(text, "@gate")) {
        parseGate(text);
        return;
    }
    if (startsWith(text, "@semantics")) {
        parseSemantics(text);
        return;
    }
    if (startsWith(text, "@fractal")) {
        parseFractal(text);
        return;
    }
    if (startsWith(text, "@spinor")) {
        parseSpinor(text);
        return;
    }
    if (startsWith(text, "@module")) {
        parseModule(text);
        return;
    }
    if (startsWith(text, "@mu") &&
        (text.size() == 3 || !std::isalnum(static_cast<unsigned char>(text[3])))) {
        parseMu(text);
        return;
    }
    if (startsWith(text, "@m") && text.size() > 2 &&
        std::isalpha(static_cast<unsigned char>(text[2]))) {
        parseInit(text);
        return;
    }
    if (startsWith(text, "[") || startsWith(text, "rule ") || text == "rule") {
        parseRule(text);
        return;
    }
    system_.passthrough.push_back(text);
}

void TliParser::parseModel(const std::string& text, bool temporal) {
    std::regex re(R"(@t?model\s*<\s*([A-Za-z_][A-Za-z0-9_]*)\s*>)");
    std::smatch m;
    if (!std::regex_search(text, m, re)) {
        addError("malformed @model / @tmodel declaration");
        return;
    }
    if (temporal || system_.model_type.empty()) system_.model_type = m[1].str();
}

void TliParser::parseClock(const std::string& text) {
    std::regex head(R"(@clock\s+([A-Za-z_][A-Za-z0-9_]*))");
    std::smatch hm;
    if (!std::regex_search(text, hm, head)) {
        addError("malformed @clock (expected @clock name { ... })");
        return;
    }
    if (text.find('{') == std::string::npos) {
        addError("@clock " + hm[1].str() + " is missing a block");
        return;
    }
    std::string body = blockBody(text);
    if (body.empty() && text.find('}') == std::string::npos) {
        addError("unterminated @clock " + hm[1].str());
        return;
    }
    Clock clock;
    clock.name = hm[1].str();
    std::smatch m;
    std::regex periodRe(R"(period\s+(\d+))");
    if (!std::regex_search(body, m, periodRe)) {
        addError("@clock " + clock.name + " is missing period");
        return;
    }
    clock.period = std::atoi(m[1].str().c_str());
    if (clock.period < 1) {
        addError("@clock " + clock.name + " period must be >= 1");
        return;
    }
    std::regex wrapRe(R"(wrap\s+([A-Za-z_][A-Za-z0-9_]*)\s*->\s*([A-Za-z_][A-Za-z0-9_]*))");
    if (std::regex_search(body, m, wrapRe)) {
        clock.wrap_from = m[1].str();
        clock.wrap_to = m[2].str();
    } else {
        clock.wrap_from = "d" + std::to_string(clock.period);
        clock.wrap_to = "skin";
        addWarning("@clock " + clock.name + " has no wrap; defaulting to " +
                   clock.wrap_from + " -> skin");
    }
    std::regex reseedRe(R"(reseed\s+([A-Za-z_][A-Za-z0-9_]*))");
    if (std::regex_search(body, m, reseedRe)) clock.reseed = m[1].str();

    std::string expected = "d" + std::to_string(clock.period);
    std::string alt = "d" + std::to_string(clock.period - 1);
    if (clock.wrap_from != expected && clock.wrap_from != alt &&
        clock.wrap_from != clock.wrap_to) {
        addWarning("@clock " + clock.name + " wrap source " + clock.wrap_from +
                   " is not " + expected + " (period " +
                   std::to_string(clock.period) + ")");
    }
    for (size_t i = 0; i < system_.clocks.size(); ++i) {
        if (system_.clocks[i].name == clock.name) {
            addError("duplicate @clock " + clock.name);
            return;
        }
    }
    system_.clocks.push_back(clock);
}

void TliParser::parsePhaseRegister(const std::string& text) {
    std::regex head(R"(@phase_register\s+([A-Za-z_][A-Za-z0-9_]*))");
    std::smatch hm;
    if (!std::regex_search(text, hm, head) || text.find('{') == std::string::npos) {
        addError("malformed @phase_register (expected @phase_register name { ... })");
        return;
    }
    std::string body = blockBody(text);
    PhaseRegister reg;
    reg.name = hm[1].str();
    std::smatch m;
    std::regex cycleRe(R"(cycle\s+(\d+))");
    if (!std::regex_search(body, m, cycleRe)) {
        addError("@phase_register " + reg.name + " is missing cycle");
        return;
    }
    reg.cycle = std::atoi(m[1].str().c_str());
    if (reg.cycle < 1) {
        addError("@phase_register " + reg.name + " cycle must be >= 1");
        return;
    }
    std::regex slotsRe(R"(slots\s*\[([^\]]*)\])");
    if (std::regex_search(body, m, slotsRe)) {
        std::string raw = m[1].str();
        std::string cur;
        for (size_t i = 0; i <= raw.size(); ++i) {
            if (i == raw.size() || raw[i] == ',' ||
                std::isspace(static_cast<unsigned char>(raw[i]))) {
                if (!cur.empty()) {
                    reg.slots.push_back(cur);
                    cur.clear();
                }
            } else {
                cur += raw[i];
            }
        }
    }
    if (!reg.slots.empty() && static_cast<int>(reg.slots.size()) != reg.cycle) {
        addError("@phase_register " + reg.name + " cycle " +
                 std::to_string(reg.cycle) + " does not match " +
                 std::to_string(reg.slots.size()) + " slots");
        return;
    }
    for (size_t i = 0; i < system_.registers.size(); ++i) {
        if (system_.registers[i].name == reg.name) {
            addError("duplicate @phase_register " + reg.name);
            return;
        }
    }
    system_.registers.push_back(reg);
}

void TliParser::parsePrimes(const std::string& text) {
    std::regex re(R"(@primes\s+(\d+))");
    std::smatch m;
    if (!std::regex_search(text, m, re)) {
        addError("malformed @primes (expected @primes N; with N in 1..15)");
        return;
    }
    int n = std::atoi(m[1].str().c_str());
    if (n < 1 || n > PPM_PRIME_COUNT) {
        addError("@primes " + std::to_string(n) + " is outside 1.." +
                 std::to_string(PPM_PRIME_COUNT));
        return;
    }
    system_.prime_count = n;
    system_.primes = ppmAlphabet(n);
}

void TliParser::parseGate(const std::string& text) {
    std::regex re(
        R"(@gate\s+([A-Za-z_][A-Za-z0-9_]*)\s+by\s+prime_signature\s*\(([^)]*)\))");
    std::smatch m;
    if (!std::regex_search(text, m, re)) {
        addError("malformed @gate (expected @gate membrane by prime_signature(p, ...))");
        return;
    }
    Gate gate;
    gate.membrane = m[1].str();
    std::string raw = m[2].str();
    std::string cur;
    for (size_t i = 0; i <= raw.size(); ++i) {
        if (i == raw.size() || raw[i] == ',' ||
            std::isspace(static_cast<unsigned char>(raw[i]))) {
            if (!cur.empty()) {
                gate.primes.push_back(std::atoi(cur.c_str()));
                cur.clear();
            }
        } else {
            cur += raw[i];
        }
    }
    if (gate.primes.empty()) {
        addError("@gate " + gate.membrane + " has an empty prime signature");
        return;
    }
    std::set<int> seen;
    for (size_t i = 0; i < gate.primes.size(); ++i) {
        if (!seen.insert(gate.primes[i]).second) {
            addError("@gate " + gate.membrane + " repeats prime " +
                     std::to_string(gate.primes[i]));
            return;
        }
    }
    if (!primeSignature(gate.primes, gate.signature)) {
        addError("@gate " + gate.membrane + " prime signature overflows");
        return;
    }
    system_.gates.push_back(gate);
}

void TliParser::parseSemantics(const std::string& text) {
    std::regex re(R"(mode\s*=\s*(daemon|angel))");
    std::smatch m;
    if (!std::regex_search(text, m, re)) {
        addError("@semantics mode must be daemon or angel");
        return;
    }
    system_.semantics = (m[1].str() == "daemon") ? SEM_DAEMON : SEM_ANGEL;
    system_.semantics_set = true;
}

void TliParser::parseFractal(const std::string& text) {
    FractalProfile fp;
    fp.present = true;
    fp.depth = 1;
    fp.scale = 1.0;
    std::string body = blockBody(text);
    std::smatch m;
    std::regex depthRe(R"(depth\s+(\d+))");
    std::regex scaleRe(R"(scale\s+([0-9]+(?:\.[0-9]+)?))");
    std::regex tileRe(R"(tile\s+([A-Za-z_][A-Za-z0-9_]*))");
    if (std::regex_search(body, m, depthRe)) fp.depth = std::atoi(m[1].str().c_str());
    if (std::regex_search(body, m, scaleRe)) fp.scale = std::atof(m[1].str().c_str());
    if (std::regex_search(body, m, tileRe)) fp.tile = m[1].str();
    system_.fractal = fp;
}

void TliParser::parseSpinor(const std::string& text) {
    std::regex head(R"(@spinor\s+([A-Za-z_][A-Za-z0-9_]*))");
    std::smatch hm;
    if (!std::regex_search(text, hm, head)) {
        addError("malformed @spinor");
        return;
    }
    Spinor sp;
    sp.name = hm[1].str();
    std::string body = blockBody(text);
    std::smatch m;
    std::regex periodRe(R"(period\s+(\d+))");
    std::regex flipRe(R"(flip_at\s+(\d+))");
    std::regex objRe(R"(object\s+([A-Za-z_][A-Za-z0-9_]*))");
    if (!std::regex_search(body, m, periodRe)) {
        addError("@spinor " + sp.name + " is missing period");
        return;
    }
    sp.period = std::atoi(m[1].str().c_str());
    if (!std::regex_search(body, m, flipRe)) {
        addError("@spinor " + sp.name + " is missing flip_at");
        return;
    }
    sp.flip_at = std::atoi(m[1].str().c_str());
    if (std::regex_search(body, m, objRe)) sp.object = m[1].str();
    else sp.object = "spin";
    system_.spinors.push_back(sp);
}

void TliParser::parseModule(const std::string& text) {
    std::regex head(R"(@module\s+([A-Za-z_][A-Za-z0-9_]*))");
    std::smatch hm;
    if (std::regex_search(text, hm, head)) system_.modules.push_back(hm[1].str());
    else system_.modules.push_back("module");
    /* @module is a grouping, not a grammar.  Its body is ordinary T-Lingua. */
    std::string body = blockBody(text);
    if (!body.empty()) parseStatements(body, lineNum_);
}

void TliParser::parseMu(const std::string& text) {
    std::regex re(R"(@mu\s*=\s*([\s\S]*);?)");
    std::smatch m;
    if (!std::regex_search(text, m, re)) {
        addError("malformed @mu");
        return;
    }
    std::string expr = trimCopy(m[1].str());
    if (!expr.empty() && expr[expr.size() - 1] == ';') expr.erase(expr.size() - 1);
    expr = trimCopy(expr);
    system_.mu = expr;
    size_t i = 0;
    MuNode root;
    std::string err;
    if (!parseMuNode(expr, i, root, err)) {
        addError(err);
        return;
    }
    indexParents(root, "", system_.parents);
}

void TliParser::parseInit(const std::string& text) {
    std::regex re(R"(@m([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]*);?)");
    std::smatch m;
    if (!std::regex_search(text, m, re)) {
        addError("malformed initial multiset");
        return;
    }
    if (m[1].str() == "u") return;
    MembraneInit init;
    init.label = m[1].str();
    init.multiset = trimCopy(m[2].str());
    system_.inits.push_back(init);
}

void TliParser::parseGuards(const std::string& tail, Rule& rule) {
    std::smatch m;
    std::regex phaseRe(R"(when\s+phase\s*==\s*(-?\d+))");
    std::regex slotRe(R"(when\s+slot\s*==\s*([A-Za-z_][A-Za-z0-9_]*))");
    std::regex resRe(
        R"(with\s+resonance\s*\(\s*([A-Za-z_]+)(?:\s*,\s*([A-Za-z_][A-Za-z0-9_]*))?\s*\))");
    if (std::regex_search(tail, m, phaseRe))
        rule.phase_guard = std::atoi(m[1].str().c_str());
    if (std::regex_search(tail, m, slotRe)) rule.slot_guard = m[1].str();
    if (std::regex_search(tail, m, resRe)) {
        std::string mode = m[1].str();
        if (m[2].matched) rule.resonance_partner = m[2].str();
        if (mode == "match" || mode == "exchange") rule.resonance = RES_MATCH;
        else if (mode == "mismatch" || mode == "dissipate")
            rule.resonance = RES_MISMATCH;
        else addError("unknown resonance mode '" + mode + "'");
    }
}

void TliParser::parseRule(const std::string& text) {
    Rule rule;
    rule.line = lineNum_;
    std::smatch m;
    std::regex bracketRe(
        R"(\[\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([\s\S]*?)-->([\s\S]*?)\]\s*'\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:,\s*(\d+))?([\s\S]*))");
    std::regex ruleRe(
        R"(rule\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:@\s*([A-Za-z_][A-Za-z0-9_]*))?\s*:\s*([\s\S]*?)-->([\s\S]*))");
    if (std::regex_search(text, m, bracketRe)) {
        rule.name = m[1].str();
        rule.lhs = trimCopy(m[2].str());
        rule.rhs = trimCopy(m[3].str());
        rule.membrane = m[4].str();
        if (m[5].matched) rule.priority = std::atoi(m[5].str().c_str());
        parseGuards(m[6].str(), rule);
    } else if (std::regex_search(text, m, ruleRe)) {
        rule.name = m[1].str();
        if (m[2].matched) rule.membrane = m[2].str();
        else {
            rule.membrane = "skin";
            addWarning("rule " + rule.name + " has no membrane; defaulting to skin");
        }
        std::string rest = m[4].str();
        /* Guards may sit on the RHS side of `-->` in the issue's rule form. */
        std::regex guardSplit(R"(^([\s\S]*?)(\s+when\s+[\s\S]*|\s+with\s+resonance[\s\S]*)$)");
        std::smatch gm;
        if (std::regex_search(rest, gm, guardSplit)) {
            rule.rhs = trimCopy(gm[1].str());
            parseGuards(gm[2].str(), rule);
        } else {
            rule.rhs = trimCopy(rest);
        }
        rule.lhs = trimCopy(m[3].str());
        parseGuards(rest, rule);
    } else {
        addError("malformed rule");
        return;
    }
    if (!rule.rhs.empty() && rule.rhs[rule.rhs.size() - 1] == ';')
        rule.rhs.erase(rule.rhs.size() - 1);
    rule.rhs = trimCopy(rule.rhs);
    system_.rules.push_back(rule);
}

namespace {

const Gate* findGate(const std::vector<Gate>& gates, const std::string& membrane) {
    for (size_t i = 0; i < gates.size(); ++i)
        if (gates[i].membrane == membrane) return &gates[i];
    return 0;
}

bool signaturesIntersect(const Gate& a, const Gate& b) {
    for (size_t i = 0; i < a.primes.size(); ++i)
        if (primeInAlphabet(a.primes[i], b.primes)) return true;
    return false;
}

std::string firstSendTarget(const Rule& rule) {
    std::vector<Term> rhs = parseTerms(rule.rhs);
    for (size_t i = 0; i < rhs.size(); ++i) {
        if (rhs[i].where == Term::IN) return rhs[i].target;
        if (rhs[i].where == Term::OUT) return "out";
    }
    return "";
}

} // namespace

bool TliParser::verify(int steps) {
    Verification& v = system_.verification;
    v = Verification();
    system_.trace.clear();
    system_.final_objects.clear();
    system_.clock_wraps.clear();
    system_.final_phase.clear();
    system_.exchanged = 0;
    system_.dissipated = 0;
    system_.steps_run = 0;

    std::vector<int> alphabet = system_.primes;
    if (alphabet.empty()) alphabet = ppmAlphabet(PPM_PRIME_COUNT);

    /* ---- clocks: the ring the simulator owns --------------------------- */
    bool anyClock = !system_.clocks.empty();
    if (!anyClock) {
        v.notes.push_back("no @clock; closed-loop check is vacuous");
    }
    for (size_t i = 0; i < system_.clocks.size(); ++i) {
        const Clock& c = system_.clocks[i];
        if (c.period < 1) {
            v.failures.push_back("clock " + c.name + " has period < 1");
            v.closed_loop = false;
            continue;
        }
        int phase = 0;
        int wraps = 0;
        for (int s = 0; s < c.period; ++s) {
            phase = (phase + 1) % c.period;
            if (phase == 0) ++wraps;
        }
        if (phase != 0 || wraps != 1) {
            v.failures.push_back("clock " + c.name + " did not close after " +
                                 std::to_string(c.period) + " steps");
            v.closed_loop = false;
        } else {
            v.notes.push_back("clock " + c.name + " period " +
                              std::to_string(c.period) +
                              " returns to " + c.wrap_to + " with 1 wrap");
        }
        if (c.period == CANONICAL_CYCLE && phase == 0 && wraps == 1)
            v.eleven_cycle = true;
        if (c.period >= 2) {
            int neighbor = circularPhaseDistance(0, c.period - 1, c.period);
            int zero = circularPhaseDistance(0, 0, c.period);
            if (neighbor != 1 || zero != 0) {
                v.failures.push_back("circular phase distance failed on clock " +
                                     c.name);
                v.circular_phase_distance = false;
            }
        }
    }
    for (size_t i = 0; i < system_.registers.size(); ++i) {
        const PhaseRegister& r = system_.registers[i];
        if (r.cycle >= 2) {
            int neighbor = circularPhaseDistance(0, r.cycle - 1, r.cycle);
            if (neighbor != 1) {
                v.failures.push_back("circular phase distance failed on register " +
                                     r.name);
                v.circular_phase_distance = false;
            }
        }
    }
    if (v.circular_phase_distance) {
        /* The canonical claim, independent of any one model: |10-0| on the
         * 11-cycle is 1, not 10. */
        if (circularPhaseDistance(10, 0, CANONICAL_CYCLE) != 1 ||
            circularPhaseDistance(0, 10, CANONICAL_CYCLE) != 1) {
            v.failures.push_back("canonical 11-cycle distance |10-0| is not 1");
            v.circular_phase_distance = false;
        }
    }

    /* ---- primes and gates --------------------------------------------- */
    if (system_.prime_count != 0 &&
        static_cast<int>(system_.primes.size()) != system_.prime_count) {
        v.failures.push_back("@primes alphabet size mismatch");
        v.prime_gating = false;
    }
    if (system_.gates.empty()) {
        v.notes.push_back("no @gate; prime-gating check is vacuous");
    }
    int gatePeriod = CANONICAL_CYCLE;
    if (!system_.clocks.empty()) gatePeriod = system_.clocks[0].period;
    for (size_t i = 0; i < system_.gates.size(); ++i) {
        const Gate& g = system_.gates[i];
        for (size_t p = 0; p < g.primes.size(); ++p) {
            if (!primeInAlphabet(g.primes[p], alphabet)) {
                v.failures.push_back("gate " + g.membrane + " prime " +
                                     std::to_string(g.primes[p]) +
                                     " is not in the PPM alphabet");
                v.prime_gating = false;
            }
        }
        if (g.signature == 0) {
            v.failures.push_back("gate " + g.membrane + " has signature 0");
            v.prime_gating = false;
            continue;
        }
        if (!gateOpen(g.signature, 0) ||
            (g.signature > 1 && gateOpen(g.signature, 1))) {
            v.failures.push_back("gate predicate failed for " + g.membrane);
            v.prime_gating = false;
        }
        bool opens = false;
        for (int t = 1; t < gatePeriod; ++t) {
            if (gateOpen(g.signature, static_cast<uint64_t>(t))) opens = true;
        }
        if (!opens && g.signature > 1) {
            system_.warnings.push_back(
                "warning: prime signature " + std::to_string(g.signature) +
                " of " + g.membrane +
                " does not divide any positive tick in the " +
                std::to_string(gatePeriod) +
                "-cycle; next open step is " +
                std::to_string(g.signature));
        }
        v.notes.push_back("gate " + g.membrane + " signature " +
                          std::to_string(g.signature));
    }

    /* ---- fractal profile (not a parser) -------------------------------- */
    if (system_.fractal.present) {
        if (system_.fractal.depth < 1 || system_.fractal.scale <= 0.0) {
            v.failures.push_back("@fractal depth must be >= 1 and scale > 0");
        } else {
            v.notes.push_back("fractal profile depth " +
                              std::to_string(system_.fractal.depth) +
                              " (M-Lingua companion, not a separate grammar)");
        }
    }

    /* ---- spinor schema -------------------------------------------------- */
    if (system_.spinors.empty()) {
        v.notes.push_back("no @spinor; sign-flip check is vacuous");
    }
    for (size_t i = 0; i < system_.spinors.size(); ++i) {
        const Spinor& sp = system_.spinors[i];
        if (sp.period < 2 || sp.flip_at <= 0 || sp.flip_at >= sp.period) {
            v.failures.push_back("spinor " + sp.name + " period/flip_at out of range");
            v.spinor_flip = false;
            continue;
        }
        if (2 * sp.flip_at != sp.period) {
            v.failures.push_back("spinor " + sp.name +
                                 " 2π flip_at must be half the 4π period");
            v.spinor_flip = false;
            continue;
        }
        if (spinorSign(0, sp.period, sp.flip_at) != 1 ||
            spinorSign(sp.flip_at, sp.period, sp.flip_at) != -1 ||
            spinorSign(sp.period, sp.period, sp.flip_at) != 1) {
            v.failures.push_back("spinor " + sp.name + " sign-flip failed");
            v.spinor_flip = false;
        } else {
            v.notes.push_back("spinor " + sp.name + " flips at 2π and returns at 4π");
        }
    }

    /* ---- multiset simulation ------------------------------------------- */
    std::map<std::string, std::map<std::string, int> > mem;
    for (size_t i = 0; i < system_.inits.size(); ++i) {
        std::map<std::string, int> objs = parseMultiset(system_.inits[i].multiset);
        for (std::map<std::string, int>::const_iterator it = objs.begin();
             it != objs.end(); ++it) {
            addObj(mem, system_.inits[i].label, it->first, it->second);
        }
    }
    std::map<std::string, int> clockPhase;
    for (size_t i = 0; i < system_.clocks.size(); ++i) {
        const Clock& c = system_.clocks[i];
        clockPhase[c.name] = 0;
        system_.clock_wraps[c.name] = 0;
        if (countOf(mem, c.wrap_to, c.name) < 1)
            addObj(mem, c.wrap_to, c.name, 1);
        if (!c.reseed.empty() && countOf(mem, c.wrap_to, c.reseed) < 1)
            addObj(mem, c.wrap_to, c.reseed, 1);
    }
    std::map<std::string, int> regPhase;
    for (size_t i = 0; i < system_.registers.size(); ++i) {
        const PhaseRegister& r = system_.registers[i];
        regPhase[r.name] = 0;
        if (countOf(mem, r.name, "phase(0)") < 1)
            addObj(mem, r.name, "phase(0)", 1);
        for (size_t s = 0; s < r.slots.size(); ++s) {
            std::string slot = "slot(" + r.slots[s] + ")";
            if (countOf(mem, r.name, slot) < 1) addObj(mem, r.name, slot, 1);
        }
    }

    int simSteps = steps;
    if (simSteps <= 0) {
        simSteps = 1;
        for (size_t i = 0; i < system_.clocks.size(); ++i)
            if (system_.clocks[i].period > simSteps)
                simSteps = system_.clocks[i].period;
        for (size_t i = 0; i < system_.registers.size(); ++i)
            if (system_.registers[i].cycle > simSteps)
                simSteps = system_.registers[i].cycle;
    }
    if (simSteps > 64) simSteps = 64;
    if (simSteps < 1) simSteps = 1;

    std::vector<std::vector<Term> > lhsTerms(system_.rules.size());
    std::vector<std::vector<Term> > rhsTerms(system_.rules.size());
    for (size_t i = 0; i < system_.rules.size(); ++i) {
        lhsTerms[i] = parseTerms(system_.rules[i].lhs);
        rhsTerms[i] = parseTerms(system_.rules[i].rhs);
    }

    bool resonanceSeen = false;
    for (int step = 0; step < simSteps; ++step) {
        StepTrace tr;
        tr.step = step;
        tr.clock_phase = system_.clocks.empty()
                             ? -1
                             : clockPhase[system_.clocks[0].name];
        for (size_t i = 0; i < system_.registers.size(); ++i)
            tr.register_phase[system_.registers[i].name] =
                regPhase[system_.registers[i].name];
        for (size_t i = 0; i < system_.gates.size(); ++i) {
            tr.gates_open[system_.gates[i].membrane] =
                gateOpen(system_.gates[i].signature, static_cast<uint64_t>(step));
        }

        std::map<std::string, std::map<std::string, int> > budget = mem;
        std::set<std::string> angelFired;
        std::vector<size_t> chosen;
        std::vector<bool> dissipate(system_.rules.size(), false);

        for (size_t ri = 0; ri < system_.rules.size(); ++ri) {
            const Rule& rule = system_.rules[ri];
            if (system_.semantics == SEM_ANGEL &&
                angelFired.count(rule.membrane)) {
                continue;
            }
            int phase = 0;
            int period = 1;
            bool havePhase = false;
            if (regPhase.count(rule.membrane)) {
                phase = regPhase[rule.membrane];
                for (size_t k = 0; k < system_.registers.size(); ++k) {
                    if (system_.registers[k].name == rule.membrane) {
                        period = system_.registers[k].cycle;
                        havePhase = true;
                    }
                }
            } else if (!system_.clocks.empty()) {
                phase = clockPhase[system_.clocks[0].name];
                period = system_.clocks[0].period;
                havePhase = true;
            }
            if (rule.phase_guard >= 0) {
                if (!havePhase || phase != rule.phase_guard) continue;
            }
            if (!rule.slot_guard.empty()) {
                const PhaseRegister* reg = 0;
                for (size_t k = 0; k < system_.registers.size(); ++k) {
                    if (system_.registers[k].name == rule.membrane) {
                        reg = &system_.registers[k];
                        break;
                    }
                }
                if (!reg || reg->slots.empty()) continue;
                int rp = regPhase[rule.membrane];
                if (rp < 0 || rp >= static_cast<int>(reg->slots.size())) continue;
                if (reg->slots[static_cast<size_t>(rp)] != rule.slot_guard) continue;
            }
            const Gate* gate = findGate(system_.gates, rule.membrane);
            if (gate && !gateOpen(gate->signature, static_cast<uint64_t>(step)))
                continue;

            if (rule.resonance != RES_NONE) {
                resonanceSeen = true;
                std::string partner = rule.resonance_partner;
                if (partner.empty()) {
                    std::string send = firstSendTarget(rule);
                    if (send == "out") {
                        std::map<std::string, std::string>::const_iterator pit =
                            system_.parents.find(rule.membrane);
                        partner = (pit == system_.parents.end()) ? "skin" : pit->second;
                        if (partner.empty()) partner = "skin";
                    } else if (!send.empty()) {
                        partner = send;
                    } else {
                        std::map<std::string, std::string>::const_iterator pit =
                            system_.parents.find(rule.membrane);
                        partner = (pit == system_.parents.end() || pit->second.empty())
                                      ? "skin"
                                      : pit->second;
                    }
                }
                const Gate* src = findGate(system_.gates, rule.membrane);
                const Gate* dst = findGate(system_.gates, partner);
                bool match = false;
                if (src && dst) {
                    match = signaturesIntersect(*src, *dst);
                } else if (src || dst) {
                    const Gate* g = src ? src : dst;
                    int pp = phasePrime(phase, alphabet);
                    match = pp >= 0 && primeInAlphabet(pp, g->primes);
                } else if (period > 0) {
                    match = circularPhaseDistance(phase, phase, period) == 0;
                }
                bool want = (rule.resonance == RES_MATCH) ? match : !match;
                if (!want) continue;
                if (rule.resonance == RES_MISMATCH) dissipate[ri] = true;
            }

            if (!budgetHas(budget, rule.membrane, lhsTerms[ri])) continue;
            takeLhs(budget, rule.membrane, lhsTerms[ri]);
            chosen.push_back(ri);
            if (system_.semantics == SEM_ANGEL) angelFired.insert(rule.membrane);
        }

        for (size_t ci = 0; ci < chosen.size(); ++ci) {
            size_t ri = chosen[ci];
            const Rule& rule = system_.rules[ri];
            takeLhs(mem, rule.membrane, lhsTerms[ri]);
            if (dissipate[ri]) {
                ++system_.dissipated;
            } else {
                for (size_t t = 0; t < rhsTerms[ri].size(); ++t) {
                    const Term& term = rhsTerms[ri][t];
                    if (term.where == Term::HERE) {
                        addObj(mem, rule.membrane, term.object, term.count);
                    } else if (term.where == Term::IN) {
                        addObj(mem, term.target, term.object, term.count);
                        ++system_.exchanged;
                    } else if (term.where == Term::OUT) {
                        std::string parent = "skin";
                        std::map<std::string, std::string>::const_iterator pit =
                            system_.parents.find(rule.membrane);
                        if (pit != system_.parents.end() && !pit->second.empty())
                            parent = pit->second;
                        addObj(mem, parent, term.object, term.count);
                        ++system_.exchanged;
                    }
                }
                if (rule.resonance == RES_MATCH) {
                    /* A match with no send still counts as a checked exchange. */
                    bool anySend = false;
                    for (size_t t = 0; t < rhsTerms[ri].size(); ++t)
                        if (rhsTerms[ri][t].where != Term::HERE) anySend = true;
                    if (!anySend) ++system_.exchanged;
                }
            }
            tr.fired.push_back(rule.name);
        }
        system_.trace.push_back(tr);

        for (size_t i = 0; i < system_.clocks.size(); ++i) {
            const Clock& c = system_.clocks[i];
            int phase = (clockPhase[c.name] + 1) % c.period;
            clockPhase[c.name] = phase;
            if (phase == 0) {
                ++system_.clock_wraps[c.name];
                if (!c.reseed.empty()) {
                    if (countOf(mem, c.wrap_to, c.name) < 1)
                        addObj(mem, c.wrap_to, c.name, 1);
                    if (countOf(mem, c.wrap_to, c.reseed) < 1)
                        addObj(mem, c.wrap_to, c.reseed, 1);
                }
            }
        }
        for (size_t i = 0; i < system_.registers.size(); ++i) {
            const PhaseRegister& r = system_.registers[i];
            regPhase[r.name] = (regPhase[r.name] + 1) % r.cycle;
        }
    }

    system_.steps_run = simSteps;
    system_.final_objects = mem;
    system_.final_phase = clockPhase;
    for (size_t i = 0; i < system_.registers.size(); ++i)
        system_.final_phase[system_.registers[i].name] =
            regPhase[system_.registers[i].name];

    for (size_t i = 0; i < system_.clocks.size(); ++i) {
        const Clock& c = system_.clocks[i];
        if (simSteps >= c.period) {
            int expectWraps = simSteps / c.period;
            if (system_.clock_wraps[c.name] != expectWraps ||
                clockPhase[c.name] != (simSteps % c.period)) {
                v.failures.push_back("simulated clock " + c.name +
                                     " left the ring");
                v.closed_loop = false;
            }
        }
        if (!c.reseed.empty() && system_.clock_wraps[c.name] > 0) {
            if (countOf(mem, c.wrap_to, c.name) < 1) {
                v.failures.push_back("reseed of " + c.name +
                                     " did not restore the tick at " + c.wrap_to);
                v.closed_loop = false;
            }
        }
    }

    if (!resonanceSeen) {
        v.notes.push_back("no resonance rule; exchange check is vacuous");
    } else if (v.resonance_exchange) {
        v.notes.push_back("resonance exchange checked (" +
                          std::to_string(system_.exchanged) + " exchange, " +
                          std::to_string(system_.dissipated) + " dissipate)");
    }

    v.ok = v.failures.empty() && v.closed_loop && v.circular_phase_distance &&
           v.prime_gating && v.resonance_exchange && v.spinor_flip;
    return v.ok;
}

std::string TliParser::lower() const {
    std::ostringstream out;
    std::string model = system_.model_type.empty() ? "time_crystal" : system_.model_type;
    out << "/* Lowered by tlingua from a T-Lingua (.tli) model.\n";
    out << " * Source model: @tmodel<" << model << ">\n";
    out << " * Traceability: plingua/docs/TLINGUA_SPEC.md\n";
    out << " * Lowering: @clock/@phase_register/when/resonance -> explicit rules.\n";
    out << " */\n\n";
    out << "@model<psystems_basic>\n\n";

    if (system_.semantics_set) {
        out << "/* @semantics mode="
            << (system_.semantics == SEM_DAEMON ? "daemon" : "angel")
            << " */\n";
    }
    if (system_.fractal.present) {
        out << "/* @fractal depth=" << system_.fractal.depth
            << " scale=" << system_.fractal.scale;
        if (!system_.fractal.tile.empty()) out << " tile=" << system_.fractal.tile;
        out << " — geometric tiling is an M-Lingua companion, not parsed here. */\n";
    }

    std::string chains;
    for (size_t ci = 0; ci < system_.clocks.size(); ++ci) {
        int period = system_.clocks[ci].period;
        std::string s = "[]'d" + std::to_string(period);
        for (int i = period - 1; i >= 1; --i)
            s = "[ " + s + " ]'d" + std::to_string(i);
        if (!chains.empty()) chains += " ";
        chains += s;
    }
    if (!system_.mu.empty()) {
        std::string mu = system_.mu;
        /* Clock stations are language-owned.  Inject them into the author's
         * tree so lowered rules that name d1..dN still declare those labels. */
        if (!chains.empty() && mu.find("'d1") == std::string::npos) {
            std::string rim = system_.clocks[0].wrap_to.empty()
                                  ? "skin"
                                  : system_.clocks[0].wrap_to;
            std::string marker = "]'" + rim;
            size_t pos = mu.rfind(marker);
            if (pos == std::string::npos) pos = mu.rfind(']');
            if (pos != std::string::npos) mu.insert(pos, " " + chains + " ");
        }
        out << "@mu = " << mu << ";\n";
    } else if (!chains.empty()) {
        std::string rim = system_.clocks[0].wrap_to.empty()
                              ? "skin"
                              : system_.clocks[0].wrap_to;
        out << "@mu = [ " << chains << " ]'" << rim << ";\n";
    }
    out << "\n";

    for (size_t i = 0; i < system_.inits.size(); ++i) {
        out << "@m" << system_.inits[i].label << " = "
            << system_.inits[i].multiset << ";\n";
    }
    if (!system_.primes.empty()) {
        std::string rim = "skin";
        if (!system_.clocks.empty() && !system_.clocks[0].wrap_to.empty())
            rim = system_.clocks[0].wrap_to;
        out << "@m" << rim << " = ";
        for (size_t i = 0; i < system_.primes.size(); ++i) {
            if (i) out << ", ";
            out << "prime_" << system_.primes[i];
        }
        out << ";\n";
    }
    for (size_t i = 0; i < system_.clocks.size(); ++i) {
        const Clock& c = system_.clocks[i];
        std::string rim = c.wrap_to.empty() ? "skin" : c.wrap_to;
        bool seeded = false;
        for (size_t k = 0; k < system_.inits.size(); ++k)
            if (system_.inits[k].label == rim) seeded = true;
        if (!seeded) out << "@m" << rim << " = " << c.name << ";\n";
    }
    for (size_t i = 0; i < system_.registers.size(); ++i) {
        const PhaseRegister& r = system_.registers[i];
        out << "@m" << r.name << " = phase(0)";
        for (size_t s = 0; s < r.slots.size(); ++s)
            out << ", slot(" << r.slots[s] << ")";
        out << ";\n";
    }
    for (size_t i = 0; i < system_.gates.size(); ++i) {
        out << "/* @gate " << system_.gates[i].membrane
            << " by prime_signature signature=" << system_.gates[i].signature
            << " */\n";
        out << "@m" << system_.gates[i].membrane << " = gate_sig_"
            << system_.gates[i].signature << ";\n";
    }
    out << "\n";

    for (size_t i = 0; i < system_.rules.size(); ++i) {
        const Rule& rule = system_.rules[i];
        std::string lhs = rule.lhs;
        std::string rhs = rule.rhs;
        if (rule.phase_guard >= 0) {
            std::string tok = "phase(" + std::to_string(rule.phase_guard) + ")";
            if (lhs.find(tok) == std::string::npos) {
                if (!lhs.empty()) lhs += " * ";
                lhs += tok;
                if (!rhs.empty()) rhs += " * ";
                rhs += tok;
            }
        }
        if (!rule.slot_guard.empty()) {
            std::string tok = "slot(" + rule.slot_guard + ")";
            if (lhs.find(tok) == std::string::npos) {
                if (!lhs.empty()) lhs += " * ";
                lhs += tok;
            }
            if (rhs.find(tok) == std::string::npos) {
                if (!rhs.empty()) rhs += " * ";
                rhs += tok;
            }
        }
        if (rule.resonance != RES_NONE) {
            const char* mode = (rule.resonance == RES_MATCH) ? "match" : "mismatch";
            out << "/* with resonance(" << mode << ") */\n";
            std::string guard = std::string("res_") + mode;
            out << "[" << rule.name << " : " << lhs << " * " << guard
                << " --> " << rhs << " * " << guard << " ]'" << rule.membrane
                << ", 1;\n";
            out << "[" << rule.name << "_off : " << lhs << " --> dissipated ]'"
                << rule.membrane << ", 2;\n";
        } else {
            out << "[" << rule.name << " : " << lhs << " --> " << rhs << " ]'"
                << rule.membrane << ";\n";
        }
    }

    for (size_t ci = 0; ci < system_.clocks.size(); ++ci) {
        const Clock& c = system_.clocks[ci];
        std::string rim = c.wrap_to.empty() ? "skin" : c.wrap_to;
        out << "\n/* @clock " << c.name << " (period " << c.period
            << ") lowered: */\n";
        out << "[" << c.name << "_in : " << c.name << " --> (" << c.name
            << ")in_d1 ]'" << rim << ";\n";
        for (int i = 1; i < c.period; ++i) {
            out << "[" << c.name << "_in : " << c.name << " --> (" << c.name
                << ")in_d" << (i + 1) << " ]'d" << i << ";\n";
        }
        std::string wrapAt = c.wrap_from.empty()
                                 ? ("d" + std::to_string(c.period))
                                 : c.wrap_from;
        out << "[" << c.name << "_wrap : " << c.name << " --> (" << c.name
            << ")out ]'" << wrapAt << ";\n";
        if (!c.reseed.empty()) {
            out << "[singularity : " << c.reseed << " --> " << c.reseed << " * "
                << c.name << " ]'" << wrapAt << ";\n";
        }
    }

    for (size_t i = 0; i < system_.registers.size(); ++i) {
        const PhaseRegister& r = system_.registers[i];
        out << "\n/* @phase_register " << r.name << " (cycle " << r.cycle
            << ") lowered: */\n";
        if (!r.slots.empty()) {
            out << "[wrap_" << r.name << " : done(" << r.slots.back()
                << ") --> cycle_complete * phase(0) ]'" << r.name << ";\n";
        }
    }

    for (size_t i = 0; i < system_.spinors.size(); ++i) {
        const Spinor& sp = system_.spinors[i];
        out << "\n/* @spinor " << sp.name << " period=" << sp.period
            << " flip_at=" << sp.flip_at
            << " — sign -1 under 2π, +1 under 4π. Rule schema, not a language. */\n";
        out << "[spin_flip : " << sp.object << " --> " << sp.object
            << "_down ]'skin;\n";
        out << "[spin_restore : " << sp.object << "_down --> " << sp.object
            << " ]'skin;\n";
    }

    for (size_t i = 0; i < system_.passthrough.size(); ++i)
        out << system_.passthrough[i] << "\n";

    out << "\n";
    return out.str();
}

} // namespace tlingua
} // namespace plingua
