#ifndef _COMMAND_LINE_HPP_
#define _COMMAND_LINE_HPP_

#include <string>

namespace plingua { namespace simulator {


// Class to parse and store parameters from the command-line
class CommandLine
{
public:
	CommandLine();

	virtual bool parse(int argc, char *argv[]);
	
	int getVerbosityLevel() const {return verbosityLevel;}
	unsigned getMaxStepsToSimulate() const {return steps;}
			
	const std::string& getInputFile() const {return inputFile;}
	const std::string& getOutputFile() const {return outputFile;}
	const std::string& getConfigurationFile() const {return configurationFile;}
	bool isRandomized() const {return randomized;}
	bool hasSeed() const {return seedProvided;}
	unsigned getSeed() const {return seed;}

	// Trace mode: "off" (default, legacy STEP output), "sexpr", "human".
	// "sexpr" emits one parenthesised event per line (the "wire" stream) so the
	// output can be diffed against the Lisp s-expr kernel; "human" adds the
	// --glyph/--wire/--checkpoint three-pane layout.
	const std::string& getTraceMode() const {return traceMode;}
	unsigned getCheckpointEvery() const {return checkpointEvery;}
	bool isUnicode() const {return unicode;}

protected:
	bool randomized;

private:

	void printAbout() const;

	int verbosityLevel;
	unsigned steps;
	unsigned seed;
	bool seedProvided;

	std::string inputFile;
	std::string outputFile;
	std::string configurationFile;
	std::string traceMode;
	unsigned checkpointEvery;
	bool unicode;

};



}}






#endif
