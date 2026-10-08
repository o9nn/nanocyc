#ifndef _AI_ENGINE_HPP_
#define _AI_ENGINE_HPP_

/*
 * ai_engine.hpp
 *
 * Cognitive-cycle runner for Ai-Lingua. Objects carry
 * (symbol, truth_value, attention_value, phase). Rule firing is gated by
 * ECAN wages and phase. MOSES evolves rule wages between cycles. Every step
 * refreshes R-Lingua grip and emergence. AtomSpace is the hypergraph image
 * of the live multiset.
 *
 * See plingua/docs/AILINGUA_SPEC.md.
 *
 * Copyright (C) 2026  P-Lingua/Ai-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <ailingua/ali_parser.hpp>
#include <atomspace_integration.hpp>
#include <ecan_integration.hpp>
#include <moses_integration.hpp>
#include <pln_integration.hpp>
#include <relevance_realization.hpp>

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <map>
#include <memory>
#include <random>
#include <sstream>
#include <string>

namespace plingua {
namespace ailingua {

struct CycleSnapshot {
    unsigned step;
    int phase;
    double grip_index;
    double emergence_score;
    double ennead_balance;
    double relevance_gradient;
    double grip_stability;
    std::size_t af_size;
    std::size_t atom_count;
    double moses_best_score;
    unsigned rules_fired;
    unsigned pln_conclusions;
    unsigned moses_generations;

    CycleSnapshot()
        : step(0), phase(0), grip_index(0), emergence_score(0), ennead_balance(0),
          relevance_gradient(0), grip_stability(0), af_size(0), atom_count(0),
          moses_best_score(-1.0), rules_fired(0), pln_conclusions(0),
          moses_generations(0) {}
};

struct RuntimeObject {
    std::string id;
    std::string symbol;
    std::string membrane;
    std::string kind;
    pln::PLNTruthValue truth;
    ecan::AttentionValue attention;
    int phase;
    unsigned count;
    unsigned ecan_id;
    unsigned rr_id;
    unsigned atom_id;

    RuntimeObject()
        : truth(0.5, 0.5), attention(0, 0, false), phase(0), count(0),
          ecan_id(0), rr_id(0), atom_id(0) {}
};

struct RuntimeRule {
    RuleDecl decl;
    int wage;
    int threshold;
    unsigned ecan_id;
    bool implication_installed;

    RuntimeRule() : wage(1), threshold(0), ecan_id(0), implication_installed(false) {}
};

class AiEngine {
public:
    explicit AiEngine(const AiLinguaSystem& sys)
        : sys_(sys),
          pln_(&atomspace_),
          moses_(1, 1),
          rng_(sys.learn.seed ? sys.learn.seed : 1u),
          next_id_(1),
          phase_(0),
          wraps_(0),
          steps_(0),
          rules_fired_(0),
          rule_generations_(0),
          combo_generations_(0),
          population_varied_(false),
          moses_ready_(false),
          grip_index_(0),
          emergence_score_(0),
          ennead_balance_(0.5),
          relevance_gradient_(0),
          grip_stability_(1) {
        build();
        refreshMetrics();
    }

    bool ok() const { return errors_.empty(); }
    const std::vector<std::string>& errors() const { return errors_; }

    CycleSnapshot step() {
        CycleSnapshot snap;
        if (!ok()) return snap;
        ++steps_;
        std::vector<unsigned> earners;
        unsigned fired_before = rules_fired_;

        if (hasStage("perceive")) perceive();
        if (hasStage("orient")) refreshMetrics();
        if (hasStage("decide")) decide();
        if (hasStage("act")) act(earners);
        if (hasStage("remember")) remember();

        syncAttentionToEcan();
        std::vector<unsigned> forgotten = ecan_.step(earners);
        syncAttentionFromEcan();
        applyForgetting(forgotten);
        projectFocus();

        if (sys_.learn.present && sys_.learn.every > 0 && (steps_ % sys_.learn.every) == 0) {
            evolveRules();
            evolveCombo();
        }

        refreshMetrics();
        advanceClock();

        snap.step = steps_;
        snap.phase = phase_;
        snap.grip_index = grip_index_;
        snap.emergence_score = emergence_score_;
        snap.ennead_balance = ennead_balance_;
        snap.relevance_gradient = relevance_gradient_;
        snap.grip_stability = grip_stability_;
        snap.af_size = ecan_.getAttentionalFocus().size();
        snap.atom_count = atomspace_.atoms.size();
        snap.moses_best_score = moses_.best_overall.score;
        snap.rules_fired = rules_fired_ - fired_before;
        snap.pln_conclusions = static_cast<unsigned>(pln_.getInferenceResults().size());
        snap.moses_generations = rule_generations_;
        history_.push_back(snap);
        return snap;
    }

    std::string reportJson(int steps_run) const {
        std::ostringstream j;
        j << std::fixed << std::setprecision(6);
        j << "{\n";
        j << "  \"dialect\": \"ali\",\n";
        j << "  \"model\": \"" << jsonEscape(sys_.model_type) << "\",\n";
        j << "  \"steps_run\": " << steps_run << ",\n";
        j << "  \"phase\": " << phase_ << ",\n";
        j << "  \"wraps\": " << wraps_ << ",\n";
        j << "  \"rules_fired\": " << rules_fired_ << ",\n";
        j << "  \"system_metrics\": {\n";
        j << "    \"grip_index\": " << grip_index_ << ",\n";
        j << "    \"emergence_score\": " << emergence_score_ << ",\n";
        j << "    \"ennead_balance\": " << ennead_balance_ << ",\n";
        j << "    \"relevance_gradient\": " << relevance_gradient_ << ",\n";
        j << "    \"grip_stability\": " << grip_stability_ << "\n";
        j << "  },\n";
        j << "  \"ecan\": { \"af_size\": " << ecan_.getAttentionalFocus().size()
          << ", \"atoms\": " << ecan_.attention_values.size() << " },\n";
        j << "  \"pln\": { \"conclusions\": " << pln_.getInferenceResults().size() << " },\n";
        j << "  \"moses\": { \"generations\": " << rule_generations_
          << ", \"best_score\": " << moses_.best_overall.score
          << ", \"population_varied\": " << (population_varied_ ? "true" : "false")
          << " },\n";
        j << "  \"atomspace\": { \"atoms\": " << atomspace_.atoms.size() << " },\n";
        j << "  \"objects\": [\n";
        bool first = true;
        for (size_t i = 0; i < objects_.size(); ++i) {
            const RuntimeObject& o = objects_[i];
            if (o.count == 0 && o.symbol == "af_member") continue;
            if (!first) j << ",\n";
            first = false;
            j << "    { \"id\": \"" << jsonEscape(o.id)
              << "\", \"symbol\": \"" << jsonEscape(o.symbol)
              << "\", \"membrane\": \"" << jsonEscape(o.membrane)
              << "\", \"kind\": \"" << jsonEscape(o.kind)
              << "\", \"strength\": " << o.truth.strength
              << ", \"confidence\": " << o.truth.confidence
              << ", \"sti\": " << o.attention.sti
              << ", \"lti\": " << o.attention.lti
              << ", \"phase\": " << o.phase
              << ", \"count\": " << o.count
              << " }";
        }
        j << "\n  ]\n}\n";
        return j.str();
    }

    int phase() const { return phase_; }
    unsigned wraps() const { return wraps_; }
    unsigned rulesFired() const { return rules_fired_; }
    unsigned ruleGenerations() const { return rule_generations_; }
    unsigned comboGenerations() const { return combo_generations_; }
    bool populationVaried() const { return population_varied_; }
    bool hasMosesProgram() const { return static_cast<bool>(moses_.best_overall.tree); }
    double mosesBestScore() const { return moses_.best_overall.score; }
    double gripIndex() const { return grip_index_; }
    double emergenceScore() const { return emergence_score_; }
    std::size_t afSize() const { return ecan_.getAttentionalFocus().size(); }
    std::size_t atomCount() const { return atomspace_.atoms.size(); }

    short stiOf(const std::string& symbol) const {
        const RuntimeObject* o = findSymbol(symbol);
        return o ? o->attention.sti : 0;
    }

    double strengthOf(const std::string& symbol) const {
        const RuntimeObject* o = findSymbol(symbol);
        return o ? o->truth.strength : 0.0;
    }

    unsigned countOf(const std::string& symbol, const std::string& membrane) const {
        unsigned n = 0;
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].symbol == symbol && objects_[i].membrane == membrane)
                n += objects_[i].count;
        }
        return n;
    }

    int wageOf(const std::string& rule) const {
        for (size_t i = 0; i < rules_.size(); ++i) {
            if (rules_[i].decl.name == rule) return rules_[i].wage;
        }
        return -1;
    }

    bool hasAtom(const std::string& symbol) const {
        return !atomspace_.findAtomsByName(symbol).empty();
    }

    double atomStrength(const std::string& symbol) const {
        std::vector<unsigned> ids = atomspace_.findAtomsByName(symbol);
        if (ids.empty()) return 0.0;
        std::shared_ptr<atomspace::Atom> a = atomspace_.getAtom(ids[0]);
        return a ? a->strength : 0.0;
    }

private:
    AiLinguaSystem sys_;
    std::vector<std::string> errors_;
    std::vector<RuntimeObject> objects_;
    std::vector<RuntimeRule> rules_;
    rr::RRHypergraph rr_;
    atomspace::AtomSpace atomspace_;
    pln::PLNInferenceEngine pln_;
    ecan::ECANEngine ecan_;
    moses::MOSESEngine moses_;
    std::mt19937 rng_;
    unsigned next_id_;
    int phase_;
    unsigned wraps_;
    unsigned steps_;
    unsigned rules_fired_;
    unsigned rule_generations_;
    unsigned combo_generations_;
    bool population_varied_;
    bool moses_ready_;
    double grip_index_;
    double emergence_score_;
    double ennead_balance_;
    double relevance_gradient_;
    double grip_stability_;
    std::map<std::string, unsigned> symbol_atoms_;
    std::vector<CycleSnapshot> history_;

    static std::string jsonEscape(const std::string& s) {
        std::string o;
        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if (c == '\\' || c == '"') { o += '\\'; o += c; }
            else if (c == '\n') o += "\\n";
            else o += c;
        }
        return o;
    }

    static rr::AARType aarOf(const std::string& kind) {
        if (kind == "agent") return rr::AARType::AGENT;
        if (kind == "arena" || kind == "stimulus") return rr::AARType::ARENA;
        if (kind == "relation") return rr::AARType::RELATION;
        return rr::AARType::AGENT;
    }

    bool hasStage(const std::string& name) const {
        for (size_t i = 0; i < sys_.stages.size(); ++i) {
            if (sys_.stages[i] == name) return true;
        }
        return false;
    }

    std::string clockMembrane() const {
        if (!sys_.clock.name.empty() && sys_.findMembrane(sys_.clock.name)) return sys_.clock.name;
        return "skin";
    }

    void copyEnnead(rr::EnneadState& e) const {
        e.identity_continuity = sys_.ennead.identity_continuity;
        e.skill_readiness = sys_.ennead.skill_readiness;
        e.motivational_valence = sys_.ennead.motivational_valence;
        e.constraint_clarity = sys_.ennead.constraint_clarity;
        e.affordance_density = sys_.ennead.affordance_density;
        e.feedback_latency = sys_.ennead.feedback_latency;
        e.coupling_strength = sys_.ennead.coupling_strength;
        e.reciprocal_shaping = sys_.ennead.reciprocal_shaping;
        e.adaptive_fit = sys_.ennead.adaptive_fit;
    }

    void build() {
        steps_ = 0;
        copyEnnead(rr_.system_ennead);
        rr_.grip_threshold = sys_.grip_threshold;
        ecan_.bank.rentRate = sys_.attention.rent;
        ecan_.bank.afThreshold = static_cast<short>(sys_.attention.af_threshold);
        ecan_.bank.totalSTI = sys_.attention.total_sti;

        for (size_t i = 0; i < sys_.objects.size(); ++i) {
            addObject(sys_.objects[i]);
        }
        for (size_t i = 0; i < sys_.rules.size(); ++i) {
            RuntimeRule rr;
            rr.decl = sys_.rules[i];
            rr.wage = rr.decl.wage < 0 ? sys_.attention.wage : rr.decl.wage;
            if (rr.wage < 1) rr.wage = 1;
            rr.threshold = rr.decl.threshold < 0 ? 0 : rr.decl.threshold;
            rr.ecan_id = next_id_++;
            ecan_.registerAtom(rr.ecan_id, 0);
            rules_.push_back(rr);
        }
        /* Focus-boundary tokens live in af and are rewritten each step. */
        if (sys_.findMembrane("af")) {
            ObjectDecl tok;
            tok.id = "af_member";
            tok.symbol = "af_member";
            tok.membrane = "af";
            tok.kind = "concept";
            tok.count = 0;
            tok.sti = 0;
            addObject(tok);
        }
    }

    void addObject(const ObjectDecl& decl) {
        RuntimeObject o;
        o.id = decl.id;
        o.symbol = decl.symbol.empty() ? decl.id : decl.symbol;
        o.membrane = decl.membrane;
        o.kind = decl.kind;
        o.truth = pln::PLNTruthValue(decl.strength, decl.confidence);
        o.attention = ecan::AttentionValue(static_cast<short>(decl.sti), 0, false);
        o.phase = decl.phase;
        o.count = decl.count;
        o.ecan_id = next_id_++;
        ecan_.registerAtom(o.ecan_id, o.attention.sti);
        o.rr_id = rr_.addObjectNode(o.symbol, aarOf(o.kind));
        if (rr_.nodes.count(o.rr_id)) {
            rr_.nodes[o.rr_id]->salience = std::max(0.05, o.truth.strength);
            rr_.nodes[o.rr_id]->affordance_realization = std::max(0.05, o.truth.strength);
            rr_.nodes[o.rr_id]->ennead = rr_.system_ennead;
        }
        objects_.push_back(o);
    }

    RuntimeObject* findMutable(const std::string& symbol, const std::string& membrane) {
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].symbol == symbol && objects_[i].membrane == membrane)
                return &objects_[i];
        }
        return 0;
    }

    const RuntimeObject* findSymbol(const std::string& symbol) const {
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].symbol == symbol && objects_[i].count > 0) return &objects_[i];
        }
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].symbol == symbol) return &objects_[i];
        }
        return 0;
    }

    RuntimeObject* ensureProduct(const std::string& symbol, const std::string& membrane) {
        RuntimeObject* existing = findMutable(symbol, membrane);
        if (existing) return existing;
        ObjectDecl d;
        d.id = symbol + "@" + membrane;
        d.symbol = symbol;
        d.membrane = membrane;
        d.kind = "concept";
        d.count = 0;
        d.strength = sys_.truth.default_strength;
        d.confidence = sys_.truth.default_confidence;
        d.sti = 0;
        d.phase = phase_;
        addObject(d);
        return findMutable(symbol, membrane);
    }

    void perceive() {
        std::string host = clockMembrane();
        short boost = static_cast<short>(sys_.attention.wage);
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].count == 0) continue;
            if (objects_[i].membrane != host) continue;
            if (objects_[i].symbol == "af_member") continue;
            objects_[i].attention.boostSTI(boost);
            ecan_.stimulate(objects_[i].ecan_id, boost);
        }
    }

    void refreshMetrics() {
        copyEnnead(rr_.system_ennead);
        for (size_t i = 0; i < objects_.size(); ++i) {
            RuntimeObject& o = objects_[i];
            if (!rr_.nodes.count(o.rr_id)) continue;
            std::shared_ptr<rr::RRNode> n = rr_.nodes[o.rr_id];
            double sal = o.count == 0 ? 0.05 : std::max(0.05, std::min(1.0, o.truth.strength));
            n->salience = sal;
            n->affordance_potential = 1.0;
            n->affordance_realization = std::max(0.05, o.truth.strength);
            n->ennead = rr_.system_ennead;
        }
        rr_.updateRelevanceRealization(0.1);
        double sum_grip = 0.0;
        unsigned n = 0;
        for (std::map<unsigned, std::shared_ptr<rr::RRNode> >::const_iterator it = rr_.nodes.begin();
             it != rr_.nodes.end(); ++it) {
            if (!it->second) continue;
            if (it->second->label == "af_member") continue;
            sum_grip += it->second->grip_index;
            ++n;
        }
        grip_index_ = n ? sum_grip / static_cast<double>(n) : 0.0;
        emergence_score_ = rr_.emergence_score;
        ennead_balance_ = rr_.ennead_balance;
        relevance_gradient_ = rr_.relevance_gradient;
        grip_stability_ = rr_.grip_stability;
    }

    unsigned ensureAtom(const std::string& symbol, double strength, double confidence) {
        std::map<std::string, unsigned>::iterator it = symbol_atoms_.find(symbol);
        if (it != symbol_atoms_.end()) {
            std::shared_ptr<atomspace::Atom> a = atomspace_.getAtom(it->second);
            if (a) {
                a->strength = std::max(a->strength, strength);
                a->confidence = std::max(a->confidence, confidence);
            }
            return it->second;
        }
        unsigned id = atomspace_.addConceptNode(symbol, strength, confidence);
        symbol_atoms_[symbol] = id;
        return id;
    }

    void decide() {
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].count == 0) continue;
            objects_[i].atom_id = ensureAtom(objects_[i].symbol, objects_[i].truth.strength,
                                             objects_[i].truth.confidence);
        }
        for (size_t i = 0; i < rules_.size(); ++i) {
            RuntimeRule& r = rules_[i];
            if (r.decl.pln != "deduction" && r.decl.pln != "abduction") continue;
            if (r.implication_installed) continue;
            unsigned ant = ensureAtom(r.decl.lhs, 0.5, 0.5);
            unsigned cons = ensureAtom(r.decl.rhs, sys_.truth.default_strength, sys_.truth.default_confidence);
            const RuntimeObject* lhs = findSymbol(r.decl.lhs);
            if (lhs) {
                std::shared_ptr<atomspace::Atom> a = atomspace_.getAtom(ant);
                if (a) {
                    a->strength = lhs->truth.strength;
                    a->confidence = lhs->truth.confidence;
                }
            }
            atomspace_.addImplicationLink(ant, cons, r.decl.impl_strength, r.decl.impl_confidence);
            r.implication_installed = true;
        }
        pln_.performInferenceCycle(&rr_);
        for (size_t i = 0; i < objects_.size(); ++i) {
            std::vector<unsigned> ids = atomspace_.findAtomsByName(objects_[i].symbol);
            if (ids.empty()) continue;
            std::shared_ptr<atomspace::Atom> a = atomspace_.getAtom(ids[0]);
            if (!a) continue;
            objects_[i].truth.strength = std::max(objects_[i].truth.strength, a->strength);
            objects_[i].truth.confidence = std::max(objects_[i].truth.confidence, a->confidence);
            objects_[i].atom_id = ids[0];
        }
    }

    static pln::PLNTruthValue revise(const pln::PLNTruthValue& a, const pln::PLNTruthValue& b) {
        double c1 = std::max(1e-9, a.confidence);
        double c2 = std::max(1e-9, b.confidence);
        double s = (a.strength * c1 + b.strength * c2) / (c1 + c2);
        double c = c1 + c2 - c1 * c2;
        return pln::PLNTruthValue(std::min(1.0, std::max(0.0, s)),
                                  std::min(1.0, std::max(0.0, c)));
    }

    void applyPln(const RuntimeRule& rule, const RuntimeObject& lhs, RuntimeObject& rhs) {
        pln::PLNTruthValue impl(rule.decl.impl_strength, rule.decl.impl_confidence);
        pln::PLNTruthValue ant(lhs.truth.strength, lhs.truth.confidence);
        if (rule.decl.pln == "deduction") {
            pln::PLNTruthValue conclusion = impl.conjunction(ant);
            rhs.truth.strength = std::max(rhs.truth.strength, conclusion.strength);
            rhs.truth.confidence = std::max(rhs.truth.confidence, conclusion.confidence);
        } else if (rule.decl.pln == "abduction") {
            double s = rhs.truth.strength * impl.strength * 0.8;
            double c = std::min(rhs.truth.confidence, impl.confidence) * 0.6;
            rhs.truth.strength = std::max(rhs.truth.strength, std::min(1.0, s));
            rhs.truth.confidence = std::max(rhs.truth.confidence, std::min(1.0, c));
        } else if (rule.decl.pln == "revision") {
            rhs.truth = revise(lhs.truth, rhs.truth);
        }
    }

    bool phaseOk(const RuntimeRule& rule) const {
        if (rule.decl.when_phase >= 0 && rule.decl.when_phase != phase_) return false;
        if (!rule.decl.when_slot.empty()) {
            if (sys_.phase_register.slots.empty()) return false;
            unsigned idx = static_cast<unsigned>(phase_) % sys_.phase_register.slots.size();
            if (sys_.phase_register.slots[idx] != rule.decl.when_slot) return false;
        }
        return true;
    }

    void act(std::vector<unsigned>& earners) {
        for (size_t i = 0; i < rules_.size(); ++i) {
            RuntimeRule& rule = rules_[i];
            if (!phaseOk(rule)) continue;
            RuntimeObject* lhs = findMutable(rule.decl.lhs, rule.decl.membrane);
            if (!lhs || lhs->count < 1) continue;
            if (lhs->attention.sti < rule.threshold) continue;
            std::string dest = rule.decl.target.empty() ? rule.decl.membrane : rule.decl.target;
            /* ensureProduct may reallocate objects_; re-find lhs afterwards. */
            RuntimeObject* rhs = ensureProduct(rule.decl.rhs, dest);
            lhs = findMutable(rule.decl.lhs, rule.decl.membrane);
            if (!lhs || !rhs) continue;
            bool fresh = (rhs->count == 0 && rhs->attention.sti <= 0);
            lhs->attention.boostSTI(static_cast<short>(-rule.wage));
            if (!rule.decl.restore) {
                if (lhs->count > 0) --lhs->count;
            }
            applyPln(rule, *lhs, *rhs);
            rhs->count += 1;
            rhs->phase = phase_;
            /* A brand-new product has STI 0. ECAN forgets STI <= 0 in the same
               step, which would erase the rewrite. Seed it with the wage. */
            if (fresh) {
                int seed = rule.wage < 1 ? 1 : rule.wage;
                rhs->attention.boostSTI(static_cast<short>(seed));
            } else if (rhs->attention.sti < rule.threshold) {
                rhs->attention.boostSTI(static_cast<short>(rule.wage));
            }
            earners.push_back(rule.ecan_id);
            ++rules_fired_;
        }
    }

    void remember() {
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].count == 0) continue;
            if (objects_[i].symbol == "af_member") continue;
            objects_[i].atom_id = ensureAtom(objects_[i].symbol,
                                             objects_[i].truth.strength,
                                             objects_[i].truth.confidence);
        }
    }

    void syncAttentionToEcan() {
        for (size_t i = 0; i < objects_.size(); ++i) {
            ecan_.attention_values[objects_[i].ecan_id] = objects_[i].attention;
        }
    }

    void syncAttentionFromEcan() {
        for (size_t i = 0; i < objects_.size(); ++i) {
            std::map<unsigned, ecan::AttentionValue>::const_iterator it =
                ecan_.attention_values.find(objects_[i].ecan_id);
            if (it != ecan_.attention_values.end()) objects_[i].attention = it->second;
        }
    }

    void applyForgetting(const std::vector<unsigned>& forgotten) {
        for (size_t f = 0; f < forgotten.size(); ++f) {
            for (size_t i = 0; i < objects_.size(); ++i) {
                if (objects_[i].ecan_id == forgotten[f] && !objects_[i].attention.vlti) {
                    objects_[i].count = 0;
                }
            }
        }
    }

    void projectFocus() {
        RuntimeObject* tok = findMutable("af_member", "af");
        if (!tok) return;
        tok->count = static_cast<unsigned>(ecan_.getAttentionalFocus().size());
        tok->phase = phase_;
    }

    bool ruleSelected(const RuntimeRule& rule) const {
        if (sys_.learn.rule_set.empty()) return true;
        const std::string& n = sys_.learn.rule_set;
        return rule.decl.name == n || rule.decl.membrane == n ||
               rule.decl.lhs == n || rule.decl.rhs == n;
    }

    void evolveRules() {
        std::vector<size_t> idx;
        for (size_t i = 0; i < rules_.size(); ++i) {
            if (ruleSelected(rules_[i])) idx.push_back(i);
        }
        if (idx.empty()) {
            for (size_t i = 0; i < rules_.size(); ++i) idx.push_back(i);
        }
        if (idx.empty()) {
            ++rule_generations_;
            return;
        }
        struct Genome {
            std::vector<int> wages;
            std::vector<int> thresholds;
            double fitness;
        };
        Genome parent;
        parent.fitness = grip_index_;
        for (size_t k = 0; k < idx.size(); ++k) {
            parent.wages.push_back(rules_[idx[k]].wage);
            parent.thresholds.push_back(rules_[idx[k]].threshold);
        }
        unsigned n = std::max(2u, sys_.learn.population);
        unsigned elite_n = static_cast<unsigned>(sys_.learn.elitism * n);
        if (elite_n > n) elite_n = n;
        std::vector<Genome> pop;
        pop.push_back(parent);
        for (unsigned g = 1; g < n; ++g) {
            Genome child = parent;
            bool elite = g < elite_n;
            if (!elite) {
                for (size_t k = 0; k < child.wages.size(); ++k) {
                    double roll = static_cast<double>(rng_() % 10000) / 10000.0;
                    if (roll < sys_.learn.mutation_rate) {
                        int delta = static_cast<int>(rng_() % 21) - 10;
                        int next = child.wages[k] + delta;
                        if (next < 1) next = 1;
                        if (next != child.wages[k]) population_varied_ = true;
                        child.wages[k] = next;
                        int td = static_cast<int>(rng_() % 11) - 5;
                        int nt = child.thresholds[k] + td;
                        if (nt < 0) nt = 0;
                        child.thresholds[k] = nt;
                    }
                }
            }
            double mean = 0.0;
            for (size_t k = 0; k < child.wages.size(); ++k) mean += child.wages[k];
            mean = child.wages.empty() ? 0.0 : mean / static_cast<double>(child.wages.size());
            child.fitness = grip_index_ - 0.0001 * mean;
            pop.push_back(child);
        }
        std::sort(pop.begin(), pop.end(), [](const Genome& a, const Genome& b) {
            return a.fitness > b.fitness;
        });
        for (size_t k = 0; k < idx.size(); ++k) {
            rules_[idx[k]].wage = pop[0].wages[k];
            rules_[idx[k]].threshold = pop[0].thresholds[k];
        }
        ++rule_generations_;
    }

    void evolveCombo() {
        if (!moses_ready_) {
            std::vector<bool> inputs;
            for (size_t i = 0; i < objects_.size(); ++i) {
                if (objects_[i].symbol == "af_member") continue;
                inputs.push_back(objects_[i].truth.strength >= 0.5);
            }
            if (inputs.empty()) inputs.push_back(true);
            moses_.addTrainingSample(inputs, true);
            moses_.updateFeaturesFromRR(&rr_, 0.0);
            if (moses_.selected_features.empty()) moses_.selected_features.push_back(0);
            moses_.initialise();
            moses_ready_ = true;
        }
        moses_.evolve();
        ++combo_generations_;
    }

    void advanceClock() {
        int period = sys_.clock.period < 1 ? 1 : sys_.clock.period;
        phase_ = (phase_ + 1) % period;
        for (size_t i = 0; i < objects_.size(); ++i) {
            if (objects_[i].membrane == clockMembrane() && objects_[i].count > 0)
                objects_[i].phase = phase_;
        }
        if (phase_ != 0) return;
        ++wraps_;
        if (sys_.clock.reseed.empty()) return;
        if (countOf(sys_.clock.reseed, clockMembrane()) > 0) return;
        ObjectDecl d;
        d.id = sys_.clock.reseed;
        d.symbol = sys_.clock.reseed;
        d.membrane = clockMembrane();
        d.kind = "concept";
        d.count = 1;
        d.strength = sys_.truth.default_strength;
        d.confidence = sys_.truth.default_confidence;
        d.sti = sys_.attention.af_threshold;
        d.phase = 0;
        addObject(d);
    }
};

} // namespace ailingua
} // namespace plingua

#endif // _AI_ENGINE_HPP_
