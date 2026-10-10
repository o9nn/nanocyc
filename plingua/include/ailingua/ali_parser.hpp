#ifndef _ALI_PARSER_HPP_
#define _ALI_PARSER_HPP_

/*
 * ali_parser.hpp
 *
 * Parser for Ai-Lingua (.ali) — the cognitive time-crystal dialect.
 * See plingua/docs/AILINGUA_SPEC.md.
 *
 * Copyright (C) 2026  P-Lingua/Ai-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <map>
#include <set>
#include <string>
#include <vector>
#include <dialect_import.hpp>

namespace plingua {
namespace ailingua {

struct MembraneDecl {
    std::string label;
    std::string parent;
    std::vector<std::string> children;

    MembraneDecl() {}
};

struct EnneadDecl {
    double identity_continuity;
    double skill_readiness;
    double motivational_valence;
    double constraint_clarity;
    double affordance_density;
    double feedback_latency;
    double coupling_strength;
    double reciprocal_shaping;
    double adaptive_fit;

    EnneadDecl()
        : identity_continuity(0.5), skill_readiness(0.5), motivational_valence(0.5),
          constraint_clarity(0.5), affordance_density(0.5), feedback_latency(0.5),
          coupling_strength(0.5), reciprocal_shaping(0.5), adaptive_fit(0.5) {}
};

struct ClockDecl {
    std::string name;
    int period;
    std::string wrap_from;
    std::string wrap_to;
    std::string reseed;
    bool present;

    ClockDecl() : period(1), present(false) {}
};

struct PhaseRegisterDecl {
    std::string name;
    int cycle;
    std::vector<std::string> slots;
    bool present;

    PhaseRegisterDecl() : cycle(0), present(false) {}
};

struct AttentionDecl {
    int wage;
    double rent;
    int af_threshold;
    double total_sti;
    bool present;

    AttentionDecl()
        : wage(10), rent(0.01), af_threshold(100), total_sti(10000.0), present(false) {}
};

struct TruthDecl {
    double default_strength;
    double default_confidence;
    bool present;

    TruthDecl() : default_strength(0.5), default_confidence(0.5), present(false) {}
};

struct LearnDecl {
    unsigned population;
    std::string fitness;
    std::string rule_set;
    unsigned every;
    double mutation_rate;
    double elitism;
    unsigned seed;
    bool present;

    LearnDecl()
        : population(20), fitness("grip_index"), every(100),
          mutation_rate(0.1), elitism(0.2), seed(1), present(false) {}
};

struct AtomSpaceDecl {
    std::string backing;
    bool present;

    AtomSpaceDecl() : backing("memory"), present(false) {}
};

struct ObjectDecl {
    std::string id;
    std::string symbol;
    double strength;
    double confidence;
    int sti;
    int phase;
    std::string membrane;
    std::string kind;
    unsigned count;

    ObjectDecl()
        : strength(0.5), confidence(0.5), sti(0), phase(0),
          kind("concept"), count(1) {}
};

struct RuleDecl {
    std::string name;
    std::string membrane;
    std::string lhs;
    std::string rhs;
    int wage;            /* -1 = inherit @attention wage */
    int threshold;
    int when_phase;      /* -1 = no phase guard */
    std::string when_slot;
    std::string pln;     /* deduction | abduction | revision | none */
    double impl_strength;
    double impl_confidence;
    std::string target;  /* empty = here */
    bool restore;

    RuleDecl()
        : wage(-1), threshold(0), when_phase(-1), pln("none"),
          impl_strength(0.9), impl_confidence(0.8), restore(false) {}
};

struct ObserveDecl {
    int sample_period;
    std::vector<std::string> report_fields;

    ObserveDecl() : sample_period(1) {}
};

struct AiLinguaSystem {
    std::string model_type;
    EnneadDecl ennead;
    ClockDecl clock;
    PhaseRegisterDecl phase_register;
    AttentionDecl attention;
    TruthDecl truth;
    LearnDecl learn;
    AtomSpaceDecl atomspace;
    std::vector<MembraneDecl> membranes;
    std::vector<ObjectDecl> objects;
    std::vector<RuleDecl> rules;
    std::vector<std::string> stages;
    ObserveDecl observe;
    double grip_threshold;
    bool mu_declared;

    std::vector<plingua::ImportedModule> imports;
    std::vector<std::string> errors;
    std::vector<std::string> warnings;

    AiLinguaSystem() : grip_threshold(0.3), mu_declared(false) {}

    bool hasErrors() const { return !errors.empty(); }

    const MembraneDecl* findMembrane(const std::string& label) const {
        for (size_t i = 0; i < membranes.size(); ++i) {
            if (membranes[i].label == label) return &membranes[i];
        }
        return 0;
    }
};

class AliParser {
public:
    AliParser();

    bool parseFile(const std::string& filename);
    bool parseString(const std::string& source, const std::string& filename = "<string>");

    const AiLinguaSystem& system() const { return system_; }

    static std::string trim(const std::string& s);
    static std::string stripSemi(const std::string& s);
    static bool parseKeyValue(const std::string& line, std::string& key, std::string& value);
    static double parseDouble(const std::string& s, double defval);
    static int parseInt(const std::string& s, int defval);
    void addError(const std::string& msg);
    void addWarning(const std::string& msg);

private:
    AiLinguaSystem system_;
    std::string filename_;
    int lineNum_;
    std::set<std::string> importStack_;

    bool parseBody(const std::string& source, const std::string& filename);
    bool handleImport(const std::string& line);
    void validate();
    void installDefaultMu();

    bool parseModelDecl(const std::string& line);
    bool parseEnneadBlock(const std::vector<std::string>& lines, size_t& i);
    bool parseClock(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parsePhaseRegister(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseAttention(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseTruth(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseLearn(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseAtomspace(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseMu(const std::string& line);
    bool parseObject(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseRule(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseDef(const std::string& header, const std::vector<std::string>& lines, size_t& i);
    bool parseObserve(const std::vector<std::string>& lines, size_t& i);
    bool parseConstraints(const std::vector<std::string>& lines, size_t& i);

    static std::string stripComments(const std::string& src);
    static std::vector<std::string> collectBlock(const std::vector<std::string>& lines, size_t& i);
    static std::string joinBlock(const std::vector<std::string>& block);
};

} // namespace ailingua
} // namespace plingua

#endif // _ALI_PARSER_HPP_
