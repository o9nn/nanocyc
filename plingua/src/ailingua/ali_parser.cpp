/*
 * ali_parser.cpp
 *
 * Parser for Ai-Lingua (.ali) files.
 * See plingua/docs/AILINGUA_SPEC.md.
 *
 * Copyright (C) 2026  P-Lingua/Ai-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <ailingua/ali_parser.hpp>
#include <dialect_import.hpp>

#include <algorithm>
#include <cctype>
#include <fstream>
#include <regex>
#include <sstream>

namespace plingua {
namespace ailingua {

namespace {

bool startsWith(const std::string& s, const std::string& pfx) {
    return s.size() >= pfx.size() && s.compare(0, pfx.size(), pfx) == 0;
}

bool isIdentChar(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

std::string readIdentAt(const std::string& s, size_t& i) {
    std::string id;
    while (i < s.size() && isIdentChar(s[i])) {
        id += s[i++];
    }
    return id;
}

double clamp01(double v) {
    if (v < 0.0) return 0.0;
    if (v > 1.0) return 1.0;
    return v;
}

} // namespace

std::string AliParser::trim(const std::string& s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    size_t b = s.find_last_not_of(" \t\r\n");
    return (a == std::string::npos) ? "" : s.substr(a, b - a + 1);
}

std::string AliParser::stripSemi(const std::string& s) {
    std::string t = trim(s);
    if (!t.empty() && t[t.size() - 1] == ';') t.erase(t.size() - 1);
    return trim(t);
}

std::string AliParser::stripComments(const std::string& src) {
    std::string out;
    out.reserve(src.size());
    bool inLine = false, inBlock = false;
    for (size_t i = 0; i < src.size(); ++i) {
        if (inLine) {
            if (src[i] == '\n') { inLine = false; out += '\n'; }
            continue;
        }
        if (inBlock) {
            if (src[i] == '*' && i + 1 < src.size() && src[i + 1] == '/') {
                inBlock = false; ++i;
            } else if (src[i] == '\n') {
                out += '\n';
            }
            continue;
        }
        if (src[i] == '/' && i + 1 < src.size()) {
            if (src[i + 1] == '/') { inLine = true; continue; }
            if (src[i + 1] == '*') { inBlock = true; ++i; continue; }
        }
        /* '--' line comments, as in the issue sketch. */
        if (src[i] == '-' && i + 1 < src.size() && src[i + 1] == '-' &&
            (i == 0 || src[i - 1] != '-')) {
            inLine = true;
            continue;
        }
        out += src[i];
    }
    return out;
}

bool AliParser::parseKeyValue(const std::string& line, std::string& key, std::string& value) {
    size_t eq = line.find('=');
    if (eq == std::string::npos) return false;
    key = trim(line.substr(0, eq));
    value = stripSemi(line.substr(eq + 1));
    return !key.empty() && !value.empty();
}

double AliParser::parseDouble(const std::string& s, double defval) {
    try { return std::stod(s); } catch (...) { return defval; }
}

int AliParser::parseInt(const std::string& s, int defval) {
    try { return std::stoi(s); } catch (...) { return defval; }
}

std::string AliParser::joinBlock(const std::vector<std::string>& block) {
    std::string s;
    for (size_t i = 0; i < block.size(); ++i) {
        if (i) s += "\n";
        s += block[i];
    }
    return s;
}

std::vector<std::string> AliParser::collectBlock(const std::vector<std::string>& lines, size_t& i) {
    std::vector<std::string> block;
    const std::string& ln0 = lines[i];
    size_t open_pos = ln0.find('{');
    size_t close_pos = ln0.rfind('}');
    if (open_pos != std::string::npos && close_pos != std::string::npos && close_pos > open_pos) {
        std::string inner = ln0.substr(open_pos + 1, close_pos - open_pos - 1);
        if (inner.find('{') == std::string::npos) {
            std::istringstream iss(inner);
            std::string stmt;
            while (std::getline(iss, stmt, ';')) {
                std::string t = trim(stmt);
                if (!t.empty()) block.push_back(t);
            }
            return block;
        }
    }
    int depth = 1;
    ++i;
    while (i < lines.size() && depth > 0) {
        const std::string& ln = lines[i];
        for (size_t c = 0; c < ln.size(); ++c) {
            if (ln[c] == '{') ++depth;
            else if (ln[c] == '}') --depth;
        }
        if (depth > 0) block.push_back(ln);
        ++i;
    }
    if (i > 0) --i;
    return block;
}

