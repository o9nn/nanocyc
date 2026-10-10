#ifndef _SIMULATOR_HPP_
#define _SIMULATOR_HPP_

#include <vector>
#include <algorithm>
#include <cmath>
#include <map>
#include <queue>
#include <limits>
#include <sstream>
#include <functional>
#include <cctype>
#include <cstdlib>
#include <sys/ioctl.h>
#include <unistd.h>
#include <simulator/command_line.hpp>
#include <simulator/shuffler.hpp>
#include <serialization.hpp>


namespace plingua { namespace simulator {

class SelectedRule
{
public:
	SelectedRule(unsigned membraneId, const Rule& rule, std::size_t applications)
	: membraneId(membraneId), rule(rule), applications(applications) {}
	unsigned membraneId;
	const Rule& rule;
	std::size_t applications;
};



class Simulator : public CommandLine
{
public: 	
	Simulator() : finished(false), initialTime(0) {}
	virtual ~Simulator() {}
	void step();
	virtual bool parse(int argc, char *argv[]);
	const Configuration& getCurrentConfiguration() const {return configuration;}
	const File& getFile() const {return file;}
	bool ok() const {return !finished;}
	// Halting summary for the active trace mode. No-op when tracing is off.
	void traceHalt() const;

protected:

	virtual void selectRules();
	virtual void executeRules();

	// --- s-expr tracing (the "wire"/"checkpoint" streams) -------------------
	// Emit the run header once: (seed <n>) (steps <n>) (model "<file>").
	void traceHeader() const;
	// Emit one (fired (step k) (membrane id) (rule r) (consumed ms)
	//           (produced ms)) event per selected rule application.
	void traceStepEvents() const;
	// Build the wire lines without printing (shared by sexpr and human modes).
	std::vector<std::string> stepEventLines() const;
	// Emit (checkpoint (step k) (membrane id (label l) (objects ((o . n)..))..)).
	void traceCheckpoint() const;
	// Emit the three-pane human layout: --glyph / --wire / --checkpoint.
	void traceHumanStep(const std::vector<std::string>& wireLines) const;
	// One JSON object for this step's fired events (MeCoSim-style stream).
	void traceStepJson() const;
	void traceCheckpointJson() const;
	// Render the membrane tree as box-drawing art, one line per row.
	std::vector<std::string> glyphLines() const;
	// Serialise a multiset as ((sym . n) ...) sorted by symbol name.
	static std::string multisetToSexpr(const Multiset& ms);
	// true when a checkpoint s-expr/JSON object should be emitted this step.
	bool checkpointDue() const;
	// Pure d1..d11 nest (each membrane one child, d11 a leaf). phase is the
	// deepest index (1..11) whose multiset is non-empty, or 0 if all empty.
	bool isPurePhaseNest(unsigned id, int& phase) const;
	std::string collapsedPhaseNote(int phase) const;
	std::string configurationFingerprint() const;
	static unsigned terminalColumns();
	static std::string ruleTraceName(const Rule& rule, std::size_t index);
	static std::string jsonEscape(const std::string& s);
	static std::string multisetToJson(const Multiset& ms);
	// T-Lingua wire annotations. Extra events only; they do not change firing.
	static std::string featureString(const Features& features, const char* key);
	static bool parsePhaseIndex(const std::string& label, int& n);
	static int phaseOfLabel(const std::string& label);
	static bool onlyClockObjects(const Multiset& ms);
	static std::string normalizeMatch(const std::string& raw);
	const char* phaseArrow() const;
	bool collectPhaseChain(unsigned id, std::vector<unsigned>& chain) const;
	std::string collapsedPhaseGlyph(const std::vector<unsigned>& chain) const;
	void appendTraceAtoms(std::vector<std::string>& sexprOut,
	                      std::vector<std::string>& jsonOut,
	                      unsigned membraneId,
	                      const Rule& rule) const;
	

private:
	std::size_t getMaxApplications(const CMembrane& membrane, const Rule& rule) const;	
	void consume(CMembrane& membrane, const Rule& rule, std::size_t applications);	
	
	bool updateSemantics(Semantics& semantics, const std::string& pattern, std::size_t applications);
	void produce(unsigned membraneId, const Rule& rule, std::size_t applications, std::set<unsigned>& dissolving);
	void produce(unsigned membraneId, const OMembrane& lhrMembrane, const OMembrane& om, std::size_t applications, std::set<unsigned>& dissolving);
	
	std::size_t getMaxApplications(const Semantics& semantics, const std::string& pattern) const;
	
	// count the times that ms0 is contained in ms1
	static std::size_t count(const Multiset& ms0, const Multiset& ms1); 
	
	// ms0 = ms0 - ms1 * times
	static void sub(Multiset& ms0, const Multiset& ms1, std::size_t times);
	
	// ms0 = ms0 + ms1 * times
	static void add(Multiset& ms0, const Multiset& ms1, std::size_t times);
	
	static bool ruleSupported(const Rule& rule);
	
	static bool ruleSupportedArrow0(const Rule& rule);
		
	static bool ruleSupportedArrow1(const Rule& rule);
	
	void initConfigurationRec(const Membrane& membrane, int parent);
	
	unsigned copyMembrane(unsigned membraneId);
		
