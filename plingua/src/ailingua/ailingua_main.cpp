/*
 * ailingua_main.cpp
 *
 * Reference runner for Ai-Lingua (.ali).
 *
 * Usage:
 *   ailingua input.ali [-o output.json] [-s steps] [-v]
 *
 * Copyright (C) 2026  P-Lingua/Ai-Lingua Contributors
 * Licensed under GPL-3.0
 */

#include <ailingua/ai_engine.hpp>
#include <ailingua/ali_parser.hpp>

#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>

static void printUsage(const char* prog) {
    std::cerr
        << "Ai-Lingua — cognitive time-crystal runner\n"
        << "Usage: " << prog << " <input.ali> [options]\n"
        << "\nOptions:\n"
        << "  -o <file>    Output JSON report (default: stdout)\n"
        << "  -s <steps>   Run N cognitive cycles (default: 0)\n"
        << "  -v           Verbose output\n"
        << "  -h           Show this help\n"
        << "\nExample:\n"
        << "  " << prog << " cognitive_cycle.ali -o report.json -s 11\n";
}

int main(int argc, char* argv[]) {
    if (argc < 2) { printUsage(argv[0]); return 1; }

    std::string inputFile;
    std::string outputFile;
    int steps = 0;
    bool verbose = false;

    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "-h") == 0 || std::strcmp(argv[i], "--help") == 0) {
            printUsage(argv[0]);
            return 0;
        } else if (std::strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            outputFile = argv[++i];
        } else if (std::strcmp(argv[i], "-s") == 0 && i + 1 < argc) {
            steps = std::atoi(argv[++i]);
        } else if (std::strcmp(argv[i], "-v") == 0) {
            verbose = true;
        } else if (argv[i][0] != '-') {
            inputFile = argv[i];
        } else {
            std::cerr << "Unknown option: " << argv[i] << "\n";
            return 1;
        }
    }

    if (inputFile.empty()) {
        std::cerr << "Error: no input file specified\n";
        printUsage(argv[0]);
        return 1;
    }
    if (steps < 0) steps = 0;

    plingua::ailingua::AliParser parser;
    if (!parser.parseFile(inputFile)) {
        std::cerr << "Parse errors in " << inputFile << ":\n";
        for (size_t i = 0; i < parser.system().errors.size(); ++i)
            std::cerr << "  " << parser.system().errors[i] << "\n";
        return 1;
    }
    for (size_t i = 0; i < parser.system().warnings.size(); ++i)
        std::cerr << "  " << parser.system().warnings[i] << "\n";

    plingua::ailingua::AiEngine engine(parser.system());
    if (!engine.ok()) {
        std::cerr << "Engine errors:\n";
        for (size_t i = 0; i < engine.errors().size(); ++i)
            std::cerr << "  " << engine.errors()[i] << "\n";
        return 1;
    }

    if (verbose) {
        const plingua::ailingua::AiLinguaSystem& sys = parser.system();
        std::cerr << "Ai-Lingua compilation successful:\n"
                  << "  Model type: " << sys.model_type << "\n"
                  << "  Membranes:  " << sys.membranes.size() << "\n"
                  << "  Objects:    " << sys.objects.size() << "\n"
                  << "  Rules:      " << sys.rules.size() << "\n"
                  << "  Period:     " << sys.clock.period << "\n"
                  << "  Imports: " << sys.imports.size() << "\n";
        for (size_t i = 0; i < sys.imports.size(); ++i) {
            const plingua::ImportedModule& im = sys.imports[i];
            std::cerr << "  import " << im.dialect << " " << im.path
                      << (im.inlined ? " (inlined)" : " (companion)")
                      << " symbols=" << im.symbols.size() << "\n";
        }
    }

    const int sample = parser.system().observe.sample_period > 0
                           ? parser.system().observe.sample_period : 1;
    for (int step = 0; step < steps; ++step) {
        plingua::ailingua::CycleSnapshot snap = engine.step();
        if (verbose && ((step + 1) % sample == 0)) {
            std::cerr << "  step " << (step + 1)
                      << " | phase=" << snap.phase
                      << " | grip_index=" << std::fixed << std::setprecision(4) << snap.grip_index
                      << " | emergence=" << snap.emergence_score
                      << " | fired=" << snap.rules_fired
                      << " | af=" << snap.af_size
                      << "\n";
        }
    }

    std::string report = engine.reportJson(steps);
    if (outputFile.empty()) {
        std::cout << report;
    } else {
        std::ofstream ofs(outputFile.c_str());
        if (!ofs.is_open()) {
            std::cerr << "Cannot open output file: " << outputFile << "\n";
            return 1;
        }
        ofs << report;
        if (verbose) std::cerr << "Report written to " << outputFile << "\n";
    }
    return 0;
}
