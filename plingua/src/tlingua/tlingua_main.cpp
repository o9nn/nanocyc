/*
 * tlingua_main.cpp
 *
 * T-Lingua compiler.  Parses a .tli model, verifies the closed time loop,
 * circular phase distance, prime gating, and resonance exchange, and can
 * lower the model to plain P-Lingua.
 *
 * Usage:
 *   tlingua input.tli [-o report.json] [-l output.pli] [-s steps] [-v]
 *
 * Copyright (C) 2026  P-Lingua/T-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <tlingua/tli_parser.hpp>

static void printUsage(const char* prog) {
    std::cerr
        << "T-Lingua Compiler — temporal/tensor P systems\n"
        << "Usage: " << prog << " <input.tli> [options]\n"
        << "\nOptions:\n"
        << "  -o <file>    JSON verification report (default: stdout)\n"
        << "  -l <file>    Lower to P-Lingua (.pli)\n"
        << "  -s <steps>   Simulate N steps (default: one declared cycle)\n"
        << "  -v           Verbose verification summary\n"
        << "  -h           Show this help\n"
        << "\nExample:\n"
        << "  " << prog << " time_crystal_neuron.tli -s 11 -v -o report.json\n";
}

static std::string jsonString(const std::string& s) {
    std::string out = "\"";
    for (size_t i = 0; i < s.size(); ++i) {
        char c = s[i];
        if (c == '\\' || c == '"') {
            out += '\\';
            out += c;
        } else if (c == '\n') {
            out += "\\n";
        } else {
            out += c;
        }
    }
    out += '"';
    return out;
}

static std::string yesNo(bool v) { return v ? "true" : "false"; }

static std::string reportJson(const plingua::tlingua::TLinguaSystem& sys) {
    const plingua::tlingua::Verification& v = sys.verification;
    std::ostringstream j;
    j << "{\n";
    j << "  \"model\": " << jsonString(sys.model_type) << ",\n";
    j << "  \"semantics\": "
      << jsonString(sys.semantics == plingua::tlingua::SEM_DAEMON ? "daemon"
                                                                  : "angel")
      << ",\n";
    j << "  \"clocks\": " << sys.clocks.size() << ",\n";
    j << "  \"phase_registers\": " << sys.registers.size() << ",\n";
    j << "  \"primes\": " << sys.primes.size() << ",\n";
    j << "  \"gates\": " << sys.gates.size() << ",\n";
    j << "  \"rules\": " << sys.rules.size() << ",\n";
    j << "  \"spinors\": " << sys.spinors.size() << ",\n";
    j << "  \"fractal\": " << yesNo(sys.fractal.present) << ",\n";
    j << "  \"imports\": " << sys.imports.size() << ",\n";
    j << "  \"steps_run\": " << sys.steps_run << ",\n";
    j << "  \"exchanged\": " << sys.exchanged << ",\n";
    j << "  \"dissipated\": " << sys.dissipated << ",\n";
    j << "  \"verification\": {\n";
    j << "    \"ok\": " << yesNo(v.ok) << ",\n";
    j << "    \"eleven_cycle\": " << yesNo(v.eleven_cycle) << ",\n";
    j << "    \"closed_loop\": " << yesNo(v.closed_loop) << ",\n";
    j << "    \"circular_phase_distance\": " << yesNo(v.circular_phase_distance)
      << ",\n";
    j << "    \"prime_gating\": " << yesNo(v.prime_gating) << ",\n";
    j << "    \"resonance_exchange\": " << yesNo(v.resonance_exchange) << ",\n";
    j << "    \"spinor_flip\": " << yesNo(v.spinor_flip) << "\n";
    j << "  },\n";
    j << "  \"failures\": [";
    for (size_t i = 0; i < v.failures.size(); ++i) {
        if (i) j << ", ";
        j << jsonString(v.failures[i]);
    }
    j << "],\n";
    j << "  \"warnings\": [";
    for (size_t i = 0; i < sys.warnings.size(); ++i) {
        if (i) j << ", ";
        j << jsonString(sys.warnings[i]);
    }
    j << "]\n";
    j << "}\n";
    return j.str();
}

static void printVerbose(const plingua::tlingua::TLinguaSystem& sys) {
    const plingua::tlingua::Verification& v = sys.verification;
    std::cerr << "T-Lingua compilation successful:\n"
              << "  Model type: " << sys.model_type << "\n"
              << "  Semantics: "
              << (sys.semantics == plingua::tlingua::SEM_DAEMON ? "daemon"
                                                                : "angel")
              << "\n"
              << "  Clocks: " << sys.clocks.size() << "\n"
              << "  Phase registers: " << sys.registers.size() << "\n"
              << "  Primes: " << sys.primes.size() << "\n"
              << "  Gates: " << sys.gates.size() << "\n"
              << "  Rules: " << sys.rules.size() << "\n"
              << "  Spinors: " << sys.spinors.size() << "\n"
              << "  Fractal: " << (sys.fractal.present ? "yes" : "no") << "\n"
              << "  Imports: " << sys.imports.size() << "\n"
              << "  Eleven-cycle: " << (v.eleven_cycle ? "yes" : "no") << "\n"
              << "  Closed loop: " << (v.closed_loop ? "yes" : "no") << "\n"
              << "  Circular phase distance: "
              << (v.circular_phase_distance ? "yes" : "no") << "\n"
              << "  Prime gating: " << (v.prime_gating ? "yes" : "no") << "\n"
              << "  Resonance exchange: "
              << (v.resonance_exchange ? "yes" : "no") << "\n"
              << "  Spinor flip: " << (v.spinor_flip ? "yes" : "no") << "\n"
              << "  Steps: " << sys.steps_run << "\n";
    for (size_t i = 0; i < sys.imports.size(); ++i) {
        const plingua::ImportedModule& im = sys.imports[i];
        std::cerr << "  import " << im.dialect << " " << im.path
                  << (im.inlined ? " (inlined)" : " (companion)")
                  << " symbols=" << im.symbols.size() << "\n";
    }
    for (size_t i = 0; i < v.notes.size(); ++i)
        std::cerr << "  note: " << v.notes[i] << "\n";
    for (size_t i = 0; i < sys.warnings.size(); ++i)
        std::cerr << "  " << sys.warnings[i] << "\n";
    for (size_t i = 0; i < v.failures.size(); ++i)
        std::cerr << "  FAIL: " << v.failures[i] << "\n";
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printUsage(argv[0]);
        return 2;
    }

    std::string inputFile;
    std::string outputFile;
    std::string lowerFile;
    int steps = 0;
    bool verbose = false;

    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "-h") == 0 || std::strcmp(argv[i], "--help") == 0) {
            printUsage(argv[0]);
            return 0;
        } else if (std::strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            outputFile = argv[++i];
        } else if (std::strcmp(argv[i], "-l") == 0 && i + 1 < argc) {
            lowerFile = argv[++i];
        } else if (std::strcmp(argv[i], "-s") == 0 && i + 1 < argc) {
            steps = std::atoi(argv[++i]);
        } else if (std::strcmp(argv[i], "-v") == 0) {
            verbose = true;
        } else if (argv[i][0] != '-') {
            inputFile = argv[i];
        } else {
            std::cerr << "Unknown option: " << argv[i] << "\n";
            return 2;
        }
    }

    if (inputFile.empty()) {
        std::cerr << "Error: no input file specified\n";
        printUsage(argv[0]);
        return 2;
    }

    plingua::tlingua::TliParser parser;
    if (!parser.parseFile(inputFile)) {
        std::cerr << "Parse errors in " << inputFile << ":\n";
        for (size_t i = 0; i < parser.system().errors.size(); ++i)
            std::cerr << "  " << parser.system().errors[i] << "\n";
        return 1;
    }

    bool ok = parser.verify(steps);
    if (verbose) printVerbose(parser.system());
    for (size_t i = 0; i < parser.system().warnings.size() && !verbose; ++i)
        std::cerr << parser.system().warnings[i] << "\n";

    if (!lowerFile.empty()) {
        std::ofstream out(lowerFile.c_str());
        if (!out) {
            std::cerr << "Cannot write " << lowerFile << "\n";
            return 1;
        }
        out << parser.lower();
    }

    std::string report = reportJson(parser.system());
    if (outputFile.empty()) {
        std::cout << report;
    } else if (outputFile != "/dev/null") {
        std::ofstream out(outputFile.c_str());
        if (!out) {
            std::cerr << "Cannot write " << outputFile << "\n";
            return 1;
        }
        out << report;
    }

    if (!ok) {
        if (!verbose) {
            for (size_t i = 0; i < parser.system().verification.failures.size(); ++i)
                std::cerr << "FAIL: " << parser.system().verification.failures[i]
                          << "\n";
        }
        return 1;
    }
    return 0;
}
