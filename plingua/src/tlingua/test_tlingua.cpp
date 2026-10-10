/*
 * test_tlingua.cpp
 *
 * Verifies the one T-Lingua dialect: closed 11-cycle, circular phase
 * distance, PPM prime gating, and resonance exchange.  Fractal, spinor,
 * daemon/angel, and module/import are profiles, not extra grammars.
 *
 * Copyright (C) 2026  P-Lingua/T-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include <tlingua/tli_parser.hpp>

using namespace plingua::tlingua;

static int tests_run = 0;
static int tests_passed = 0;

#define ASSERT_TRUE(cond, msg)                                                 \
    do {                                                                       \
        ++tests_run;                                                           \
        if (cond) {                                                            \
            ++tests_passed;                                                    \
            std::cout << "  [PASS] " << (msg) << "\n";                         \
        } else {                                                               \
            std::cout << "  [FAIL] " << (msg) << "\n";                         \
        }                                                                      \
    } while (0)

static void section(const std::string& title) {
    std::cout << "\n=== " << title << " ===\n";
}

static bool contains(const std::string& s, const std::string& needle) {
    return s.find(needle) != std::string::npos;
}

static bool fired(const StepTrace& tr, const std::string& name) {
    for (size_t i = 0; i < tr.fired.size(); ++i)
        if (tr.fired[i] == name) return true;
    return false;
}

static int countObj(const TLinguaSystem& sys, const std::string& mem,
                    const std::string& obj) {
    std::map<std::string, std::map<std::string, int> >::const_iterator mit =
        sys.final_objects.find(mem);
    if (mit == sys.final_objects.end()) return 0;
    std::map<std::string, int>::const_iterator oit = mit->second.find(obj);
    if (oit == mit->second.end()) return 0;
    return oit->second;
}

static std::string findFile(const std::string& rel) {
    const char* prefixes[] = {"", "../", "plingua/", "../plingua/"};
    for (size_t i = 0; i < 4; ++i) {
        std::string path = std::string(prefixes[i]) + rel;
        std::ifstream in(path.c_str());
        if (in) return path;
    }
    return rel;
}

static bool writeFile(const std::string& path, const std::string& body) {
    std::ofstream out(path.c_str());
    if (!out) return false;
    out << body;
    return true;
}

static void test_ring_math() {
    section("Ring math");
    ASSERT_TRUE(circularPhaseDistance(10, 0, 11) == 1,
                "circ(10, 0, 11) == 1");
    ASSERT_TRUE(circularPhaseDistance(0, 10, 11) == 1,
                "circ(0, 10, 11) == 1 (negative remainder)");
    ASSERT_TRUE(circularPhaseDistance(0, 0, 11) == 0, "circ(0, 0, 11) == 0");
    ASSERT_TRUE(circularPhaseDistance(3, 8, 11) == 5, "circ(3, 8, 11) == 5");

    std::vector<int> alphabet = ppmAlphabet(4);
    ASSERT_TRUE(alphabet.size() == 4 && alphabet[0] == 2 && alphabet[3] == 7,
                "first 4 PPM primes are 2,3,5,7");
    ASSERT_TRUE(ppmAlphabet(0).empty() && ppmAlphabet(16).empty(),
                "prime count outside 1..15 is rejected");

    uint64_t sig = 0;
    std::vector<int> primes;
    primes.push_back(2);
    primes.push_back(3);
    primes.push_back(5);
    ASSERT_TRUE(primeSignature(primes, sig) && sig == 30,
                "prime_signature(2,3,5) == 30");
    ASSERT_TRUE(gateOpen(30, 0) && !gateOpen(30, 1),
                "gate open at step 0, closed at step 1");
    ASSERT_TRUE(spinorSign(0, 4, 2) == 1 && spinorSign(2, 4, 2) == -1 &&
                    spinorSign(4, 4, 2) == 1,
                "spinor +1, flip at 2π, +1 at 4π");
}

static void test_issue_snippet() {
    section("Issue snippet");
    const char* src =
        "@tmodel<time_crystal>\n"
        "@clock skin { period 11; wrap d11 -> rim; reseed singularity_point; }\n"
        "@phase_register cfga { cycle 13; slots [add,sub,mul,div,diff,int,\n"
        "                       inner,outer,geometric,project,reject,rotate,reflect]; }\n"
        "   -- first-class clock, not a comment that eats the arrow\n"
        "rule fire : operator * slot(X) --> done(X)\n"
        "            when phase == 0\n"
        "            with resonance(match) ;\n";
    TliParser parser;
    ASSERT_TRUE(parser.parseString(src), "issue snippet parses");
    const TLinguaSystem& sys = parser.system();
    ASSERT_TRUE(sys.clocks.size() == 1 && sys.clocks[0].period == 11,
                "clock period 11");
    ASSERT_TRUE(sys.clocks[0].wrap_from == "d11" && sys.clocks[0].wrap_to == "rim",
                "wrap d11 -> rim");
    ASSERT_TRUE(sys.registers.size() == 1 && sys.registers[0].slots.size() == 13,
                "13 comma-separated slots");
    ASSERT_TRUE(sys.rules.size() == 1 && sys.rules[0].phase_guard == 0,
                "rule form keeps phase guard");
    ASSERT_TRUE(sys.rules[0].resonance == RES_MATCH, "resonance(match) kept");
    ASSERT_TRUE(sys.rules[0].membrane == "skin", "bare rule defaults to skin");
    ASSERT_TRUE(parser.verify(11) && sys.verification.eleven_cycle,
                "snippet verifies the 11-cycle");
}

static void test_exemplars() {
    section("Exemplars");
    TliParser core;
    std::string corePath = findFile("lang/tli/time_crystal_core.tli");
    ASSERT_TRUE(core.parseFile(corePath), "time_crystal_core.tli parses");
    ASSERT_TRUE(core.verify() && core.system().verification.eleven_cycle,
                "time crystal closes the 11-cycle");
    ASSERT_TRUE(core.system().clock_wraps["tick"] == 1,
                "one wrap after one period");
    ASSERT_TRUE(core.system().final_phase["tick"] == 0,
                "phase is 0 after period steps");
    std::string lowered = core.lower();
    ASSERT_TRUE(contains(lowered, "Traceability") && contains(lowered, "d11") &&
                    contains(lowered, "tick_wrap") && contains(lowered, "-->"),
                "lowering emits d11, tick_wrap, and a Traceability header");

    TliParser cfga;
    std::string cfgaPath = findFile("lang/tli/cfga_operator.tli");
    ASSERT_TRUE(cfga.parseFile(cfgaPath), "cfga_operator.tli parses");
    ASSERT_TRUE(cfga.system().registers.size() == 1 &&
                    cfga.system().registers[0].slots.size() == 13,
                "CFGA register has 13 slots");
    ASSERT_TRUE(cfga.system().rules.size() == 16, "CFGA keeps its 16 rules");
    ASSERT_TRUE(cfga.verify(), "CFGA verifies");
    std::string cfgaPli = cfga.lower();
    ASSERT_TRUE(contains(cfgaPli, "phase(0)") && contains(cfgaPli, "slot(add)"),
                "CFGA lowering seeds phase(0) and slot(add)");
}

static void test_gates_and_scheduling() {
    section("Gates, phase, scheduling");
    TliParser badPrime;
    ASSERT_TRUE(badPrime.parseString(
                    "@tmodel<time_crystal>\n"
                    "@gate neuron by prime_signature(4);\n"),
                "prime 4 is parsed so verify can reject it");
    ASSERT_TRUE(!badPrime.verify(), "prime 4 is not in the PPM alphabet");
    ASSERT_TRUE(!badPrime.system().verification.failures.empty() &&
                    contains(badPrime.system().verification.failures[0], "4"),
                "failure names prime 4");

    TliParser gate;
    ASSERT_TRUE(gate.parseString(
                    "@tmodel<time_crystal>\n"
                    "@semantics { mode = daemon; }\n"
                    "@clock tick { period 11; wrap d11 -> skin; reseed singularity_point; }\n"
                    "@mu = [ []'neuron ]'skin;\n"
                    "@mneuron = token;\n"
                    "@gate neuron by prime_signature(2, 3, 5);\n"
                    "[hold : token --> token * held ]'neuron;\n"),
                "signature-30 model parses");
    ASSERT_TRUE(gate.system().gates.size() == 1 &&
                    gate.system().gates[0].signature == 30,
                "gate signature is 30");
    ASSERT_TRUE(gate.verify(11), "signature 30 warns, it does not fail the 11-cycle");
    bool warned = false;
    for (size_t i = 0; i < gate.system().warnings.size(); ++i)
        if (contains(gate.system().warnings[i], "does not divide")) warned = true;
    ASSERT_TRUE(warned, "warns that 30 does not divide a positive 11-cycle tick");
    ASSERT_TRUE(gate.system().trace.size() >= 2 &&
                    gate.system().trace[0].gates_open["neuron"] &&
                    !gate.system().trace[1].gates_open["neuron"],
                "gate open at step 0 and closed at step 1");
    ASSERT_TRUE(fired(gate.system().trace[0], "hold") &&
                    !fired(gate.system().trace[1], "hold"),
                "gated rule does not fire while the gate is closed");

    TliParser phase;
    ASSERT_TRUE(phase.parseString(
                    "@tmodel<time_crystal>\n"
                    "@semantics { mode = daemon; }\n"
                    "@clock skin { period 11; wrap d11 -> skin; reseed singularity_point; }\n"
                    "@mu = [ []'neuron ]'skin;\n"
                    "@mneuron = fuel;\n"
                    "[fire : fuel --> fuel * done ]'neuron when phase == 0;\n"),
                "phase-guard model parses");
    ASSERT_TRUE(phase.verify(2), "phase-guard model verifies");
    ASSERT_TRUE(fired(phase.system().trace[0], "fire") &&
                    !fired(phase.system().trace[1], "fire"),
                "when phase == 0 does not fire at phase 1");
    ASSERT_TRUE(countObj(phase.system(), "neuron", "done") == 1,
                "phase-0 rule fires once in the first two steps");

    TliParser mismatch;
    ASSERT_TRUE(!mismatch.parseString(
                    "@phase_register cfga { cycle 2; slots [add]; }\n"),
                "slot/cycle mismatch is an error");

    TliParser angelDefault;
    ASSERT_TRUE(angelDefault.parseString("@tmodel<time_crystal>\n@mu = [ ]'skin;\n"),
                "model without @semantics parses");
    ASSERT_TRUE(angelDefault.system().semantics == SEM_ANGEL &&
                    !angelDefault.system().semantics_set,
                "default semantics is angel");

    const char* both =
        "@tmodel<time_crystal>\n"
        "@mu = [ []'m ]'skin;\n"
        "@mm = a, b;\n"
        "[one : a --> x ]'m;\n"
        "[two : b --> y ]'m;\n";
    TliParser daemon;
    ASSERT_TRUE(daemon.parseString(std::string("@semantics { mode = daemon; }\n") + both),
                "daemon model parses");
    ASSERT_TRUE(daemon.verify(1), "daemon verifies");
    ASSERT_TRUE(fired(daemon.system().trace[0], "one") &&
                    fired(daemon.system().trace[0], "two"),
                "daemon fires both non-conflicting rules");
    TliParser angel;
    ASSERT_TRUE(angel.parseString(both), "angel model parses");
    ASSERT_TRUE(angel.verify(1), "angel verifies");
    ASSERT_TRUE(fired(angel.system().trace[0], "one") &&
                    !fired(angel.system().trace[0], "two"),
                "angel fires one rule per membrane");
}

static void test_resonance_spinor_fractal() {
    section("Resonance, spinor, fractal");
    TliParser match;
    ASSERT_TRUE(match.parseString(
                    "@tmodel<time_crystal>\n"
                    "@semantics { mode = daemon; }\n"
                    "@mu = [ []'src []'dst ]'skin;\n"
                    "@msrc = signal;\n"
                    "@gate src by prime_signature(2, 3);\n"
                    "@gate dst by prime_signature(3, 5);\n"
                    "[send : signal --> (signal)in_dst ]'src with resonance(match);\n"),
                "matching resonance parses");
    ASSERT_TRUE(match.verify(1), "matching resonance verifies");
    ASSERT_TRUE(match.system().exchanged >= 1 &&
                    countObj(match.system(), "dst", "signal") == 1,
                "match exchanges the signal");

    TliParser miss;
    ASSERT_TRUE(miss.parseString(
                    "@tmodel<time_crystal>\n"
                    "@semantics { mode = daemon; }\n"
                    "@mu = [ []'src []'dst ]'skin;\n"
                    "@msrc = signal;\n"
                    "@gate src by prime_signature(2);\n"
                    "@gate dst by prime_signature(3);\n"
                    "[send : signal --> (signal)in_dst ]'src with resonance(mismatch);\n"),
                "mismatch resonance parses");
    ASSERT_TRUE(miss.verify(1), "mismatch resonance verifies");
    ASSERT_TRUE(miss.system().dissipated >= 1 &&
                    countObj(miss.system(), "dst", "signal") == 0 &&
                    countObj(miss.system(), "src", "signal") == 0,
                "mismatch dissipates without delivering");

    TliParser spin;
    ASSERT_TRUE(spin.parseString(
                    "@spinor spin { period 4; flip_at 2; object spin; }\n"),
                "spinor profile parses");
    ASSERT_TRUE(spin.verify() && spin.system().verification.spinor_flip,
                "2π flip and 4π return verify");
    TliParser badSpin;
    ASSERT_TRUE(badSpin.parseString(
                    "@spinor spin { period 5; flip_at 2; object spin; }\n"),
                "bad spinor parses");
    ASSERT_TRUE(!badSpin.verify(), "2 * flip_at must equal the period");

    TliParser fractal;
    ASSERT_TRUE(fractal.parseString(
                    "@tmodel<time_crystal>\n"
                    "@fractal { depth 3; scale 0.5; tile box; }\n"),
                "@fractal parses inside T-Lingua");
    ASSERT_TRUE(fractal.system().model_type == "time_crystal" &&
                    fractal.system().fractal.present &&
                    fractal.system().fractal.tile == "box",
                "@fractal is a profile, not a new model type");
    ASSERT_TRUE(fractal.verify(), "fractal profile verifies");
}

static void test_reseed_and_pli() {
    section("Reseed and P-Lingua superset");
    TliParser reseed;
    ASSERT_TRUE(reseed.parseString(
                    "@tmodel<time_crystal>\n"
                    "@semantics { mode = daemon; }\n"
                    "@clock tick { period 11; wrap d11 -> skin; reseed singularity_point; }\n"
                    "@mu = [ []'neuron ]'skin;\n"
                    "[eat : tick --> consumed ]'skin;\n"),
                "reseed model parses");
    ASSERT_TRUE(reseed.verify(11), "reseed model verifies");
    ASSERT_TRUE(reseed.system().clock_wraps["tick"] == 1, "tick wrapped once");
    ASSERT_TRUE(countObj(reseed.system(), "skin", "tick") >= 1,
                "reseed restores a consumed tick at the rim");

    TliParser pli;
    ASSERT_TRUE(pli.parseString(
                    "@model<psystems_basic>\n"
                    "@mu = [ []'inner ]'skin;\n"
                    "@minner = a;\n"
                    "[send : a --> (b)out ]'inner;\n"),
                "plain .pli is a T-Lingua superset");
    ASSERT_TRUE(pli.system().rules.size() == 1 &&
                    pli.system().parents["inner"] == "skin",
                "@mu parent of inner is skin");
    ASSERT_TRUE(pli.verify(1) && countObj(pli.system(), "skin", "b") == 1,
                "out-send delivers to the parent");
}

static void test_imports() {
    section("Imports");
    const std::string dir = "/tmp/tlingua-tests";
    if (std::system(("mkdir -p " + dir).c_str()) != 0) {
        ASSERT_TRUE(false, "create import test directory");
        return;
    }
    ASSERT_TRUE(writeFile(dir + "/clock.tli",
                          "@clock tick { period 11; wrap d11 -> skin; }\n"),
                "write clock profile");
    ASSERT_TRUE(writeFile(dir + "/host.tli",
                          "@tmodel<time_crystal>\n"
                          "@import \"clock.tli\";\n"
                          "@import \"clock.tli\";\n"),
                "write diamond host");
    TliParser diamond;
    ASSERT_TRUE(diamond.parseFile(dir + "/host.tli"), "diamond import parses");
    ASSERT_TRUE(diamond.system().clocks.size() == 1, "diamond skips the second copy");
    ASSERT_TRUE(diamond.system().imports.size() == 1 &&
                    diamond.system().imports[0].inlined &&
                    diamond.system().imports[0].symbols.size() == 1 &&
                    diamond.system().imports[0].symbols[0] == "tick",
                "same-dialect import is inlined and exports the clock name");

    ASSERT_TRUE(writeFile(dir + "/a.tli", "@import \"b.tli\";\n"), "write cycle a");
    ASSERT_TRUE(writeFile(dir + "/b.tli", "@import \"a.tli\";\n"), "write cycle b");
    TliParser cycle;
    ASSERT_TRUE(!cycle.parseFile(dir + "/a.tli"), "import cycle is an error");
    bool sawCycle = false;
    for (size_t i = 0; i < cycle.system().errors.size(); ++i)
        if (contains(cycle.system().errors[i], "cycle")) sawCycle = true;
    ASSERT_TRUE(sawCycle, "cycle error names the cycle");

    ASSERT_TRUE(writeFile(dir + "/companion.pli",
                          "@model<psystems_basic>\n@mu = [ []'neuron ]'skin;\n"),
                "write pli companion");
    ASSERT_TRUE(writeFile(dir + "/with_pli.tli",
                          "@tmodel<time_crystal>\n@import \"companion.pli\";\n"),
                "write cross-dialect host");
    TliParser cross;
    ASSERT_TRUE(cross.parseFile(dir + "/with_pli.tli"), "pli companion parses");
    ASSERT_TRUE(cross.system().imports.size() == 1 &&
                    !cross.system().imports[0].inlined &&
                    cross.system().imports[0].dialect == "pli",
                "other dialects are recorded, not inlined");
    bool sawNeuron = false;
    for (size_t i = 0; i < cross.system().imports[0].symbols.size(); ++i)
        if (cross.system().imports[0].symbols[i] == "neuron") sawNeuron = true;
    ASSERT_TRUE(sawNeuron, "pli companion exports its membrane label");
}

static void test_neuron_example() {
    section("Neuron example");
    std::string path = findFile("examples/tlingua/time_crystal_neuron.tli");
    TliParser parser;
    ASSERT_TRUE(parser.parseFile(path), "time_crystal_neuron.tli parses");
    ASSERT_TRUE(parser.verify(11), "neuron example verifies");
    const Verification& v = parser.system().verification;
    ASSERT_TRUE(v.eleven_cycle && v.closed_loop && v.circular_phase_distance &&
                    v.prime_gating && v.resonance_exchange,
                "neuron example checks every temporal claim");
    ASSERT_TRUE(parser.system().fractal.present &&
                    !parser.system().spinors.empty(),
                "fractal and spinor arrive as imported profiles");
    std::string pli = parser.lower();
    ASSERT_TRUE(contains(pli, "'neuron") && contains(pli, "'d11") &&
                    contains(pli, "Traceability"),
                "lowered neuron declares both the author tree and the clock ring");
}

int main() {
    test_ring_math();
    test_issue_snippet();
    test_exemplars();
    test_gates_and_scheduling();
    test_resonance_spinor_fractal();
    test_reseed_and_pli();
    test_imports();
    test_neuron_example();

    std::cout << "\n" << tests_passed << " / " << tests_run << " passed\n";
    return tests_passed == tests_run ? 0 : 1;
}