	std::map<Label, std::map<char, std::vector<Rule>>> ruleSets;
	
		
	std::map<unsigned, std::map<unsigned,std::size_t>> selectedRules;
	std::vector<std::string> pendingWireLines; // stashed for human/diff panes
	mutable std::string lastTraceFingerprint; // previous checkpoint, for --trace=diff
	std::queue<unsigned> freeIndexes;	
	Configuration configuration;
	File file;
	bool finished;
	unsigned long initialTime;
	
};	

///////////////////////////////////////////////////////////


inline
void Simulator::step()
{

	selectRules();
	executeRules();
	finished = selectedRules.empty() ||
				(getMaxStepsToSimulate()>0 && (configuration.time - initialTime) >= getMaxStepsToSimulate());
}

// ---------------------------------------------------------------------------
// s-expr tracing.  The "wire" stream is one parenthesised event per line — the
// same canonical format the Lisp s-expr kernel (plingua/lang/scm) emits, so
// traces can be diffed across engines.  "checkpoint" lines carry the full
// configuration as a readable s-expr.
// ---------------------------------------------------------------------------

inline
std::string Simulator::multisetToSexpr(const Multiset& ms)
{
	std::ostringstream os;
	os << "(";
	bool first = true;
	for (const auto& kv : ms) {
		if (kv.second.raw() == 0) continue;
		if (!first) os << " ";
		os << "(" << kv.first.str() << " . " << kv.second.raw() << ")";
		first = false;
	}
	os << ")";
	return os.str();
}

inline
void Simulator::traceHeader() const
{
	unsigned seed = hasSeed() ? getSeed() : RANDOM.getSeed();
	if (getTraceMode() == "json") {
		std::ostringstream os;
		os << "{\"event\":\"header\",\"seed\":" << seed;
		if (getMaxStepsToSimulate() > 0) os << ",\"steps\":" << getMaxStepsToSimulate();
		os << ",\"model\":\"" << jsonEscape(getInputFile()) << "\"}";
		std::cout << os.str() << "\n";
		return;
	}
	std::ostringstream os;
	os << "(seed " << seed << ")";
	if (getMaxStepsToSimulate() > 0) os << " (steps " << getMaxStepsToSimulate() << ")";
	os << " (model \"" << getInputFile() << "\")";
	std::cout << os.str() << "\n";
}

inline
void Simulator::traceHalt() const
{
	if (getTraceMode() == "off") return;
	unsigned long t = configuration.time;
	bool hitMax = getMaxStepsToSimulate() > 0 && t >= getMaxStepsToSimulate();
	const char* reason = hitMax ? "max-steps" : "no-applicable-rules";
	if (getTraceMode() == "json") {
		std::cout << "{\"event\":\"halted\",\"steps\":" << t
		          << ",\"reason\":\"" << reason << "\"}\n";
		return;
	}
	std::cout << "(halted (steps " << t << ") (reason " << reason << "))\n";
}

inline
std::vector<std::string> Simulator::stepEventLines() const
{
	std::vector<std::string> lines;
	// configuration.time has NOT yet been incremented for this step's events
	for (auto it1 = selectedRules.begin(); it1 != selectedRules.end(); ++it1) {
		const CMembrane& m = configuration.membranes[it1->first];
		const std::vector<Rule>& rules = ruleSets.at(m.label).at(m.charge);
		for (auto it2 = it1->second.begin(); it2 != it1->second.end(); ++it2) {
			const Rule& r = rules[it2->first];
			std::size_t n = it2->second;
			// consumed = objects taken from THIS membrane = the union of the
			// rule's local multiset (lhr.multiset) and its home-membrane
			// multiset (lhr.membrane.multiset), scaled by applications.
			Multiset consumed;
			for (const auto& kv : r.lhr.multiset)
				consumed[kv.first] += kv.second.raw() * n;
			for (const auto& kv : r.lhr.membrane.multiset)
				consumed[kv.first] += kv.second.raw() * n;
			// produced: in this grammar the home membrane is rhr.data[0]; its
			// multiset is the "here" product, and its nested children are the
			// send-in targets, reported as ((ms) (in <label>)).
			Multiset produced;
			std::ostringstream prod;
			if (!r.rhr.data.empty()) {
				const OMembrane& home = r.rhr.data[0];
				for (const auto& kv : home.multiset)
					produced[kv.first] += kv.second.raw() * n;
				for (const auto& child : home.data) {
					Multiset inner;
					for (const auto& kv : child.multiset)
						inner[kv.first] += kv.second.raw() * n;
					prod << (produced.empty() ? "" : " ")
					     << "(" << multisetToSexpr(inner)
					     << " (in " << (child.label.empty() ? "?" : child.label[0].str())
					     << "))";
				}
			}
			// also account for any rhr.multiset (defensive; usually empty here)
			for (const auto& kv : r.rhr.multiset)
				produced[kv.first] += kv.second.raw() * n;
			std::ostringstream prodAll;
			prodAll << multisetToSexpr(produced);
			if (!prod.str().empty()) prodAll << prod.str();
			std::ostringstream line;
			line << "(fired (step " << configuration.time << ")"
			     << " (membrane " << it1->first << ")"
			     << " (rule " << ruleTraceName(r, it2->first) << ")"
			     << " (consumed " << multisetToSexpr(consumed) << ")"
			     << " (produced " << prodAll.str() << ")"
			     << (n > 1 ? " (applications " : "")
			     << (n > 1 ? std::to_string(n) : "")
			     << (n > 1 ? ")" : "")
			     << ")";
			lines.push_back(line.str());
			std::vector<std::string> jsonAtoms;
			appendTraceAtoms(lines, jsonAtoms, it1->first, r);
		}
	}
	return lines;
}

inline
void Simulator::traceStepEvents() const
{
	if (getTraceMode() == "human") return; // human mode draws its own panes
	for (const auto& l : stepEventLines()) std::cout << l << "\n";
}

// Render the membrane tree as box-drawing art (one row per line).
// A pure d1..d11 time-crystal nest collapses to one row unless --expand.
inline
std::vector<std::string> Simulator::glyphLines() const
{
	const bool uni = isUnicode();
	const char* tl = uni ? "\u256D" : "+";   // top-left
	const char* bl = uni ? "\u2570" : "+";   // bottom-left
	const char* tr = uni ? "\u256E" : "+";   // top-right
	const char* br = uni ? "\u256F" : "+";   // bottom-right
	const char* hz = uni ? "\u2500" : "-";   // horizontal
	const char* vt = uni ? "\u2502" : "|";   // vertical

	std::vector<std::string> out;
	// recursive lambda over children of the skin (parent == -1)
	std::function<void(unsigned, int)> render = [&](unsigned id, int depth) {
		const CMembrane& m = configuration.membranes[id];
		if (m.parent == -2) return; // dissolved
		std::string indent(depth * 2, ' ');
		std::ostringstream label;
		label << "[" << id << "]" << (m.label.empty() ? "" : m.label[0].str());
		// objects inline, e.g. "b b b"
		std::ostringstream objs;
		for (const auto& kv : m.multiset)
			for (std::size_t k = 0; k < kv.second.raw(); k++)
				objs << kv.first.str() << " ";
		std::string width = label.str();
		std::string rule;
		for (std::size_t i = 0; i < width.size() + 2; i++) rule += hz;
		out.push_back(indent + tl + rule + tr);
		out.push_back(indent + vt + " " + width + " " + vt + "  " + objs.str());
		for (int c : m.children) {
			int phase = 0;
			std::vector<unsigned> phaseChain;
			if (!expandNests() && c >= 0 &&
			    isPurePhaseNest(static_cast<unsigned>(c), phase)) {
				out.push_back(indent + vt + " " + collapsedPhaseNote(phase) + " " + vt);
			} else if (!expandNests() && c >= 0 &&
			           collectPhaseChain(static_cast<unsigned>(c), phaseChain)) {
				// Shorter clock rings (d1..dN, N>=3) collapse to one row.
				// An 11-deep nest uses collapsedPhaseNote above.
				out.push_back(indent + vt + " " + collapsedPhaseGlyph(phaseChain) + " " + vt);
			} else {
				render(static_cast<unsigned>(c), depth + 1);
			}
		}
		out.push_back(indent + bl + rule + br);
	};
	for (std::size_t i = 0; i < configuration.membranes.size(); i++) {
		if (configuration.membranes[i].parent != -1) continue;
		int phase = 0;
		std::vector<unsigned> phaseChain;
		if (!expandNests() && isPurePhaseNest(static_cast<unsigned>(i), phase)) {
			out.push_back(collapsedPhaseNote(phase));
		} else if (!expandNests() && collectPhaseChain(static_cast<unsigned>(i), phaseChain)) {
			out.push_back(collapsedPhaseGlyph(phaseChain));
		} else {
			render(static_cast<unsigned>(i), 0);
		}
	}
	return out;
}

// Three-pane human layout: --glyph / --wire / --checkpoint.
// Side by side at >= 120 columns; stacked (glyph, then wire, then checkpoint)
// below that. Width is read once per step (COLUMNS, else the tty size).
// --trace=diff redraws the panes only when the multiset or membrane tree
// changes; the wire lines are still emitted so the event stream stays complete.
inline
void Simulator::traceHumanStep(const std::vector<std::string>& wireLines) const
{
	if (getTraceMode() == "diff") {
		std::string fp = configurationFingerprint();
		if (!lastTraceFingerprint.empty() && fp == lastTraceFingerprint) {
			for (const auto& l : wireLines) std::cout << l << "\n";
			std::cout << "(unchanged (step " << configuration.time << "))\n";
			return;
		}
		lastTraceFingerprint = fp;
	}

	std::vector<std::string> glyph = glyphLines();

	// checkpoint text (reuse the s-expr but split into short lines).
	// High verbosity (-v 2+) emits it every step; otherwise every N steps.
	std::vector<std::string> check;
	if (checkpointDue()) {
		std::ostringstream cp;
		cp << "(checkpoint (step " << configuration.time << ")";
		for (std::size_t i = 0; i < configuration.membranes.size(); i++) {
			const CMembrane& m = configuration.membranes[i];
			if (m.parent == -2) continue;
			cp << "\n  (membrane " << i
			   << " (label " << (m.label.empty() ? "?" : m.label[0].str()) << ")"
			   << " (objects " << multisetToSexpr(m.multiset) << "))";
		}
		cp << ")";
		std::istringstream is(cp.str());
		std::string l;
		while (std::getline(is, l)) check.push_back(l);
	} else {
		unsigned every = getCheckpointEvery() == 0 ? 1 : getCheckpointEvery();
		unsigned long next = configuration.time + (every - (configuration.time % every));
		std::ostringstream cp;
		cp << "(checkpoint (step " << configuration.time << ") (deferred until " << next << "))";
		check.push_back(cp.str());
	}

	const unsigned cols = terminalColumns();
	const bool stack = cols < 120;
	const std::size_t GW = 34, WW = 50; // column widths

	// wrap a long line to width w, indenting continuation lines by 2
	auto wrap = [](const std::string& s, std::size_t w) {
		std::vector<std::string> out;
		if (w < 4) w = 4;
		std::string cur;
		std::istringstream is(s);
		std::string tok;
		while (is >> tok) {
			if (!cur.empty() && cur.size() + 1 + tok.size() > w) {
				out.push_back(cur); cur = "  " + tok;
			} else {
				cur += (cur.empty() ? "" : " ") + tok;
			}
		}
		if (!cur.empty()) out.push_back(cur);
		if (out.empty() && !s.empty()) out.push_back(s);
		return out;
	};
	std::size_t wireWidth = stack ? (cols > 2 ? cols - 1 : 78) : (WW - 1);
	std::vector<std::string> wire;
	for (const auto& l : wireLines)
		for (const auto& w : wrap(l, wireWidth)) wire.push_back(w);

	if (stack) {
		std::cout << "--glyph\n";
		for (const auto& g : glyph) std::cout << g << "\n";
		std::cout << "--wire\n";
		for (const auto& w : wire) std::cout << w << "\n";
		std::cout << "--checkpoint\n";
		for (const auto& c : check) std::cout << c << "\n";
		std::cout << "\n";
		return;
	}

	// pad to a *display* width: count UTF-8 code points (box-drawing chars are
	// 3 bytes each but 1 column wide), then right-pad with spaces.
	auto dispWidth = [](const std::string& s) {
		std::size_t n = 0;
		for (unsigned char c : s) if ((c & 0xC0) != 0x80) n++;
		return n;
	};
	auto pad = [&](std::string s, std::size_t w) {
		std::size_t dw = dispWidth(s);
		if (dw < w) s.append(w - dw, ' ');
		return s;
	};

	std::ostringstream hdr;
	hdr << pad("--glyph", GW) << pad("--wire", WW) << "--checkpoint";
	std::cout << hdr.str() << "\n";

	std::size_t rows = std::max(glyph.size(), std::max(wire.size(), check.size()));
	for (std::size_t i = 0; i < rows; i++) {
		std::string g = i < glyph.size() ? glyph[i] : "";
		std::string w = i < wire.size() ? wire[i] : "";
		std::string c = i < check.size() ? check[i] : "";
		std::cout << pad(g, GW) << pad(w, WW) << c << "\n";
	}
	std::cout << "\n";
}

inline
void Simulator::traceCheckpoint() const
{
	std::ostringstream os;
	os << "(checkpoint (step " << configuration.time << ")";
	for (std::size_t i = 0; i < configuration.membranes.size(); i++) {
		const CMembrane& m = configuration.membranes[i];
		if (m.parent == -2) continue; // dissolved
		os << " (membrane " << i
		   << " (label " << (m.label.empty() ? "?" : m.label[0].str()) << ")"
		   << " (parent " << m.parent << ")"
		   << " (objects " << multisetToSexpr(m.multiset) << "))";
	}
	os << ")";
	std::cout << os.str() << "\n";
}

inline
bool Simulator::checkpointDue() const
{
	if (getVerbosityLevel() >= 2) return true;
	unsigned every = getCheckpointEvery() == 0 ? 1 : getCheckpointEvery();
	return configuration.time != 0 && (configuration.time % every) == 0;
}

inline
std::string Simulator::jsonEscape(const std::string& s)
{
	std::string o;
	o.reserve(s.size());
	for (unsigned char c : s) {
		switch (c) {
			case '"': o += "\\\""; break;
			case '\\': o += "\\\\"; break;
			case '\n': o += "\\n"; break;
			case '\r': o += "\\r"; break;
			case '\t': o += "\\t"; break;
			default:
				if (c < 0x20) {
					const char* hex = "0123456789abcdef";
					o += "\\u00";
					o += hex[c >> 4];
					o += hex[c & 0xf];
				} else {
					o += static_cast<char>(c);
				}
		}
	}
	return o;
}

inline
std::string Simulator::multisetToJson(const Multiset& ms)
{
	std::ostringstream os;
	os << "{";
	bool first = true;
	for (const auto& kv : ms) {
		if (kv.second.raw() == 0) continue;
		if (!first) os << ",";
		os << "\"" << jsonEscape(kv.first.str()) << "\":" << kv.second.raw();
		first = false;
	}
	os << "}";
	return os.str();
}

inline
std::string Simulator::ruleTraceName(const Rule& rule, std::size_t index)
{
	static const char* keys[] = {"name", "id", "rule"};
	for (const char* key : keys) {
		auto it = rule.features.find(key);
		if (it == rule.features.end()) continue;
		if (it->second.type() != Value::STRING) continue;
		const char* raw = it->second.as_string();
		if (raw == nullptr || raw[0] == '\0') continue;
		std::string name(raw);
		bool bare = (std::isalpha(static_cast<unsigned char>(name[0])) || name[0] == '_') &&
		            name.find_first_not_of("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_") == std::string::npos;
		if (bare) return name;
		return "\"" + jsonEscape(name) + "\"";
	}
	return "r" + std::to_string(index);
}

inline
unsigned Simulator::terminalColumns()
{
	if (const char* env = std::getenv("COLUMNS")) {
		char* end = nullptr;
		long n = std::strtol(env, &end, 10);
		if (end != env && n > 0 && n < 100000) return static_cast<unsigned>(n);
	}
	struct winsize ws;
	if (::isatty(STDOUT_FILENO) && ::ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0) {
		return ws.ws_col;
	}
	return 80;
}

inline
bool Simulator::isPurePhaseNest(unsigned id, int& phase) const
{
	phase = 0;
	unsigned cur = id;
	for (int i = 1; i <= 11; i++) {
		if (cur >= configuration.membranes.size()) return false;
		const CMembrane& m = configuration.membranes[cur];
		if (m.parent == -2) return false;
		std::string lab = m.label.empty() ? "" : m.label[0].str();
		if (lab != std::string("d") + std::to_string(i)) return false;
		if (!m.multiset.empty()) phase = i;
		if (i < 11) {
			if (m.children.size() != 1) return false;
			if (m.children[0] < 0) return false;
			cur = static_cast<unsigned>(m.children[0]);
		} else if (!m.children.empty()) {
			return false;
		}
	}
	return true;
}

inline
std::string Simulator::collapsedPhaseNote(int phase) const
{
	std::ostringstream os;
	if (isUnicode()) {
		os << "d1\u22EFd11 \u25D4 phase=" << phase;
	} else {
		os << "d1...d11 phase=" << phase;
	}
	return os.str();
}

inline
std::string Simulator::featureString(const Features& features, const char* key)
{
	auto it = features.find(key);
	if (it == features.end() || it->second.type() != Value::STRING) return "";
	const char* raw = it->second.as_string();
	if (raw == nullptr || raw[0] == '\0') return "";
	std::string s(raw);
	if (s.size() >= 2 && s.front() == '"' && s.back() == '"')
		s = s.substr(1, s.size() - 2);
	return s;
}

inline
bool Simulator::parsePhaseIndex(const std::string& label, int& n)
{
	if (label.size() >= 2 && (label[0] == 'd' || label[0] == 'D') &&
	    std::all_of(label.begin() + 1, label.end(),
	                [](unsigned char c) { return std::isdigit(c) != 0; })) {
		n = std::atoi(label.c_str() + 1);
		return n > 0;
	}
	if (label.compare(0, 5, "phase") == 0) {
		std::string rest = label.substr(5);
		if (!rest.empty() && (rest[0] == '{' || rest[0] == '(')) rest.erase(rest.begin());
		if (!rest.empty() && (rest.back() == '}' || rest.back() == ')')) rest.pop_back();
		if (!rest.empty() && std::all_of(rest.begin(), rest.end(),
		        [](unsigned char c) { return std::isdigit(c) != 0; })) {
			n = std::atoi(rest.c_str());
			return true;
		}
	}
	return false;
}

inline
int Simulator::phaseOfLabel(const std::string& label)
{
	int n = -1;
	if (parsePhaseIndex(label, n)) return n;
	if (label == "skin" || label == "rim") return 0;
	return -1;
}

inline
bool Simulator::onlyClockObjects(const Multiset& ms)
{
	for (const auto& kv : ms) {
		if (kv.second.raw() == 0) continue;
		const std::string& name = kv.first.str();
		if (name == "tick" || name.compare(0, 4, "tick") == 0) continue;
		if (name == "singularity_point") continue;
		if (name.compare(0, 5, "phase") == 0) continue;
		if (name.compare(0, 6, "period") == 0) continue;
		if (name.compare(0, 9, "coherence") == 0) continue;
		return false;
	}
	return true;
}

inline
std::string Simulator::normalizeMatch(const std::string& raw)
{
	std::string collapsed;
	bool sp = false;
	for (char c : raw) {
		if (c == ',' || c == ';') c = ' ';
		if (c == ' ' || c == '\t') {
			if (!collapsed.empty()) sp = true;
			continue;
		}
		if (sp) collapsed.push_back(' ');
		sp = false;
		collapsed.push_back(c);
	}
	return collapsed;
}

inline
const char* Simulator::phaseArrow() const
{
	return isUnicode() ? "\u2192" : "->";
}

inline
bool Simulator::collectPhaseChain(unsigned id, std::vector<unsigned>& chain) const
{
	chain.clear();
	if (id >= configuration.membranes.size()) return false;
	int expect = -1;
	unsigned cur = id;
	for (int depth = 0; depth < 64 && cur < configuration.membranes.size(); depth++) {
		const CMembrane& m = configuration.membranes[cur];
		if (m.parent == -2 || m.label.empty()) break;
		int n = 0;
		if (!parsePhaseIndex(m.label[0].str(), n)) break;
		if (expect >= 0 && n != expect) break;
		if (m.children.size() > 1) break;
		if (!onlyClockObjects(m.multiset)) break;
		chain.push_back(cur);
		expect = n + 1;
		if (m.children.empty() || m.children[0] < 0) break;
		unsigned next = static_cast<unsigned>(m.children[0]);
		if (next == cur) break;
		cur = next;
	}
	return chain.size() >= 3;
}

inline
std::string Simulator::collapsedPhaseGlyph(const std::vector<unsigned>& chain) const
{
	const CMembrane& first = configuration.membranes[chain.front()];
	const CMembrane& last = configuration.membranes[chain.back()];
	std::string where = "?";
	std::string objs;
	for (unsigned id : chain) {
		const CMembrane& m = configuration.membranes[id];
		bool hasTick = false;
		for (const auto& kv : m.multiset) {
			if (kv.second.raw() == 0) continue;
			if (kv.first.str() == "tick" || kv.first.str().compare(0, 4, "tick") == 0)
				hasTick = true;
			for (std::size_t k = 0; k < kv.second.raw(); k++)
				objs += kv.first.str() + " ";
		}
		if (hasTick && !m.label.empty()) where = m.label[0].str();
	}
	std::ostringstream os;
	os << "[phase " << first.label[0].str() << ".." << last.label[0].str()
	   << " @" << where;
	if (!objs.empty()) os << " " << objs;
	os << "]";
	return os.str();
}

inline
void Simulator::appendTraceAtoms(std::vector<std::string>& sexprOut,
                                 std::vector<std::string>& jsonOut,
                                 unsigned membraneId,
                                 const Rule& rule) const
{
	if (membraneId >= configuration.membranes.size()) return;
	const CMembrane& m = configuration.membranes[membraneId];
	const std::string selfLabel = m.label.empty() ? "?" : m.label[0].str();
	const std::string ruleName = featureString(rule.features, "name");

	auto sawTick = [](const Multiset& ms) {
		for (const auto& kv : ms) {
			if (kv.second.raw() == 0) continue;
			if (kv.first.str() == "tick" || kv.first.str().compare(0, 4, "tick") == 0)
				return true;
		}
		return false;
	};
	bool movedTick = sawTick(rule.lhr.multiset) || sawTick(rule.lhr.membrane.multiset);
	int tickTo = -1;
	std::string tickToLabel;
	if (!rule.rhr.data.empty()) {
		for (const auto& child : rule.rhr.data[0].data) {
			if (!sawTick(child.multiset)) continue;
			tickToLabel = child.label.empty() ? "?" : child.label[0].str();
			tickTo = phaseOfLabel(tickToLabel);
		}
	}
	int tickFrom = phaseOfLabel(selfLabel);
	if (movedTick && ruleName.find("wrap") != std::string::npos && tickFrom >= 0)
		tickTo = 0;
	if (movedTick && tickFrom >= 0 && tickTo >= 0 && tickTo != tickFrom) {
		std::ostringstream tick;
		tick << "(tick " << configuration.time
		     << " (phase " << tickFrom << phaseArrow() << tickTo << "))";
		sexprOut.push_back(tick.str());
		std::ostringstream jtick;
		jtick << "{\"event\":\"tick\",\"step\":" << configuration.time
		      << ",\"phase_from\":" << tickFrom
		      << ",\"phase_to\":" << tickTo << "}";
		jsonOut.push_back(jtick.str());
	}

	std::string resonance = featureString(rule.features, "resonance");
	if (resonance.empty()) return;
	std::string partner = featureString(rule.features, "partner");
	if (partner.empty()) partner = tickToLabel.empty() ? "?" : tickToLabel;
	std::string match = normalizeMatch(resonance);
	std::ostringstream res;
	res << "(resonance (" << selfLabel << " " << partner
	    << ") (match " << match << "))";
	sexprOut.push_back(res.str());
	std::ostringstream jres;
	jres << "{\"event\":\"resonance\",\"membranes\":[\""
	     << jsonEscape(selfLabel) << "\",\"" << jsonEscape(partner)
	     << "\"],\"match\":[";
	std::istringstream tokens(match);
	std::string tok;
	bool firstTok = true;
	while (tokens >> tok) {
		if (!firstTok) jres << ",";
		bool numeric = !tok.empty() &&
			std::all_of(tok.begin(), tok.end(),
			            [](unsigned char c) { return std::isdigit(c) != 0; });
		if (numeric) jres << tok;
		else jres << "\"" << jsonEscape(tok) << "\"";
		firstTok = false;
	}
	jres << "]}";
	jsonOut.push_back(jres.str());
}

inline
std::string Simulator::configurationFingerprint() const
{
	std::ostringstream os;
	os << "env=" << multisetToSexpr(configuration.environment);
	for (std::size_t i = 0; i < configuration.membranes.size(); i++) {
		const CMembrane& m = configuration.membranes[i];
		if (m.parent == -2) {
			os << " #" << i << "dissolved";
			continue;
		}
		os << " |" << i
		   << " p=" << m.parent
		   << " l=" << (m.label.empty() ? "?" : m.label[0].str())
		   << " c=" << static_cast<int>(m.charge)
		   << " o=" << multisetToSexpr(m.multiset)
		   << " k=";
		for (int c : m.children) os << c << ",";
	}
	return os.str();
}

inline
void Simulator::traceStepJson() const
{
	std::ostringstream os;
	os << "{\"event\":\"step\",\"step\":" << configuration.time << ",\"fired\":[";
	bool first = true;
	for (auto it1 = selectedRules.begin(); it1 != selectedRules.end(); ++it1) {
		const CMembrane& m = configuration.membranes[it1->first];
		const std::vector<Rule>& rules = ruleSets.at(m.label).at(m.charge);
		for (auto it2 = it1->second.begin(); it2 != it1->second.end(); ++it2) {
			const Rule& r = rules[it2->first];
			std::size_t n = it2->second;
			Multiset consumed;
			for (const auto& kv : r.lhr.multiset)
				consumed[kv.first] += kv.second.raw() * n;
			for (const auto& kv : r.lhr.membrane.multiset)
				consumed[kv.first] += kv.second.raw() * n;
			Multiset produced;
			std::ostringstream sent;
			bool sentFirst = true;
			if (!r.rhr.data.empty()) {
				const OMembrane& home = r.rhr.data[0];
				for (const auto& kv : home.multiset)
					produced[kv.first] += kv.second.raw() * n;
				for (const auto& child : home.data) {
					Multiset inner;
					for (const auto& kv : child.multiset)
						inner[kv.first] += kv.second.raw() * n;
					if (!sentFirst) sent << ",";
					sentFirst = false;
					sent << "{\"in\":\""
					     << jsonEscape(child.label.empty() ? "?" : child.label[0].str())
					     << "\",\"objects\":" << multisetToJson(inner) << "}";
				}
			}
			for (const auto& kv : r.rhr.multiset)
				produced[kv.first] += kv.second.raw() * n;
			if (!first) os << ",";
			first = false;
			std::string name = ruleTraceName(r, it2->first);
			bool quoted = !name.empty() && name[0] == '"';
			os << "{\"membrane\":" << it1->first
			   << ",\"rule\":" << (quoted ? name : "\"" + jsonEscape(name) + "\"")
			   << ",\"applications\":" << n
			   << ",\"consumed\":" << multisetToJson(consumed)
			   << ",\"produced\":" << multisetToJson(produced)
			   << ",\"sent\":[" << sent.str() << "]}";
		}
	}
	os << "]}";
	std::cout << os.str() << "\n";
	std::vector<std::string> sexprUnused;
	std::vector<std::string> atoms;
	for (auto it1 = selectedRules.begin(); it1 != selectedRules.end(); ++it1) {
		const CMembrane& m = configuration.membranes[it1->first];
		const std::vector<Rule>& rules = ruleSets.at(m.label).at(m.charge);
		for (auto it2 = it1->second.begin(); it2 != it1->second.end(); ++it2) {
			appendTraceAtoms(sexprUnused, atoms, it1->first, rules[it2->first]);
		}
	}
	for (const auto& a : atoms) std::cout << a << "\n";
}

inline
void Simulator::traceCheckpointJson() const
{
	std::ostringstream os;
	os << "{\"event\":\"checkpoint\",\"step\":" << configuration.time << ",\"membranes\":[";
	bool first = true;
	for (std::size_t i = 0; i < configuration.membranes.size(); i++) {
		const CMembrane& m = configuration.membranes[i];
		if (m.parent == -2) continue;
		if (!first) os << ",";
		first = false;
		os << "{\"id\":" << i
		   << ",\"label\":\"" << jsonEscape(m.label.empty() ? "?" : m.label[0].str()) << "\""
		   << ",\"parent\":" << m.parent
		   << ",\"objects\":" << multisetToJson(m.multiset) << "}";
	}
	os << "]}";
	std::cout << os.str() << "\n";
}

inline
void Simulator::selectRules()
{
	std::size_t remainingApplications;
	
	selectedRules.clear();
	
	for (unsigned i = 0; i< configuration.membranes.size(); i++) {
		configuration.membranes[i].semantics = file.psystem.semantics;
	}
	
	do{
		remainingApplications = 0;
		Shuffler<CMembrane> membranes(configuration.membranes, randomized);
		for (unsigned i = 0; i < membranes.size(); i++) {
			
			if (membranes[i].parent==-2) { 
				continue;
			}
			membranes[i].priorityLevel = std::numeric_limits<long>::max();
			Shuffler<Rule> rules(ruleSets[membranes[i].label][membranes[i].charge],randomized);
			for (unsigned j = 0; j< rules.size(); j++) {
				std::size_t max = getMaxApplications(membranes[i],rules[j]);
				bool isProbabilistic = rules[j].features.count("probability") > 0;
				std::size_t applications;
				if (isProbabilistic) {
					double prob = rules[j].features.at("probability").as_double();
					if (randomized) {
						// Stochastic rounding: base applications + Bernoulli trial
						// on the fractional part gives an unbiased integer count.
						double scaled = max * prob;
						std::size_t base = (std::size_t)scaled;
						double remainder = scaled - base;
						applications = base + (RANDOM() < remainder ? 1 : 0);
					} else {
						applications = (std::size_t)std::round(max * prob);
					}
				} else {
					applications = randomized ? RANDOM(max+1) : max;
				}
				if (rules[j].features.count("priority")>0) {
					if (rules[j].features.at("priority").cast_long() > membranes[i].priorityLevel) {
						applications = 0;
					} else if (max > applications) {
						membranes[i].priorityLevel = rules[j].features.at("priority").cast_long();
					}
				}
				if (applications>0) {
					selectedRules[membranes(i)][rules(j)] += applications;
					consume(membranes[i],rules[j],applications);
				}
				if (!isProbabilistic) {
					remainingApplications += (max - applications);
				}
			}
		}
	} while (remainingApplications > 0);
	
	if (getVerbosityLevel()>1 && !selectedRules.empty()) {
		std::cout<<"-----------------------------------------------\n\n";
		std::cout<<"STEP "<<configuration.time+1<<":\n";
		for (auto it1 = selectedRules.begin(); it1 != selectedRules.end(); ++it1) {
			CMembrane& m = configuration.membranes[it1->first];
			std::cout << "\nMembrane ID: "<< it1->first << std::endl;
			const std::vector<Rule>& rules = ruleSets[m.label][m.charge];
			for (auto it2 = it1->second.begin(); it2 != it1->second.end(); ++it2) {
				std::cout<< it2->second <<" * "<< rules[it2->first] << std::endl;
			}
		}
	}

	// "wire" stream: one (fired ...) s-expr per rule application this step.
	// sexpr mode prints now; json mode emits one object for the step; human
	// and diff stash the lines and the panes are drawn in executeRules()
	// after the clock advances.
	if (getTraceMode() == "sexpr" && !selectedRules.empty()) {
		traceStepEvents();
	} else if (getTraceMode() == "json" && !selectedRules.empty()) {
		traceStepJson();
	} else if (getTraceMode() == "human" || getTraceMode() == "diff") {
		pendingWireLines = stepEventLines();
	}
}


inline
void Simulator::consume(CMembrane& m, const Rule& rule, std::size_t applications) 
{
	if (rule.features.count("pattern")>0) {
		updateSemantics(m.semantics,rule.features.at("pattern").as_string(),applications);
	}
	
	
	Multiset& pMs = m.parent == -1 ? configuration.environment : configuration.membranes[m.parent].multiset;
	sub(pMs, rule.lhr.multiset, applications);
	sub(m.multiset,rule.lhr.membrane.multiset,applications);
	bool found;
	unsigned i;
	for (const IMembrane& im : rule.lhr.membrane.data) {
		found = false;
		i=0;
		while(i<m.children.size() && !found) {
			if (configuration.membranes[m.children[i]].label == im.label && 
				configuration.membranes[m.children[i]].charge == im.charge) {
				found = true;		
			} else {
				i++;
			}
		}
		if (found) {
			sub(configuration.membranes[m.children[i]].multiset,im.multiset,applications);
		}
	}
	
	if (rule.arrow == 1 && rule.rhr.data[0].label[0] != "0") {
		for (CMembrane& m : configuration.membranes) {
			if (m.label == rule.rhr.data[0].label) {
				sub(m.multiset, rule.rhr.data[0].multiset,applications);
				break;
			}
		}
		
	}
	
}



inline
void Simulator::add(Multiset& ms0, const Multiset& ms1, std::size_t times)
{
	if (times==0 || ms1.empty()) {
		return;
	}
	for (auto it = ms1.begin(); it!= ms1.end(); ++it) {
		ms0[it->first] += it->second.raw() * times;
	}
	
}


inline
void Simulator::sub(Multiset& ms0, const Multiset& ms1, std::size_t times)
{
	if (times==0 || ms1.empty()) {
		return;
	}
	for (auto it = ms1.begin(); it!= ms1.end(); ++it) {
		auto it1 = ms0.find(it->first);
		if (it1 == ms0.end()) {
			continue;
		}
		it1->second = it1->second.raw() - it->second.raw() * times;
		if (it1->second.raw() <= 0) {
			ms0.erase(it1);
		}
	}
	
}

inline
void Simulator::produce(unsigned membraneId, const OMembrane& lhrMembrane, const OMembrane& om, std::size_t applications, std::set<unsigned>& dissolving)
{
	CMembrane& m = configuration.membranes[membraneId];
	add(m.multiset,om.multiset,applications);
	if (om.charge != lhrMembrane.charge) {
		m.charge = om.charge;
	}
	if (m.multiset.count("@d")) {
		m.multiset.erase("@d");
		dissolving.insert(membraneId);
	}
	for (const IMembrane& im : om.data) {
		bool found = false;
		unsigned i=0;
		while(i<m.children.size() && !found) {
			if (configuration.membranes[m.children[i]].label == im.label) {
				found = true;		
			} else {
				i++;
			}
		}
		if (!found) {
			std::ostringstream ss;
			ss << "Unable to produce: child membrane with label '" << im.label 
			   << "' not found in membrane " << membraneId;
			throw std::runtime_error(ss.str());
		}
		configuration.membranes[m.children[i]].charge = im.charge;
		add(configuration.membranes[m.children[i]].multiset,im.multiset,applications);
		if (configuration.membranes[m.children[i]].multiset.count("@d")>0) {
			configuration.membranes[m.children[i]].multiset.erase("@d");
			dissolving.insert(m.children[i]);
		}
	}
}

inline
unsigned Simulator::copyMembrane(unsigned membraneId)
{
	unsigned index;
	if (freeIndexes.empty()) {
		index = configuration.membranes.size();
		configuration.membranes.resize(configuration.membranes.size()+1);
	} else {
		index = freeIndexes.front();
		freeIndexes.pop();
	}
	configuration.membranes[index].charge = configuration.membranes[membraneId].charge;
	configuration.membranes[index].label = configuration.membranes[membraneId].label;
	configuration.membranes[index].multiset = configuration.membranes[membraneId].multiset;
	configuration.membranes[index].parent = configuration.membranes[membraneId].parent;
	if (configuration.membranes[index].parent != -1) {
		configuration.membranes[configuration.membranes[index].parent].children.push_back(index);
	}
	
	for (unsigned i=0;i<configuration.membranes[membraneId].children.size(); i++) {
		configuration.membranes[index].children.push_back(copyMembrane(configuration.membranes[membraneId].children[i]));
	}
	
	return index;
}


inline
void Simulator::produce(unsigned membraneId, const Rule& rule, std::size_t applications, std::set<unsigned>& dissolving)
{
	CMembrane& m = configuration.membranes[membraneId];
	
	
	if (rule.arrow == 1) {
		add(m.multiset,rule.rhr.data[0].multiset,applications);
		for (CMembrane& m1 : configuration.membranes) {
			if (m1.label == rule.rhr.data[0].label) {
				if (m1.label[0]=="0") {
					add(m1.multiset,rule.lhr.membrane.multiset,1);
				} else {
					add(m1.multiset,rule.lhr.membrane.multiset,applications);
				}
				break;
			}
		}
		return;
		
	}
	
	
	Multiset& pMs = m.parent == -1 ? configuration.environment : configuration.membranes[m.parent].multiset;
	add(pMs,rule.rhr.multiset,applications);
	if (rule.rhr.data.size()==0) {
		dissolving.insert(membraneId);
		return;
	} 
	for (unsigned i = 1; i< rule.rhr.data.size(); i++) {
		unsigned index = copyMembrane(membraneId);
		produce(index,rule.lhr.membrane,rule.rhr.data[i],applications,dissolving);
	}
	produce(membraneId,rule.lhr.membrane,rule.rhr.data[0],applications,dissolving);
}


inline
void Simulator::executeRules()
{
	if (selectedRules.empty()) {
		return;
	}
		
	std::set<unsigned> dissolving;
	
	// First pass: no division
	for (auto it1 = selectedRules.begin(); it1 != selectedRules.end(); ++it1) {
		CMembrane& m = configuration.membranes[it1->first];
		const std::vector<Rule>& rules = ruleSets[m.label][m.charge];
		auto it2 = it1->second.begin();
		while (it2 != it1->second.end()) {
			const Rule& r = rules[it2->first];
			if (r.rhr.data.size()>1) {
				++it2;
			} else {
				produce(it1->first,r,it2->second,dissolving);
				it2 = it1->second.erase(it2);
			}
		}
	}
	
	// Second pass: division
	for (auto it1 = selectedRules.begin(); it1 != selectedRules.end(); ++it1) {
		CMembrane& m = configuration.membranes[it1->first];
		const std::vector<Rule>& rules = ruleSets[m.label][m.charge];
		for (auto it2 = it1->second.begin(); it2 != it1->second.end(); ++it2) {
			const Rule& r = rules[it2->first];
			produce(it1->first,r,it2->second,dissolving);
		}
	}
	
	// dissolution
	for (unsigned index : dissolving) {
		CMembrane& m = configuration.membranes[index];
		Multiset& pMs = m.parent == -1 ? configuration.environment : configuration.membranes[m.parent].multiset;
		add(pMs,m.multiset,1);
		if (m.parent != -1) {
			for (unsigned i=0;i<configuration.membranes[m.parent].children.size();i++) {
				if (configuration.membranes[m.parent].children[i]==(int)index) {
					configuration.membranes[m.parent].children[i] = configuration.membranes[m.parent].children[configuration.membranes[m.parent].children.size()-1];
					configuration.membranes[m.parent].children.resize(configuration.membranes[m.parent].children.size()-1);
					break;
				}
			}
		}
		for (unsigned i=0;i<m.children.size();i++) {
			if (m.parent!=-1) {
				configuration.membranes[m.parent].children.push_back(m.children[i]);
			}
			configuration.membranes[m.children[i]].parent = m.parent;
		}
		freeIndexes.push(index);
		m.parent = -2;
		m.multiset.clear();
		m.children.clear();	
	}
	
	
	configuration.time++;

	if (getVerbosityLevel()>0) {
		std::cout<<"\n***********************************************\n\n";
		std::cout<<getCurrentConfiguration()<<std::endl;
	}

	// "checkpoint" stream: full configuration as a readable s-expr, emitted
	// every --checkpoint-every steps (after time has advanced), or every step
	// at high verbosity.  human/diff draw the three-pane layout instead.
	if (getTraceMode() == "human" || getTraceMode() == "diff") {
		if (checkpointDue() || !pendingWireLines.empty()) {
			traceHumanStep(pendingWireLines);
		}
		pendingWireLines.clear();
	} else if (getTraceMode() == "sexpr" && checkpointDue()) {
		traceCheckpoint();
	} else if (getTraceMode() == "json" && checkpointDue()) {
		traceCheckpointJson();
	}

}



bool Simulator::updateSemantics(Semantics& semantics, const std::string& pattern, std::size_t applications)
{
	if (!semantics.inf && semantics.value < applications) {
		return false;
	}
		
	if (!semantics.inf)  {
		semantics.value-=applications;
	}
	if (semantics.patterns.count(pattern)>0) {
		return true;
	}
	for (Semantics& child : semantics.children) {
		if (updateSemantics(child,pattern,applications)) {
			return true;
		}
	}
	if (!semantics.inf) {
		semantics.value+=applications;
	}
	return false;
	
}

std::size_t Simulator::getMaxApplications(const Semantics& semantics, const std::string& pattern) const
{
	if (semantics.patterns.count(pattern)>0) {
		return semantics.inf ? std::numeric_limits<std::size_t>::max() : semantics.value;
	}
	for (const Semantics& child : semantics.children) {
		std::size_t aux = getMaxApplications(child,pattern);
		if (aux > 0) {
			return aux;
		}
	}
	return 0;
}



std::size_t Simulator::getMaxApplications(const CMembrane& m, const Rule& rule) const
{
	
	const LHR& lhr = rule.lhr;
	
	if (m.children.size() < lhr.membrane.data.size()) {
		return 0;
	}
	
	std::size_t min = std::numeric_limits<std::size_t>::max();
	
	if (rule.features.count("pattern")>0) {
		min = std::min(min,getMaxApplications(m.semantics,rule.features.at("pattern").as_string()));
		if (min==0) {
			return 0;
		}
	}
		
	const Multiset& pMs = m.parent == -1 ? configuration.environment : configuration.membranes[m.parent].multiset;
	
	min = std::min(min, count(lhr.multiset,pMs));
	
	if (min==0) {
		return 0;
	}
	
	min = std::min(min, count(lhr.membrane.multiset,m.multiset));
	
	if (min==0) {
		return 0;
	}

	bool found;
	unsigned i;
	for (const IMembrane& im : lhr.membrane.data) {
		found = false;
		i=0;
		while(i<m.children.size() && !found) {
			if (configuration.membranes[m.children[i]].label == im.label && 
				configuration.membranes[m.children[i]].charge == im.charge) {
				found = true;		
			} else {
				i++;
			}
		}
		if (!found) {
			return 0;
		}
		min = std::min(min,count(im.multiset,configuration.membranes[m.children[i]].multiset));
		if (min==0) {
			return 0;
		}	
	}
	
	// For communication rules with different LHS/RHS inner-membrane labels,
	// verify every RHS target membrane actually exists as a child.
	for (unsigned rhs_i = 0; rhs_i < rule.rhr.data.size(); rhs_i++) {
		for (const IMembrane& rhs_im : rule.rhr.data[rhs_i].data) {
			bool matchesLHS = false;
			for (const IMembrane& lhs_im : lhr.membrane.data) {
				if (lhs_im.label == rhs_im.label) {
					matchesLHS = true;
					break;
				}
			}
			if (!matchesLHS) {
				bool targetFound = false;
				for (unsigned ci : m.children) {
					if (configuration.membranes[ci].label == rhs_im.label) {
						targetFound = true;
						break;
					}
				}
				if (!targetFound) {
					return 0;
				}
			}
		}
	}
	
	
	if (rule.arrow==1) {
		found = false;
		for (const CMembrane& m : configuration.membranes) {
			if (m.label == rule.rhr.data[0].label) {
				found=true;
				if (m.label[0]=="0") {
					if (count(rule.rhr.data[0].multiset,m.multiset)==0) {
						min=0;
					}
				} else {
					min = std::min(min,count(rule.rhr.data[0].multiset,m.multiset));
				}
				break;
			}
		}
		if (!found) {
			min = 0;
		}
		
	}
	
	
	return min;
}


std::size_t Simulator::count(const Multiset& ms0, const Multiset& ms1)
{
	if (ms0.empty()) {
		return std::numeric_limits<std::size_t>::max();
	}
		
	if (ms1.size() < ms0.size()) {
		return 0;
	}
	std::size_t min = std::numeric_limits<std::size_t>::max();
	for (auto it0 = ms0.begin(); it0 != ms0.end() && min>0; ++it0) {
		auto it1 = ms1.find(it0->first);
		if (it1 == ms1.end()) {
			min = 0;
		} else {
			std::size_t aux = it1->second.raw() / it0->second.raw();
			if (aux < min) {
				min = aux;
			}
		}
	}
	return min;
}


inline
bool Simulator::ruleSupportedArrow0(const Rule& rule)
{
	if (rule.lhr.multiset.count("@d")>0 || rule.lhr.membrane.multiset.count("@d") || rule.rhr.multiset.count("@d")>0) {
		return false;
	}
	
	for (unsigned i=0;i< rule.rhr.data.size(); i++) {
		
		if (rule.rhr.data[i].multiset.count("@d")>0 && rule.rhr.data.size()>1) {
			return false;
		}
		
		if (rule.lhr.membrane.label != rule.rhr.data[i].label) {
			return false;
		}
		if (rule.lhr.membrane.data.size() != rule.rhr.data[i].data.size()) {
			return false;
		}
		
		for (unsigned j=0;j< rule.lhr.membrane.data.size(); j++) {
			if (rule.lhr.membrane.data[j].multiset.count("@d")>0) {
				return false;
			}
			if (rule.rhr.data[i].data[j].multiset.count("@d")>0 && rule.rhr.data.size()>1) {
				return false;
			}	
		}
	}
	return true;
}

inline 
bool Simulator::ruleSupportedArrow1(const Rule& rule)
{
	// <-->
	if (!rule.lhr.multiset.empty() || !rule.rhr.multiset.empty()) {
		return false;
	}
	
		
	if (rule.rhr.data.size()!=1) {
		return false;
	}
	
	if (rule.lhr.membrane.data.size()>0 || rule.rhr.data[0].data.size()>0) {
		return false;
	}
	
	if (rule.lhr.membrane.charge!=0 || rule.rhr.data[0].charge!=0) {
		return false;
	}
	
	if (rule.lhr.membrane.label == rule.rhr.data[0].label) {
		return false;
	}
	
		
	if (rule.lhr.membrane.multiset.count("@d")>0 || rule.rhr.data[0].multiset.count("@d")>0) {
		return false;
	}
	
	return true;
}


inline
bool Simulator::ruleSupported(const Rule& rule)
{
	// Rules with probability are now supported in randomized mode
	// Validate probability value if present (defensive check)
	if (rule.features.count("probability") > 0) {
		double prob = rule.features.at("probability").as_double();
		if (prob < 0.0 || prob > 1.0) {
			return false;
		}
	}
	
	if (rule.arrow == 0) {
		return ruleSupportedArrow0(rule);
	} 
	
	if (rule.arrow == 1) {
		return ruleSupportedArrow1(rule);
	}	
	
	return false;
}


	
inline
bool Simulator::parse(int argc, char *argv[])
{
	
	ruleSets.clear();
	selectedRules.clear();
	while(!freeIndexes.empty()) {
		freeIndexes.pop();
	}
	configuration.clear();
		
	
	if (!CommandLine::parse(argc,argv)) {
		finished = true;
		return false;
	}
	
	// Set random seed if provided via command line
	if (hasSeed()) {
		RANDOM.setSeed(getSeed());
		if (getVerbosityLevel() > 0) {
			std::cout << "Using random seed: " << getSeed() << std::endl;
		}
	} else if (getVerbosityLevel() > 0) {
		std::cout << "Using random seed: " << RANDOM.getSeed() << std::endl;
	}

	loadFromFile(getInputFile(),file);
	
	if (getConfigurationFile().empty()) {
		initConfigurationRec(file.psystem.structure, -1);
	} else {
		loadFromFile(getConfigurationFile(),configuration);
	}
	
	for (const Rule& rule : file.psystem.rules) {
		
		if (!ruleSupported(rule)) {
			 std::ostringstream ss;
			 ss << "Rule not supported: "<< rule ;
			 std::cout << ss.str() <<std::endl;
			 throw std::runtime_error(ss.str());
		}
		ruleSets[rule.lhr.membrane.label][rule.lhr.membrane.charge].push_back(rule);
	}	
	
	struct {
		inline bool operator()(const Rule& a, const Rule& b)  {
						
			if (a.features.count("priority") > 0 && b.features.count("priority") > 0) {
				long x = a.features.at("priority").cast_long();
				long y = b.features.at("priority").cast_long();
				return x < y;
			}
			return a < b;
		}
	} customLess;
	
	for (auto it1 = ruleSets.begin(); it1 != ruleSets.end(); ++it1) {
		for (auto it2 = it1->second.begin(); it2 != it1->second.end(); ++it2) {
			std::vector<Rule>& rules = it2->second;
			std::sort(rules.begin(),rules.end(),customLess);
		}
	}
	
	if (!randomized) {
		randomized = file.psystem.features.count("randomized");
	}
	if (getVerbosityLevel()>1) {
		std::cout<<"// P SYSTEM TO SIMULATE:\n";
		std::cout<<getFile()<<"\n\n";
		std::cout<<"***********************************************\n\n";
	}
	if (getVerbosityLevel()>0) {
		std::cout<<getCurrentConfiguration()<<std::endl;
	}
	initialTime = configuration.time;
	finished = false;
	// Emit the run header first so any trace is replayable.
	if (getTraceMode() != "off") {
		traceHeader();
	}
	// --trace=diff compares each step against the previous checkpoint,
	// starting from the initial configuration.
	if (getTraceMode() == "diff") {
		lastTraceFingerprint = configurationFingerprint();
	}
	return true;
}

inline
void Simulator::initConfigurationRec(const Membrane& membrane, int parent)
{
	int index = configuration.membranes.size();
	configuration.membranes.emplace_back();
	CMembrane& c = configuration.membranes.back();
	c.label = membrane.label;
	c.charge = membrane.charge;
	c.parent = parent;
	
	if (file.psystem.multisets.count(membrane.label)>0) {
		c.multiset = file.psystem.multisets.at(membrane.label);
	}
	
	if (parent!=-1) {
		configuration.membranes[parent].children.push_back(index);
	}
	for (const Membrane& m : membrane.data) {
		initConfigurationRec(m,index);
	}
}



	
}}



#endif