void AliParser::addError(const std::string& msg) {
    system_.errors.push_back(filename_ + ":" + std::to_string(lineNum_) + ": error: " + msg);
}

void AliParser::addWarning(const std::string& msg) {
    system_.warnings.push_back(filename_ + ":" + std::to_string(lineNum_) + ": warning: " + msg);
}

AliParser::AliParser() : lineNum_(0) {}

bool AliParser::parseFile(const std::string& filename) {
    std::ifstream f(filename.c_str());
    if (!f.is_open()) {
        system_.errors.push_back("Cannot open file: " + filename);
        return false;
    }
    std::ostringstream ss;
    ss << f.rdbuf();
    return parseString(ss.str(), filename);
}

bool AliParser::handleImport(const std::string& line) {
    plingua::import_util::ImportPrep prep = plingua::import_util::prepareImport(
        filename_, line, importStack_, system_.imports);
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
    mod.inlined = (prep.dialect == "ali");
    if (mod.inlined) parseBody(prep.body, prep.resolved);
    system_.imports.push_back(mod);
    return true;
}

bool AliParser::parseString(const std::string& source, const std::string& filename) {
    system_ = AiLinguaSystem();
    importStack_.clear();
    filename_ = filename;
    lineNum_ = 0;
    bool ok = parseBody(source, filename);
    validate();
    return ok && !system_.hasErrors();
}

bool AliParser::parseBody(const std::string& source, const std::string& filename) {
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

    std::string clean = stripComments(source);
    std::vector<std::string> lines;
    {
        std::istringstream iss(clean);
        std::string ln;
        while (std::getline(iss, ln)) lines.push_back(ln);
    }

    for (size_t i = 0; i < lines.size(); ++i) {
        lineNum_ = static_cast<int>(i + 1);
        std::string ln = trim(lines[i]);
        if (ln.empty()) continue;
        if (handleImport(ln)) continue;

        if (ln.find("@aimodel") != std::string::npos) {
            parseModelDecl(ln);
            continue;
        }
        if (ln.find("@ennead") != std::string::npos && ln.find('{') != std::string::npos) {
            parseEnneadBlock(lines, i);
            continue;
        }
        if (startsWith(ln, "@clock")) {
            parseClock(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "@phase_register")) {
            parsePhaseRegister(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "@attention")) {
            parseAttention(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "@truth")) {
            parseTruth(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "@learn")) {
            parseLearn(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "@atomspace")) {
            parseAtomspace(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "@mu")) {
            parseMu(ln);
            continue;
        }
        if (startsWith(ln, "@object")) {
            parseObject(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "@rule")) {
            parseRule(ln, lines, i);
            continue;
        }
        if (startsWith(ln, "def ")) {
            parseDef(ln, lines, i);
            continue;
        }
        if (ln.find("@observe") != std::string::npos && ln.find('{') != std::string::npos) {
            parseObserve(lines, i);
            continue;
        }
        if (ln.find("@constraints") != std::string::npos && ln.find('{') != std::string::npos) {
            parseConstraints(lines, i);
            continue;
        }
        if (!ln.empty() && ln[0] == '@') {
            addWarning("unrecognised directive: " + ln);
        }
    }

    importStack_.erase(key);
    filename_ = prevFile;
    lineNum_ = prevLine;
    return !system_.hasErrors();
}

bool AliParser::parseModelDecl(const std::string& line) {
    std::regex re("@aimodel\\s*<\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*>");
    std::smatch m;
    if (std::regex_search(line, m, re)) {
        if (!system_.model_type.empty() && system_.model_type != m[1].str()) {
            addWarning("@aimodel overrides previous '" + system_.model_type + "'");
        }
        system_.model_type = m[1].str();
        return true;
    }
    addError("invalid @aimodel declaration: " + line);
    return false;
}

