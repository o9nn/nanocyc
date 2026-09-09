CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6)

# Root CMakeLists.txt for nn.pl
# Delegates to language-specific implementations

# Add Lua/C implementation
ADD_SUBDIRECTORY(lang/lua)
