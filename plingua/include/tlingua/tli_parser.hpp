#ifndef _TLI_PARSER_HPP_
#define _TLI_PARSER_HPP_

/*
 * tli_parser.hpp
 *
 * Parser, verifier, and .pli lowering for T-Lingua (.tli) — the temporal/tensor
 * dialect of the P-Lingua family.  One grammar: clocks, phase registers, PPM
 * prime gates, and resonance.  Fractal, spinor, daemon/angel, and module/import
 * are profiles and pragmas, not separate parsers.
 *
 * Copyright (C) 2026  P-Lingua/T-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <cstdint>
#include <map>
#include <set>
#include <string>
#include <vector>

#include <dialect_import.hpp>

namespace plingua {
namespace tlingua {

static const int PPM_PRIME_COUNT = 15;
static const int PPM_PRIMES[PPM_PRIME_COUNT] = {
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47
};
static const int CANONICAL_CYCLE = 11;

enum SemanticsMode {
    SEM_ANGEL = 0,   /* declarative: at most one rule per membrane per step */
    SEM_DAEMON = 1   /* procedural: maximal parallelism */
};

enum ResonanceMode {
    RES_NONE = 0,
    RES_MATCH,
    RES_MISMATCH
};

struct Clock {
    std::string name;
    int period;
    std::string wrap_from; /* corpus label of the innermost station, usually dN */
    std::string wrap_to;   /* rim membrane the tick is re-created in */
    std::string reseed;

    Clock() : period(0) {}
};

struct PhaseRegister {
    std::string name;
    int cycle;
    std::vector<std::string> slots;

    PhaseRegister() : cycle(0) {}
};

struct Gate {
    std::string membrane;
    std::vector<int> primes;
    uint64_t signature; /* product of primes; 0 if overflow or empty */

    Gate() : signature(0) {}
};

struct Spinor {
    std::string name;
    int period;   /* 4π return */
    int flip_at;  /* 2π sign flip */
    std::string object;

    Spinor() : period(0), flip_at(0) {}
};

struct FractalProfile {
    bool present;
    int depth;
    double scale;
    std::string tile;

    FractalProfile() : present(false), depth(0), scale(0.0) {}
};

struct Rule {
    std::string name;
    std::string membrane;
    std::string lhs;
    std::string rhs;
    int phase_guard;          /* -1 if absent */
    std::string slot_guard;   /* empty if absent */
    ResonanceMode resonance;
    std::string resonance_partner;
    int priority;             /* lower wins; 0 if unset */
    int line;

    Rule()
        : phase_guard(-1), resonance(RES_NONE), priority(0), line(0) {}
};

struct MembraneInit {
    std::string label;
    std::string multiset;
};

struct StepTrace {
    int step;
    int clock_phase; /* phase at the start of the step; -1 if no clock */
    std::vector<std::string> fired;
    std::map<std::string, bool> gates_open;
    std::map<std::string, int> register_phase;

    StepTrace() : step(0), clock_phase(-1) {}
};

struct Verification {
    bool closed_loop;
    bool eleven_cycle;
    bool circular_phase_distance;
    bool prime_gating;
    bool resonance_exchange;
    bool spinor_flip;
    bool ok;
    std::vector<std::string> notes;
    std::vector<std::string> failures;

    Verification()
        : closed_loop(true), eleven_cycle(false), circular_phase_distance(true),
          prime_gating(true), resonance_exchange(true), spinor_flip(true),
          ok(false) {}
};

struct TLinguaSystem {
    std::string model_type;
    SemanticsMode semantics;
    bool semantics_set;

    std::vector<Clock> clocks;
    std::vector<PhaseRegister> registers;
    std::vector<int> primes;
    int prime_count; /* 0 if @primes was omitted */
    std::vector<Gate> gates;
    std::vector<Spinor> spinors;
    FractalProfile fractal;
    std::vector<std::string> modules;

    std::string mu;
    std::map<std::string, std::string> parents; /* label -> parent; skin -> "" */
    std::vector<MembraneInit> inits;
    std::vector<Rule> rules;
    std::vector<std::string> passthrough;

    std::vector<plingua::ImportedModule> imports;
    std::vector<std::string> errors;
    std::vector<std::string> warnings;

    Verification verification;
    std::vector<StepTrace> trace;
    std::map<std::string, std::map<std::string, int> > final_objects;
    std::map<std::string, int> clock_wraps;
    std::map<std::string, int> final_phase;
    int exchanged;
    int dissipated;
    int steps_run;

    TLinguaSystem()
        : semantics(SEM_ANGEL), semantics_set(false), prime_count(0),
          exchanged(0), dissipated(0), steps_run(0) {}

    bool hasErrors() const { return !errors.empty(); }
};

/* Ring distance on a period-N cycle.  circ(0, N-1, N) == 1, not N-1. */
int circularPhaseDistance(int a, int b, int period);

/* First `count` PPM primes.  count must be in 1..15; otherwise empty. */
std::vector<int> ppmAlphabet(int count);

bool primeInAlphabet(int prime, const std::vector<int>& alphabet);

/* Product of primes.  Returns false on overflow or an empty list. */
bool primeSignature(const std::vector<int>& primes, uint64_t& out);

/* Gate is open when step is a multiple of the signature, including step 0. */
bool gateOpen(uint64_t signature, uint64_t step);

/* +1 before the 2π flip, -1 until the 4π return, +1 at multiples of period. */
int spinorSign(int step, int period, int flip_at);

/* Phase p maps onto the PPM alphabet (phase 0 -> first prime). */
int phasePrime(int phase, const std::vector<int>& alphabet);

class TliParser {
public:
    TliParser();

    bool parseFile(const std::string& filename);
    bool parseString(const std::string& source,
                     const std::string& filename = "<string>");

    const TLinguaSystem& system() const { return system_; }
    TLinguaSystem& system() { return system_; }

    /* Check the closed loop, circular distance, prime gates, resonance,
     * and spinor sign-flip.  `steps` <= 0 runs one full declared cycle
     * (at least one step, at most 64). */
    bool verify(int steps = 0);

    /* Source-to-source lowering to the psystems authoring convention. */
    std::string lower() const;

private:
    TLinguaSystem system_;
    std::string filename_;
    int lineNum_;
    std::set<std::string> importStack_;

    struct Stmt {
        std::string text;
        int line;
    };

    bool parseBody(const std::string& source, const std::string& filename);
    bool handleImport(const std::string& text);
    void parseStatement(const Stmt& stmt);
    void parseStatements(const std::string& source, int lineBase);

    void parseModel(const std::string& text, bool temporal);
    void parseClock(const std::string& text);
    void parsePhaseRegister(const std::string& text);
    void parsePrimes(const std::string& text);
    void parseGate(const std::string& text);
    void parseSemantics(const std::string& text);
    void parseFractal(const std::string& text);
    void parseSpinor(const std::string& text);
    void parseModule(const std::string& text);
    void parseMu(const std::string& text);
    void parseInit(const std::string& text);
    void parseRule(const std::string& text);
    void parseGuards(const std::string& tail, Rule& rule);

    void addError(const std::string& msg);
    void addWarning(const std::string& msg);

    static std::string trim(const std::string& s);
    static std::string stripComments(const std::string& src);
    static std::vector<Stmt> splitStatements(const std::string& src);
    static bool startsWith(const std::string& s, const std::string& pfx);
    static std::string blockBody(const std::string& text);
};

} // namespace tlingua
} // namespace plingua

#endif // _TLI_PARSER_HPP_