bool AliParser::parseEnneadBlock(const std::vector<std::string>& lines, size_t& i) {
    std::string body = joinBlock(collectBlock(lines, i));
    struct Field { const char* name; double* slot; };
    Field fields[] = {
        { "identity_continuity", &system_.ennead.identity_continuity },
        { "skill_readiness", &system_.ennead.skill_readiness },
        { "motivational_valence", &system_.ennead.motivational_valence },
        { "constraint_clarity", &system_.ennead.constraint_clarity },
        { "affordance_density", &system_.ennead.affordance_density },
        { "feedback_latency", &system_.ennead.feedback_latency },
        { "coupling_strength", &system_.ennead.coupling_strength },
        { "reciprocal_shaping", &system_.ennead.reciprocal_shaping },
        { "adaptive_fit", &system_.ennead.adaptive_fit }
    };
    for (size_t f = 0; f < sizeof(fields) / sizeof(fields[0]); ++f) {
        std::regex re(std::string(fields[f].name) + "\\s*=\\s*([+-]?[0-9]*\\.?[0-9]+)");
        std::smatch m;
        if (std::regex_search(body, m, re)) {
            *fields[f].slot = clamp01(parseDouble(m[1].str(), 0.5));
        }
    }
    return true;
}

bool AliParser::parseClock(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::regex re("@clock\\s+([A-Za-z_][A-Za-z0-9_]*)");
    std::smatch m;
    if (!std::regex_search(header, m, re)) {
        addError("invalid @clock (expected @clock name { ... })");
        return false;
    }
    std::string body = header;
    if (header.find('{') != std::string::npos) body += "\n" + joinBlock(collectBlock(lines, i));
    system_.clock.name = m[1].str();
    system_.clock.present = true;
    std::smatch pm;
    if (std::regex_search(body, pm, std::regex("period\\s+([0-9]+)"))) {
        system_.clock.period = parseInt(pm[1].str(), 1);
    } else {
        addError("@clock " + system_.clock.name + " missing period");
    }
    if (system_.clock.period < 1) addError("@clock period must be >= 1");
    std::smatch wm;
    if (std::regex_search(body, wm, std::regex("wrap\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*->\\s*([A-Za-z_][A-Za-z0-9_]*)"))) {
        system_.clock.wrap_from = wm[1].str();
        system_.clock.wrap_to = wm[2].str();
    }
    std::smatch rm;
    if (std::regex_search(body, rm, std::regex("reseed\\s+([A-Za-z_][A-Za-z0-9_]*)"))) {
        system_.clock.reseed = rm[1].str();
    }
    return true;
}

bool AliParser::parsePhaseRegister(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::regex re("@phase_register\\s+([A-Za-z_][A-Za-z0-9_]*)");
    std::smatch m;
    if (!std::regex_search(header, m, re)) {
        addError("invalid @phase_register");
        return false;
    }
    std::string body = header;
    if (header.find('{') != std::string::npos) body += "\n" + joinBlock(collectBlock(lines, i));
    system_.phase_register.name = m[1].str();
    system_.phase_register.present = true;
    std::smatch cm;
    if (std::regex_search(body, cm, std::regex("cycle\\s+([0-9]+)"))) {
        system_.phase_register.cycle = parseInt(cm[1].str(), 0);
    }
    std::smatch sm;
    if (std::regex_search(body, sm, std::regex("slots\\s*\\[([^\\]]*)\\]"))) {
        std::string inner = sm[1].str();
        for (size_t k = 0; k < inner.size();) {
            while (k < inner.size() && !isIdentChar(inner[k])) ++k;
            if (k >= inner.size()) break;
            system_.phase_register.slots.push_back(readIdentAt(inner, k));
        }
    }
    if (system_.phase_register.slots.empty()) addError("@phase_register missing slots");
    return true;
}

bool AliParser::parseAttention(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::string body = header;
    if (header.find('{') != std::string::npos) body += "\n" + joinBlock(collectBlock(lines, i));
    system_.attention.present = true;
    std::smatch m;
    if (std::regex_search(body, m, std::regex("wage\\s*=?\\s*([0-9]+)"))) {
        system_.attention.wage = parseInt(m[1].str(), 10);
    }
    if (std::regex_search(body, m, std::regex("rent\\s*=?\\s*([0-9]*\\.?[0-9]+)"))) {
        double rent = parseDouble(m[1].str(), 0.01);
        if (rent <= 0.0) {
            addError("@attention rent must be > 0");
        } else if (rent > 1.0) {
            addError("@attention rent must be a fraction in (0, 1]");
        } else {
            system_.attention.rent = rent;
        }
    }
    if (std::regex_search(body, m, std::regex("af_threshold\\s*=?\\s*([0-9]+)"))) {
        system_.attention.af_threshold = parseInt(m[1].str(), 100);
    }
    if (std::regex_search(body, m, std::regex("total_sti\\s*=?\\s*([0-9]*\\.?[0-9]+)"))) {
        system_.attention.total_sti = parseDouble(m[1].str(), 10000.0);
    }
    return true;
}

