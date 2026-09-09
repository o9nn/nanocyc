#!/usr/bin/env lua
-- a9nn/run_tests.lua
-- Convenience script: runs all test suites and reports summary.
-- Usage:  lua run_tests.lua   (from lang/a9nn/)

local function addPath(p)
   package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end
addPath(".")
addPath("..")

local function runSuite(path, name)
   print(string.rep("═", 60))
   print("  Suite: " .. name)
   print(string.rep("═", 60))
   local fn, err = loadfile(path)
   if not fn then
      print("ERROR loading " .. path .. ": " .. tostring(err))
      return false
   end
   -- Reset loaded modules so suites don't pollute each other
   local ok, err2 = pcall(fn)
   if not ok then
      print("ERROR running " .. path .. ": " .. tostring(err2))
      return false
   end
   return true
end

local ok1 = runSuite("test/test_basic.lua",    "Core NN modules")
print()
local ok2 = runSuite("test/test_cognitive.lua", "Cognitive agents")
print()
local ok3 = runSuite("test/test_consistency.lua", "Cross-implementation consistency")
print()

if ok1 and ok2 and ok3 then
   print("All suites completed successfully.")
else
   print("Some suites had errors.")
   os.exit(1)
end
