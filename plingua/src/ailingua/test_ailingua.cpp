/*
 * test_ailingua.cpp
 *
 * Parser and cognitive-cycle tests for Ai-Lingua.
 *
 * Copyright (C) 2026  P-Lingua/Ai-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <ailingua/ai_engine.hpp>
#include <ailingua/ali_parser.hpp>

#include <cmath>
#include <fstream>
#include <iostream>
#include <string>

using namespace plingua::ailingua;

static int tests_run = 0;
static int tests_passed = 0;

#define ASSERT_TRUE(cond, msg) \
    do { \
        ++tests_run; \
        if (cond) { \
            ++tests_passed; \
            std::cout << "  [PASS] " << (msg) << "\n"; \
        } else { \
            std::cout << "  [FAIL] " << (msg) << "\n"; \
        } \
    } while (0)

#define ASSERT_NEAR(a, b, eps, msg) \
    ASSERT_TRUE(std::fabs((a) - (b)) < (eps), msg)

static void section(const std::string& title) {
    std::cout << "\n=== " << title << " ===\n";
}

static bool hasError(const AiLinguaSystem& sys, const std::string& frag) {
    for (size_t i = 0; i < sys.errors.size(); ++i) {
        if (sys.errors[i].find(frag) != std::string::npos) return true;
    }
    return false;
}

static void writeFile(const std::string& path, const std::string& body) {
    std::ofstream out(path.c_str());
    out << body;
}

static const char* kHeader =
    "@aimodel<cognitive_time_crystal>\n"
    "@attention ecan { wage 10; rent 0.01; af_threshold 100; }\n"
    "@truth pln;\n"
    "@atomspace { backing memory; }\n";

static void test_parse_cycle_and_default_tree() {
    section("Parser – ennead, clock, pipeline, default tree");
    AliParser p;
    bool ok = p.parseString(
        std::string(kHeader) +
        "@ennead {\n"
        "  @triad_a { identity_continuity=0.7; skill_readiness=0.6; motivational_valence=0.8; }\n"
        "}\n"
        "@clock skin { period 11; wrap d11 -> skin; reseed singularity_point; }\n"
        "def cognitive_cycle() {\n"
        "    perceive -> orient (grip) -> decide (PLN) -> act -> remember (AtomSpace);\n"
        "}\n"
        "@object perception { symbol perception; truth 0.9 0.8; attention 200; membrane skin; kind arena; }\n");
    ASSERT_TRUE(ok, "minimal cognitive model parses");
    const AiLinguaSystem& s = p.system();
    ASSERT_TRUE(s.model_type == "cognitive_time_crystal", "@aimodel identifier");
    ASSERT_NEAR(s.ennead.identity_continuity, 0.7, 1e-9, "ennead identity_continuity");
    ASSERT_TRUE(s.clock.period == 11, "clock period 11");
    ASSERT_TRUE(s.clock.wrap_from == "d11" && s.clock.wrap_to == "skin", "wrap d11 -> skin");
    ASSERT_TRUE(s.clock.reseed == "singularity_point", "reseed symbol");
    ASSERT_TRUE(s.stages.size() == 5 && s.stages[0] == "perceive" && s.stages[4] == "remember",
                "five-stage pipeline");
    ASSERT_TRUE(!s.mu_declared, "omitted @mu is filled in, not declared");
    const MembraneDecl* skin = s.findMembrane("skin");
    const MembraneDecl* af = s.findMembrane("af");
    const MembraneDecl* memory = s.findMembrane("memory");
    ASSERT_TRUE(skin && af && memory, "default tree has skin, af, memory");
    ASSERT_TRUE(af && af->parent == "ecan", "af is a child of ecan");
    ASSERT_TRUE(memory && memory->parent == "skin", "memory is a child of skin");
    ASSERT_TRUE(s.objects.size() == 1 && s.objects[0].strength == 0.9, "object truth strength");
}

static void test_missing_aimodel_and_sibling() {
    section("Parser – missing @aimodel and sibling send");
    AliParser missing;
    ASSERT_TRUE(!missing.parseString("@object perception { membrane skin; }\n"),
                "missing @aimodel is rejected");
    ASSERT_TRUE(hasError(missing.system(), "missing @aimodel"), "error names missing @aimodel");

    AliParser sib;
    bool ok = sib.parseString(
        std::string(kHeader) +
        "@mu = [ [ ]'ecan [ ]'pln ]'skin;\n"
        "@rule hop { membrane ecan; lhs a; rhs b; target pln; }\n");
    ASSERT_TRUE(!ok, "sibling-to-sibling send is rejected");
    ASSERT_TRUE(hasError(sib.system(), "sibling-to-sibling send"),
                "error text includes sibling-to-sibling send");

    AliParser child;
    bool child_ok = child.parseString(
        std::string(kHeader) +
        "@mu = [ [ ]'memory ]'skin;\n"
        "@rule down { membrane skin; lhs a; rhs b; target memory; }\n"
        "@rule up { membrane memory; lhs b; rhs a; target skin; }\n");
    ASSERT_TRUE(child_ok, "parent and direct-child targets are accepted");
}

static void test_imports() {
    section("Import – inline, companion, cycle, missing");
    const std::string dir = "/tmp/nanocyc_ali_import";
    writeFile(dir + "_lib.ali",
              "@object shared_percept { symbol shared_percept; attention 80; membrane skin; kind arena; }\n"
              "@rule shared_rule { membrane skin; lhs shared_percept; rhs note; }\n");
    writeFile(dir + "_host.ali",
              std::string("@import \"") + dir + "_lib.ali\";\n" + kHeader);
    AliParser host;
    ASSERT_TRUE(host.parseFile(dir + "_host.ali"), "same-dialect import inlines");
    ASSERT_TRUE(host.system().imports.size() == 1 && host.system().imports[0].inlined,
                "inlined flag set");
    ASSERT_TRUE(host.system().imports[0].dialect == "ali", "dialect is ali");
    ASSERT_TRUE(!host.system().imports[0].symbols.empty(), "extracted symbols");
    bool saw = false;
    for (size_t i = 0; i < host.system().objects.size(); ++i) {
        if (host.system().objects[i].id == "shared_percept") saw = true;
    }
    ASSERT_TRUE(saw, "inlined @object is part of the host system");

    writeFile(dir + "_comp.pli",
              "@model<membrane_computing>\n"
              "def main() { @mu = [[]'memory]'skin; @ms(skin) = perception; }\n");
    writeFile(dir + "_with_pli.ali",
              std::string("@import \"") + dir + "_comp.pli\";\n" + kHeader);
    AliParser comp;
    ASSERT_TRUE(comp.parseFile(dir + "_with_pli.ali"), "pli companion parses");
    ASSERT_TRUE(comp.system().imports.size() == 1 && !comp.system().imports[0].inlined,
                "pli companion is not inlined");
    ASSERT_TRUE(comp.system().imports[0].dialect == "pli", "companion dialect pli");
    bool skin_sym = false;
    for (size_t i = 0; i < comp.system().imports[0].symbols.size(); ++i) {
        if (comp.system().imports[0].symbols[i] == "skin") skin_sym = true;
    }
    ASSERT_TRUE(skin_sym, "companion symbols include @mu label skin");

    writeFile(dir + "_a.ali",
              std::string("@import \"") + dir + "_b.ali\";\n" + kHeader);
    writeFile(dir + "_b.ali",
              std::string("@import \"") + dir + "_a.ali\";\n" + kHeader);
    AliParser cyc;
    ASSERT_TRUE(!cyc.parseFile(dir + "_a.ali"), "import cycle is rejected");
    ASSERT_TRUE(hasError(cyc.system(), "import cycle"), "cycle error text");

    AliParser miss;
    ASSERT_TRUE(!miss.parseString("@import \"/tmp/nanocyc_no_such.ali\";\n@aimodel<cognitive_time_crystal>\n",
                                  "/tmp/nanocyc_ali_host.ali"),
                "missing import is an error");
    ASSERT_TRUE(hasError(miss.system(), "cannot open import"), "missing-import error text");
}

static std::string modelWith(const std::string& body) {
    return std::string(kHeader) +
           "def cognitive_cycle() { orient -> decide -> act -> remember; }\n" +
           body;
}

static void test_phase_wage_deduction_remember() {
    section("Cycle – phase gate, wage gate, deduction, AtomSpace");
    AliParser phase_p;
    ASSERT_TRUE(phase_p.parseString(modelWith(
        "@clock skin { period 4; }\n"
        "@object perception { attention 80; membrane skin; kind arena; truth 0.9 0.8; }\n"
        "@rule later { membrane skin; lhs perception; rhs concept; wage 10; threshold 1; when phase == 1; target memory; }\n")),
                "phase-gated model parses");
    AiEngine phase(phase_p.system());
    phase.step();
    ASSERT_TRUE(phase.rulesFired() == 0, "phase 0 does not fire a phase==1 rule");
    ASSERT_TRUE(phase.phase() == 1, "clock advances at end of step");
    phase.step();
    ASSERT_TRUE(phase.rulesFired() == 1, "phase 1 fires the rule");
    ASSERT_TRUE(phase.countOf("concept", "memory") == 1, "child send lands in memory");
    ASSERT_TRUE(phase.countOf("perception", "skin") == 0, "non-restore rule consumes LHS");

    AliParser wage_p;
    ASSERT_TRUE(wage_p.parseString(modelWith(
        "@object perception { attention 40; membrane skin; kind arena; }\n"
        "@rule costly { membrane skin; lhs perception; rhs concept; wage 10; threshold 100; }\n")),
                "wage-gated model parses");
    AiEngine wage(wage_p.system());
    wage.step();
    ASSERT_TRUE(wage.rulesFired() == 0, "STI below threshold does not fire");
    ASSERT_TRUE(wage.countOf("perception", "skin") == 1, "ungated object is not consumed");

    AliParser ded_p;
    ASSERT_TRUE(ded_p.parseString(modelWith(
        "@object perception { attention 80; membrane skin; kind arena; truth 0.9 0.8; }\n"
        "@rule attend { membrane skin; lhs perception; rhs concept; wage 10; threshold 1; "
        "pln deduction; impl 0.9 0.8; target memory; restore; }\n")),
                "deduction model parses");
    AiEngine ded(ded_p.system());
    ded.step();
    ASSERT_TRUE(ded.rulesFired() == 1, "restore rule fires");
    ASSERT_TRUE(ded.countOf("perception", "skin") == 1, "restore keeps LHS");
    ASSERT_NEAR(ded.strengthOf("concept"), 0.81, 1e-9, "deduction strength is 0.9*0.9");
    ASSERT_TRUE(ded.hasAtom("perception"), "remember writes the live symbol");
    ASSERT_TRUE(ded.hasAtom("concept"), "remember writes the product");
    ASSERT_NEAR(ded.atomStrength("concept"), 0.81, 1e-6, "AtomSpace strength matches the object");
}

static void test_rent_wrap_grip_moses() {
    section("Cycle – rent, wrap, grip JSON, MOSES");
    AliParser rent_p;
    ASSERT_TRUE(rent_p.parseString(modelWith(
        "@object perception { attention 200; membrane skin; kind arena; }\n")),
                "rent model parses");
    AiEngine rent(rent_p.system());
    rent.step();
    ASSERT_TRUE(rent.stiOf("perception") == 198, "rent 0.01 collects ceil(200*0.01)");

    AliParser wrap_p;
    ASSERT_TRUE(wrap_p.parseString(modelWith(
        "@clock skin { period 2; wrap d2 -> skin; reseed singularity_point; }\n"
        "@object perception { attention 80; membrane skin; kind arena; }\n")),
                "wrap model parses");
    AiEngine wrap(wrap_p.system());
    wrap.step();
    ASSERT_TRUE(wrap.wraps() == 0 && wrap.phase() == 1, "first step does not wrap");
    wrap.step();
    ASSERT_TRUE(wrap.phase() == 0 && wrap.wraps() == 1, "period 2 wraps on the second step");
    ASSERT_TRUE(wrap.countOf("singularity_point", "skin") == 1, "reseed places the absent symbol");

    AliParser grip_p;
    ASSERT_TRUE(grip_p.parseString(modelWith(
        "@object perception { attention 80; membrane skin; kind arena; truth 0.9 0.8; }\n"
        "@object bond { attention 80; membrane skin; kind relation; truth 0.7 0.6; }\n")),
                "grip model parses");
    AiEngine grip(grip_p.system());
    grip.step();
    std::string json = grip.reportJson(1);
    ASSERT_TRUE(json.find("\"grip_index\"") != std::string::npos, "JSON always has grip_index");
    ASSERT_TRUE(json.find("\"emergence_score\"") != std::string::npos, "JSON always has emergence_score");
    ASSERT_TRUE(json.find("\"dialect\": \"ali\"") != std::string::npos, "dialect field");
    ASSERT_TRUE(grip.gripIndex() >= 0.0 && grip.gripIndex() <= 1.0, "grip_index in [0,1]");
    ASSERT_TRUE(grip.emergenceScore() > 0.0, "relation kind contributes to emergence");

    AliParser mos_p;
    ASSERT_TRUE(mos_p.parseString(
        std::string(kHeader) +
        "def cognitive_cycle() { orient -> decide -> act -> remember; }\n"
        "@learn moses { population 4; fitness grip_index; every 1; mutation_rate 1.0; elitism 0.0; seed 1; }\n"
        "@object perception { attention 80; membrane skin; kind arena; truth 0.9 0.8; }\n"
        "@rule attend { membrane skin; lhs perception; rhs concept; wage 10; threshold 1; restore; }\n"),
        "moses model parses");
    AiEngine mos(mos_p.system());
    mos.step();
    ASSERT_TRUE(mos.ruleGenerations() == 1, "MOSES rule population evolves when step % every == 0");
    ASSERT_TRUE(mos.comboGenerations() == 1, "MOSESEngine::evolve is called");
    ASSERT_TRUE(mos.hasMosesProgram(), "combo evolution produced a program");
    ASSERT_TRUE(mos.mosesBestScore() >= -1.0 && mos.mosesBestScore() <= 0.0,
                "moses_best_score stays in [-1, 0]");
    ASSERT_TRUE(mos.populationVaried() || mos.wageOf("attend") != 10,
                "mutation perturbs the wage population or writes a new wage");
}

int main() {
    test_parse_cycle_and_default_tree();
    test_missing_aimodel_and_sibling();
    test_imports();
    test_phase_wage_deduction_remember();
    test_rent_wrap_grip_moses();

    std::cout << "\n" << tests_passed << " / " << tests_run << " passed\n";
    return tests_passed == tests_run ? 0 : 1;
}