bool AliParser::parseTruth(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::string body = header;
    if (header.find('{') != std::string::npos) body += "\n" + joinBlock(collectBlock(lines, i));
    system_.truth.present = true;
    if (body.find("pln") == std::string::npos) addWarning("@truth without pln; PLN formulas still apply");
    std::smatch m;
    if (std::regex_search(body, m, std::regex("default_strength\\s*=?\\s*([0-9]*\\.?[0-9]+)"))) {
        system_.truth.default_strength = clamp01(parseDouble(m[1].str(), 0.5));
    }
    if (std::regex_search(body, m, std::regex("default_confidence\\s*=?\\s*([0-9]*\\.?[0-9]+)"))) {
        system_.truth.default_confidence = clamp01(parseDouble(m[1].str(), 0.5));
    }
    return true;
}

bool AliParser::parseLearn(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::string body = header;
    if (header.find('{') != std::string::npos) body += "\n" + joinBlock(collectBlock(lines, i));
    system_.learn.present = true;
    std::smatch m;
    if (std::regex_search(body, m, std::regex("population\\s*=?\\s*([0-9]+)"))) {
        system_.learn.population = static_cast<unsigned>(parseInt(m[1].str(), 20));
    }
    if (std::regex_search(body, m, std::regex("fitness\\s*=?\\s*([A-Za-z_][A-Za-z0-9_]*)"))) {
        system_.learn.fitness = m[1].str();
        if (system_.learn.fitness != "grip_index") {
            addError("@learn fitness must be grip_index, got '" + system_.learn.fitness + "'");
        }
    }
    if (std::regex_search(body, m, std::regex("evolve\\s+rule_set\\s*\\(\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*\\)\\s+every\\s+([0-9]+)\\s+ticks?"))) {
        system_.learn.rule_set = m[1].str();
        system_.learn.every = static_cast<unsigned>(parseInt(m[2].str(), 100));
    } else if (std::regex_search(body, m, std::regex("every\\s+([0-9]+)"))) {
        system_.learn.every = static_cast<unsigned>(parseInt(m[1].str(), 100));
    }
    if (system_.learn.every < 1) addError("@learn every must be >= 1");
    if (std::regex_search(body, m, std::regex("mutation_rate\\s*=?\\s*([0-9]*\\.?[0-9]+)"))) {
        system_.learn.mutation_rate = clamp01(parseDouble(m[1].str(), 0.1));
    }
    if (std::regex_search(body, m, std::regex("elitism\\s*=?\\s*([0-9]*\\.?[0-9]+)"))) {
        system_.learn.elitism = clamp01(parseDouble(m[1].str(), 0.2));
    }
    if (std::regex_search(body, m, std::regex("seed\\s*=?\\s*([0-9]+)"))) {
        system_.learn.seed = static_cast<unsigned>(parseInt(m[1].str(), 1));
    }
    return true;
}

bool AliParser::parseAtomspace(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::string body = header;
    if (header.find('{') != std::string::npos) body += "\n" + joinBlock(collectBlock(lines, i));
    system_.atomspace.present = true;
    std::smatch m;
    if (std::regex_search(body, m, std::regex("backing\\s*=?\\s*([A-Za-z_][A-Za-z0-9_]*)"))) {
        system_.atomspace.backing = m[1].str();
    }
    return true;
}

