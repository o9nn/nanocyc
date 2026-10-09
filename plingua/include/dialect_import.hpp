#ifndef _DIALECT_IMPORT_HPP_
#define _DIALECT_IMPORT_HPP_

/*
 * Cross-dialect composition for the P/M/R stack.
 *
 * @import "path"; and @import <path>; resolve relative to the importing
 * file. Same-dialect modules are inlined by the caller; other dialects
 * (typically a .pli companion) are recorded with extracted symbols and
 * are not inlined, so foreign rule syntax cannot be misread.
 *
 * Cycle detection is on the normalized path string. A repeated import of
 * an already-recorded path is a diamond and is skipped.
 */

#include <cctype>
#include <fstream>
#include <regex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace plingua {

struct ImportedModule {
	std::string path;
	std::string spec;
	std::string dialect; // pli, mli, rli, tli, or other
	bool inlined;
	std::vector<std::string> symbols;

	ImportedModule() : inlined(false) {}
};

namespace import_util {

inline std::string normalizePath(const std::string& path) {
	if (path.empty()) return path;
	bool abs = path[0] == '/';
	std::vector<std::string> parts;
	std::string cur;
	for (size_t i = 0; i <= path.size(); ++i) {
		if (i == path.size() || path[i] == '/') {
			if (cur.empty() || cur == ".") {
				// skip
			} else if (cur == "..") {
				if (!parts.empty() && parts.back() != "..") parts.pop_back();
				else if (!abs) parts.push_back("..");
			} else {
				parts.push_back(cur);
			}
			cur.clear();
		} else {
			cur += path[i];
		}
	}
	std::string out = abs ? "/" : "";
	for (size_t i = 0; i < parts.size(); ++i) {
		if (i) out += "/";
		out += parts[i];
	}
	if (out.empty()) return abs ? "/" : ".";
	return out;
}

inline std::string dirnameOf(const std::string& path) {
	std::string n = normalizePath(path);
	size_t slash = n.find_last_of('/');
	if (slash == std::string::npos) return ".";
	if (slash == 0) return "/";
	return n.substr(0, slash);
}

inline std::string resolveImport(const std::string& baseFile, const std::string& spec) {
	if (!spec.empty() && spec[0] == '/') return normalizePath(spec);
	std::string dir = dirnameOf(baseFile);
	if (dir == "." || dir.empty()) return normalizePath(spec);
	return normalizePath(dir + "/" + spec);
}

inline std::string dialectOf(const std::string& path) {
	size_t slash = path.find_last_of('/');
	size_t dot = path.find_last_of('.');
	if (dot == std::string::npos || (slash != std::string::npos && dot < slash))
		return "other";
	std::string ext = path.substr(dot + 1);
	for (size_t i = 0; i < ext.size(); ++i)
		ext[i] = static_cast<char>(std::tolower(static_cast<unsigned char>(ext[i])));
	if (ext == "pli" || ext == "mli" || ext == "rli" || ext == "tli") return ext;
	return "other";
}

inline bool looksLikeImport(const std::string& line) {
	if (line.size() < 7 || line.compare(0, 7, "@import") != 0) return false;
	if (line.size() == 7) return true;
	char c = line[7];
	return std::isspace(static_cast<unsigned char>(c)) || c == '"' || c == '<';
}

inline bool parseImportSpec(const std::string& line, std::string& spec) {
	std::regex re("@import\\s+(?:\"([^\"]+)\"|<([^>]+)>)\\s*;?");
	std::smatch m;
	if (!std::regex_search(line, m, re)) return false;
	spec = m[1].matched ? m[1].str() : m[2].str();
	return !spec.empty();
}

inline std::string stripComments(const std::string& src) {
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
		out += src[i];
	}
	return out;
}

inline void addUnique(std::vector<std::string>& syms, std::set<std::string>& seen,
                      const std::string& s) {
	if (seen.insert(s).second) syms.push_back(s);
}

