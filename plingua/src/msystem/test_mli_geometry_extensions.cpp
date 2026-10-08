#include <iostream>
#include <fstream>
#include <string>
#include <sys/stat.h>
#include <unistd.h>
#include <msystem/mli_parser.hpp>

using namespace plingua::msystem;

namespace {
	int tests_run = 0;
	int tests_passed = 0;

	void expect(bool condition, const std::string& message) {
		++tests_run;
		if (condition) {
			++tests_passed;
			std::cout << "[PASS] " << message << "\n";
		} else {
			std::cout << "[FAIL] " << message << "\n";
		}
	}
}

int main() {
	const std::string src = R"(
@msystem<morphogenetic>
@geometry<projective>;
@manifold sphere(dimension=2, compact=true, charts=8);
@metric g(signature=+++, type=riemannian);
@connection nabla(bundle=tangent, type=levi_civita);
@capability gauge_invariance;
@flow rf(iterations=25, preserve_volume=true, type=discrete_ricci, step=0.02);
@polytope c120(cells=120, edges=1200, faces=720, vertices=600, dimension=4, symmetry=H4);

@tiling {
    @glue g1;
    @tile d(sides=4, radius=1.0) {
        @connector c1(vertices=[v1,v2], glue=g1, angle=90);
    }
    @seed d at (0,0,0);
}
)";

	MliParser parser;
	bool ok = parser.parseString(src, "<test>");
	expect(ok, "parser accepts geometry extension syntax");

	const MSystem& sys = parser.system();
	expect(sys.geometryProfileLabel == "projective", "geometry profile parsed");
	expect(sys.manifolds.size() == 1 && sys.manifolds[0].compact, "manifold parsed");
	expect(sys.metrics.size() == 1 && sys.metrics[0].signature == "+++", "metric parsed");
	expect(sys.connections.size() == 1 && sys.connections[0].bundle == "tangent", "connection parsed");
	expect(sys.capabilities.size() == 1 && sys.capabilities[0] == "gauge_invariance", "capability parsed");
	expect(sys.flows.size() == 1 && sys.flows[0].iterations == 25, "flow parsed");
	expect(sys.polytopes.size() == 1 && sys.polytopes[0].incidenceCounts.at("cells") == 120, "polytope parsed");

	// @import: same-dialect inline, cross-dialect record, diamond, cycle, missing.
	std::string dir = "/tmp/nanocyc_mli_" + std::to_string(static_cast<long>(getpid()));
	mkdir(dir.c_str(), 0755);
	std::string libPath = dir + "/lib.mli";
	std::string hostPath = dir + "/host.mli";
	std::string pliPath = dir + "/companion.pli";
	std::string cycleA = dir + "/cycle_a.mli";
	std::string cycleB = dir + "/cycle_b.mli";

	{
		std::ofstream out(libPath.c_str());
		out << "@msystem<morphogenetic>\n"
		    << "@tiling {\n"
		    << "  @glue g_lib;\n"
		    << "  @tile lib_tile(sides=4, radius=1.0) {\n"
		    << "    @connector c1(vertices=[v1,v2], glue=g_lib, angle=90);\n"
		    << "  }\n"
		    << "}\n";
	}
	{
		std::ofstream out(pliPath.c_str());
		out << "@model<psystems_basic>\n"
		    << "@mu = [ []'assembly ]'skin;\n"
		    << "[ edge --> locked ]'assembly;\n";
	}
	{
		std::ofstream out(hostPath.c_str());
		out << "@import \"" << libPath << "\";\n"
		    << "@import \"./lib.mli\";\n"
		    << "@import \"companion.pli\";\n"
		    << "@msystem<morphogenetic>\n"
		    << "@tiling {\n"
		    << "  @glue g_host;\n"
		    << "  @tile host_tile(sides=3, radius=2.0) {\n"
		    << "    @connector c1(vertices=[v1,v2], glue=g_host, angle=60);\n"
		    << "  }\n"
		    << "}\n"
		    << "def main() {\n  a --> b;\n}\n";
	}

	MliParser imported;
	bool importOk = imported.parseFile(hostPath);
	expect(importOk, "@import host parses");
	const MSystem& isys = imported.system();
	expect(isys.tiling.tiles.size() == 2, "same-dialect @import inlines the library tile once");
	bool sawLib = false, sawHost = false;
	for (size_t i = 0; i < isys.tiling.tiles.size(); ++i) {
		if (isys.tiling.tiles[i].name == "lib_tile") sawLib = true;
		if (isys.tiling.tiles[i].name == "host_tile") sawHost = true;
	}
	expect(sawLib && sawHost, "host and library tiles both present");
	expect(isys.imports.size() == 2, "diamond skip keeps one .mli import plus the .pli companion");
	bool sawPli = false, pliInlined = true, pliHasSkin = false;
	for (size_t i = 0; i < isys.imports.size(); ++i) {
		if (isys.imports[i].dialect == "pli") {
			sawPli = true;
			pliInlined = isys.imports[i].inlined;
			for (size_t s = 0; s < isys.imports[i].symbols.size(); ++s) {
				if (isys.imports[i].symbols[s] == "skin") pliHasSkin = true;
			}
		}
		if (isys.imports[i].dialect == "mli") {
			expect(isys.imports[i].inlined, ".mli import is inlined");
		}
	}
	expect(sawPli && !pliInlined && pliHasSkin, ".pli companion is recorded, not inlined, with @mu labels");
	expect(isys.rules.size() == 1, ".pli rules are not misread as metabolic rules");

	{
		std::ofstream out(cycleA.c_str());
		out << "@import \"cycle_b.mli\";\n@msystem<morphogenetic>\n";
	}
	{
		std::ofstream out(cycleB.c_str());
		out << "@import \"cycle_a.mli\";\n@msystem<morphogenetic>\n";
	}
	MliParser cycled;
	expect(!cycled.parseFile(cycleA), "import cycle is an error");
	expect(!cycled.errors().empty(), "cycle reports an error");

	MliParser missing;
	expect(!missing.parseString("@import \"/tmp/nanocyc_missing_import.mli\";\n@msystem<morphogenetic>\n",
	                            "/tmp/nanocyc_missing_host.mli"),
	       "missing import is an error");
	MliParser malformed;
	expect(!malformed.parseString("@import foo;\n@msystem<morphogenetic>\n", "<string>"),
	       "malformed @import is an error");

	std::cout << "\nResults: " << tests_passed << "/" << tests_run << " passed.\n";
	return (tests_passed == tests_run) ? 0 : 1;
}