bool AliParser::parseMu(const std::string& line) {
    if (system_.mu_declared) {
        addError("duplicate @mu");
        return false;
    }
    size_t eq = line.find('=');
    if (eq == std::string::npos) {
        addError("invalid @mu (expected @mu = [ ... ]'label;)");
        return false;
    }
    std::string s = line.substr(eq + 1);
    size_t i = 0;
    struct Frame {
        std::string label;
        std::vector<Frame> children;
    };
    bool failed = false;
    struct Walker {
        static void skip(const std::string& s, size_t& i) {
            while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
        }
        static Frame parse(const std::string& s, size_t& i, bool& failed, AliParser* self) {
            Frame f;
            skip(s, i);
            if (i >= s.size() || s[i] != '[') {
                self->addError("@mu: expected '['");
                failed = true;
                return f;
            }
            ++i;
            while (true) {
                skip(s, i);
                if (i < s.size() && s[i] == '[') f.children.push_back(parse(s, i, failed, self));
                else break;
            }
            skip(s, i);
            if (i >= s.size() || s[i] != ']') {
                self->addError("@mu: expected ']'");
                failed = true;
                return f;
            }
            ++i;
            skip(s, i);
            if (i >= s.size() || s[i] != '\'') {
                self->addError("@mu: label must follow the closing bracket");
                failed = true;
                return f;
            }
            ++i;
            f.label = readIdentAt(s, i);
            if (f.label.empty()) {
                self->addError("@mu: empty membrane label");
                failed = true;
            }
            return f;
        }
    };
    Frame root = Walker::parse(s, i, failed, this);
    if (failed || root.label.empty()) return false;

    std::set<std::string> seen;
    struct Flattener {
        static void walk(const Frame& f, const std::string& parent, AiLinguaSystem& sys, std::set<std::string>& seen, AliParser* self) {
            if (!seen.insert(f.label).second) {
                self->addError("duplicate membrane label '" + f.label + "'");
            }
            MembraneDecl m;
            m.label = f.label;
            m.parent = parent;
            for (size_t c = 0; c < f.children.size(); ++c) m.children.push_back(f.children[c].label);
            sys.membranes.push_back(m);
            for (size_t c = 0; c < f.children.size(); ++c) walk(f.children[c], f.label, sys, seen, self);
        }
    };
    Flattener::walk(root, "", system_, seen, this);
    system_.mu_declared = true;
    return !failed;
}

namespace {

void applyObjectField(ObjectDecl& o, const std::string& raw, AliParser* /*self*/) {
    std::string t = AliParser::stripSemi(raw);
    if (t.empty()) return;
    std::string key, val;
    if (AliParser::parseKeyValue(t, key, val)) t = key + " " + val;
    std::istringstream iss(t);
    std::string kw;
    iss >> kw;
    if (kw == "symbol") iss >> o.symbol;
    else if (kw == "truth") iss >> o.strength >> o.confidence;
    else if (kw == "attention") iss >> o.sti;
    else if (kw == "phase") iss >> o.phase;
    else if (kw == "membrane") iss >> o.membrane;
    else if (kw == "kind") iss >> o.kind;
    else if (kw == "count") iss >> o.count;
}

void applyRuleField(RuleDecl& r, const std::string& raw) {
    std::string t = AliParser::stripSemi(raw);
    if (t.empty() || t == "{" || t == "}") return;
    if (t == "restore" || t == "catalyst") { r.restore = true; return; }
    std::smatch m;
    if (std::regex_search(t, m, std::regex("when\\s+phase\\s*==\\s*(-?[0-9]+)"))) {
        r.when_phase = AliParser::parseInt(m[1].str(), -1);
        return;
    }
    if (std::regex_search(t, m, std::regex("when\\s+slot\\s*==\\s*([A-Za-z_][A-Za-z0-9_]*)"))) {
        r.when_slot = m[1].str();
        return;
    }
    if (std::regex_search(t, m, std::regex("^pln\\s+([A-Za-z_][A-Za-z0-9_]*)"))) {
        r.pln = m[1].str();
        return;
    }
    if (std::regex_search(t, m, std::regex("^impl\\s+([0-9]*\\.?[0-9]+)\\s+([0-9]*\\.?[0-9]+)"))) {
        r.impl_strength = AliParser::parseDouble(m[1].str(), 0.9);
        r.impl_confidence = AliParser::parseDouble(m[2].str(), 0.8);
        return;
    }
    std::string key, val;
    std::string line = t;
    if (AliParser::parseKeyValue(t, key, val)) line = key + " " + val;
    std::istringstream iss(line);
    std::string kw;
    iss >> kw;
    if (kw == "membrane") iss >> r.membrane;
    else if (kw == "lhs") iss >> r.lhs;
    else if (kw == "rhs") iss >> r.rhs;
    else if (kw == "wage") iss >> r.wage;
    else if (kw == "threshold") iss >> r.threshold;
    else if (kw == "target") {
        iss >> r.target;
        if (r.target == "here") r.target.clear();
    }
}

} // namespace