inline std::vector<std::string> extractSymbols(const std::string& body,
                                               const std::string& dialect) {
	std::string clean = stripComments(body);
	std::vector<std::string> syms;
	std::set<std::string> seen;
	if (dialect == "pli") {
		std::regex muRe("@mu\\s*=\\s*([^;]*);");
		std::smatch mu;
		if (std::regex_search(clean, mu, muRe)) {
			std::string region = mu[1].str();
			std::regex labRe("'([A-Za-z_][A-Za-z0-9_]*)");
			auto begin = std::sregex_iterator(region.begin(), region.end(), labRe);
			auto end = std::sregex_iterator();
			for (auto it = begin; it != end; ++it)
				addUnique(syms, seen, (*it)[1].str());
		}
	} else if (dialect == "mli") {
		std::regex tileRe("@tile\\s+([A-Za-z_][A-Za-z0-9_]*)");
		auto begin = std::sregex_iterator(clean.begin(), clean.end(), tileRe);
		auto end = std::sregex_iterator();
		for (auto it = begin; it != end; ++it)
			addUnique(syms, seen, (*it)[1].str());
	} else if (dialect == "rli") {
		std::regex nodeRe("@(?:agent|arena|relate)\\s+[^;\\n]*\\bid\\s*=\\s*([A-Za-z_][A-Za-z0-9_]*)");
		auto begin = std::sregex_iterator(clean.begin(), clean.end(), nodeRe);
		auto end = std::sregex_iterator();
		for (auto it = begin; it != end; ++it)
			addUnique(syms, seen, (*it)[1].str());
	} else if (dialect == "tli") {
		std::regex symRe("@(?:clock|phase_register|spinor|gate)\\s+([A-Za-z_][A-Za-z0-9_]*)");
		auto begin = std::sregex_iterator(clean.begin(), clean.end(), symRe);
		auto end = std::sregex_iterator();
		for (auto it = begin; it != end; ++it)
			addUnique(syms, seen, (*it)[1].str());
	}
	return syms;
}

struct ImportPrep {
	enum Status { NOT_IMPORT, MALFORMED, CYCLE, SKIP, MISSING, READY };
	Status status;
	std::string error;
	std::string spec;
	std::string resolved;
	std::string dialect;
	std::string body;
	std::vector<std::string> symbols;

	ImportPrep() : status(NOT_IMPORT) {}
};

inline ImportPrep prepareImport(const std::string& baseFile,
                                const std::string& line,
                                const std::set<std::string>& stack,
                                const std::vector<ImportedModule>& already) {
	ImportPrep prep;
	if (!looksLikeImport(line)) return prep;
	if (!parseImportSpec(line, prep.spec)) {
		prep.status = ImportPrep::MALFORMED;
		prep.error = "malformed @import (expected @import \"path\"; or @import <path>;)";
		return prep;
	}
	prep.resolved = resolveImport(baseFile, prep.spec);
	prep.dialect = dialectOf(prep.resolved);
	if (stack.count(prep.resolved)) {
		prep.status = ImportPrep::CYCLE;
		prep.error = "import cycle: " + prep.spec + " -> " + prep.resolved;
		return prep;
	}
	for (size_t i = 0; i < already.size(); ++i) {
		if (already[i].path == prep.resolved) {
			prep.status = ImportPrep::SKIP;
			return prep;
		}
	}
	std::ifstream in(prep.resolved.c_str());
	if (!in) {
		prep.status = ImportPrep::MISSING;
		prep.error = "cannot open import '" + prep.spec + "' (resolved " + prep.resolved + ")";
		return prep;
	}
	std::ostringstream ss;
	ss << in.rdbuf();
	prep.body = ss.str();
	prep.symbols = extractSymbols(prep.body, prep.dialect);
	prep.status = ImportPrep::READY;
	return prep;
}

} // namespace import_util
} // namespace plingua

#endif // _DIALECT_IMPORT_HPP_