bool AliParser::parseObject(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::regex re("@object\\s+([A-Za-z_][A-Za-z0-9_]*)");
    std::smatch m;
    if (!std::regex_search(header, m, re)) {
        addError("invalid @object (expected @object name { ... })");
        return false;
    }
    ObjectDecl o;
    o.id = m[1].str();
    o.symbol = o.id;
    o.strength = system_.truth.default_strength;
    o.confidence = system_.truth.default_confidence;
    std::vector<std::string> body;
    if (header.find('{') != std::string::npos) body = collectBlock(lines, i);
    for (size_t k = 0; k < body.size(); ++k) applyObjectField(o, body[k], this);
    o.strength = clamp01(o.strength);
    o.confidence = clamp01(o.confidence);
    if (o.membrane.empty()) o.membrane = "skin";
    system_.objects.push_back(o);
    return true;
}

bool AliParser::parseRule(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::regex re("@rule\\s+([A-Za-z_][A-Za-z0-9_]*)");
    std::smatch m;
    if (!std::regex_search(header, m, re)) {
        addError("invalid @rule (expected @rule name { ... })");
        return false;
    }
    RuleDecl r;
    r.name = m[1].str();
    std::vector<std::string> body;
    if (header.find('{') != std::string::npos) body = collectBlock(lines, i);
    for (size_t k = 0; k < body.size(); ++k) applyRuleField(r, body[k]);
    if (r.membrane.empty()) r.membrane = "skin";
    if (r.lhs.empty() || r.rhs.empty()) addError("@rule " + r.name + " needs lhs and rhs");
    if (r.pln != "none" && r.pln != "deduction" && r.pln != "abduction" && r.pln != "revision") {
        addError("@rule " + r.name + " unknown pln clause '" + r.pln + "'");
    }
    r.impl_strength = clamp01(r.impl_strength);
    r.impl_confidence = clamp01(r.impl_confidence);
    system_.rules.push_back(r);
    return true;
}

bool AliParser::parseDef(const std::string& header, const std::vector<std::string>& lines, size_t& i) {
    std::vector<std::string> body;
    if (header.find('{') != std::string::npos) body = collectBlock(lines, i);
    std::string text = joinBlock(body);
    /* Also accept a same-line pipeline after the brace, already in body. */
    std::vector<std::string> parts;
    std::string cur;
    for (size_t k = 0; k < text.size(); ++k) {
        if (text[k] == '-' && k + 1 < text.size() && text[k + 1] == '>') {
            parts.push_back(cur);
            cur.clear();
            ++k;
        } else {
            cur += text[k];
        }
    }
    if (!trim(cur).empty()) parts.push_back(cur);
    if (parts.empty() && header.find("->") != std::string::npos) parts.push_back(header);
    std::vector<std::string> stages;
    for (size_t p = 0; p < parts.size(); ++p) {
        std::string seg = parts[p];
        size_t cut = seg.find('(');
        if (cut != std::string::npos) seg = seg.substr(0, cut);
        std::istringstream iss(seg);
        std::string word;
        while (iss >> word) {
            if (!word.empty() && word[word.size() - 1] == ';') word.erase(word.size() - 1);
            if (word == "perceive" || word == "orient" || word == "decide" ||
                word == "act" || word == "remember") {
                stages.push_back(word);
                break;
            }
        }
    }
    if (!stages.empty()) system_.stages = stages;
    return true;
}

bool AliParser::parseObserve(const std::vector<std::string>& lines, size_t& i) {
    std::string body = joinBlock(collectBlock(lines, i));
    std::smatch m;
    if (std::regex_search(body, m, std::regex("sample_period\\s*=?\\s*([0-9]+)"))) {
        system_.observe.sample_period = parseInt(m[1].str(), 1);
    }
    std::smatch fm;
    if (std::regex_search(body, fm, std::regex("report_fields\\s*=?\\s*([^;\\n]+)"))) {
        std::string list = fm[1].str();
        std::istringstream iss(list);
        std::string tok;
        while (std::getline(iss, tok, ',')) {
            std::string t = trim(tok);
            if (!t.empty()) system_.observe.report_fields.push_back(t);
        }
    }
    return true;
}

bool AliParser::parseConstraints(const std::vector<std::string>& lines, size_t& i) {
    std::string body = joinBlock(collectBlock(lines, i));
    std::smatch m;
    if (std::regex_search(body, m, std::regex("grip_threshold\\s*=?\\s*([0-9]*\\.?[0-9]+)"))) {
        system_.grip_threshold = clamp01(parseDouble(m[1].str(), 0.3));
    }
    return true;
}

void AliParser::installDefaultMu() {
    /* skin > ecan > af, plus pln, moses, memory as children of skin. */
    MembraneDecl af; af.label = "af"; af.parent = "ecan";
    MembraneDecl ecan; ecan.label = "ecan"; ecan.parent = "skin"; ecan.children.push_back("af");
    MembraneDecl pln; pln.label = "pln"; pln.parent = "skin";
    MembraneDecl moses; moses.label = "moses"; moses.parent = "skin";
    MembraneDecl memory; memory.label = "memory"; memory.parent = "skin";
    MembraneDecl skin; skin.label = "skin";
    skin.children.push_back("ecan");
    skin.children.push_back("pln");
    skin.children.push_back("moses");
    skin.children.push_back("memory");
    system_.membranes.push_back(skin);
    system_.membranes.push_back(ecan);
    system_.membranes.push_back(af);
    system_.membranes.push_back(pln);
    system_.membranes.push_back(moses);
    system_.membranes.push_back(memory);
}

void AliParser::validate() {
    lineNum_ = 0;
    if (system_.model_type.empty()) addError("missing @aimodel<...> declaration");
    if (system_.membranes.empty()) installDefaultMu();
    if (!system_.clock.present) {
        addWarning("no @clock; treating the system as period 1");
        system_.clock.period = 1;
        system_.clock.name = "skin";
    }
    if (system_.stages.empty()) {
        system_.stages.push_back("perceive");
        system_.stages.push_back("orient");
        system_.stages.push_back("decide");
        system_.stages.push_back("act");
        system_.stages.push_back("remember");
    }
    if (!system_.atomspace.backing.empty() && !system_.findMembrane(system_.atomspace.backing)) {
        addWarning("@atomspace backing '" + system_.atomspace.backing + "' is not a membrane; remember still writes AtomSpace");
    }

    std::set<std::string> ids;
    for (size_t i = 0; i < system_.objects.size(); ++i) {
        const ObjectDecl& o = system_.objects[i];
        if (!ids.insert(o.id).second) addError("duplicate @object '" + o.id + "'");
        if (!system_.findMembrane(o.membrane)) {
            addError("@object " + o.id + " names unknown membrane '" + o.membrane + "'");
        }
    }
    std::set<std::string> rules;
    for (size_t i = 0; i < system_.rules.size(); ++i) {
        const RuleDecl& r = system_.rules[i];
        if (!rules.insert(r.name).second) addError("duplicate @rule '" + r.name + "'");
        const MembraneDecl* home = system_.findMembrane(r.membrane);
        if (!home) {
            addError("@rule " + r.name + " names unknown membrane '" + r.membrane + "'");
            continue;
        }
        if (r.when_phase >= system_.clock.period) {
            addError("@rule " + r.name + " phase guard " + std::to_string(r.when_phase) +
                     " is outside clock period " + std::to_string(system_.clock.period));
        }
        if (!r.when_slot.empty() && !system_.phase_register.present) {
            addError("@rule " + r.name + " uses a slot guard but no @phase_register is declared");
        }
        if (r.target.empty() || r.target == r.membrane) continue;
        const MembraneDecl* dest = system_.findMembrane(r.target);
        if (!dest) {
            addError("@rule " + r.name + " target '" + r.target + "' is not a membrane");
            continue;
        }
        bool to_parent = (home->parent == r.target);
        bool to_child = false;
        for (size_t c = 0; c < home->children.size(); ++c) {
            if (home->children[c] == r.target) to_child = true;
        }
        if (!to_parent && !to_child) {
            addError("sibling-to-sibling send from '" + r.membrane + "' to '" + r.target +
                     "'; route (obj)out to the parent then (obj)in_" + r.target);
        }
    }
}

} // namespace ailingua
} // namespace plingua
