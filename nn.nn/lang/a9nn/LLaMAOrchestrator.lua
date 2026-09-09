-- a9nn/LLaMAOrchestrator.lua
-- Orchestrator for 1-9 parallel LLaMA.cpp local-inference instances.
--
-- Each instance is assumed to be a running llama.cpp server (--server mode)
-- listening on a different HTTP port.  Requests are dispatched via the
-- `/completion` REST endpoint.
--
-- In environments without llama.cpp, the orchestrator falls back to a
-- stub "echo" backend so that the cognitive pipeline can still run.
--
-- Port assignment: instance k uses port (basePort + k - 1).
-- Default base port: 8080.  Max instances: 9.

local nn    = require('a9nn.nn_ns')
local Class = nn.Class

-- Try to load a lightweight HTTP library (if present in the environment)
local http = nil
pcall(function()
   http = require('socket.http')  -- LuaSocket
end)
if not http then
   pcall(function()
      http = require('http')       -- custom binding
   end)
end

-- ─── Instance record ─────────────────────────────────────────────────────────

local function makeInstance(id, port)
   return {
      id           = id,
      port         = port,
      available    = true,
      tokensServed = 0,
      requests     = 0,
      errors       = 0,
      lastLatencyMs = 0,
   }
end

-- ─── LLaMAOrchestrator ───────────────────────────────────────────────────────

local LLaMAOrchestrator, _ = Class.class('nn.LLaMAOrchestrator')

--- Constructor.
-- @param opts   table:
--   numInstances  number of instances (1-9, default 1)
--   basePort      port for first instance (default 8080)
--   modelPath     path to .gguf model (informational)
--   timeout       HTTP timeout in seconds (default 30)
--   stubMode      if true, use echo stub without real HTTP (default: auto)
function LLaMAOrchestrator:__init(opts)
   opts = opts or {}
   self.numInstances = math.min(9, math.max(1, opts.numInstances or 1))
   self.basePort     = opts.basePort  or 8080
   self.modelPath    = opts.modelPath or ""
   self.timeout      = opts.timeout   or 30
   self.stubMode     = opts.stubMode

   -- Auto-detect stub mode if no HTTP library available
   if self.stubMode == nil then
      self.stubMode = (http == nil)
   end

   -- Build instance pool
   self.instances = {}
   for i = 1, self.numInstances do
      self.instances[i] = makeInstance(i, self.basePort + i - 1)
   end

   -- Request queue
   self.queue = {}

   self.initialized = false
   self.verbose     = opts.verbose or false
end

--- Initialize (ping each instance to verify reachability).
-- In stub mode this always succeeds.
-- @return  true if at least one instance is reachable
function LLaMAOrchestrator:initialize()
   if self.stubMode then
      if self.verbose then
         print(string.format(
            "[LLaMAOrchestrator] Stub mode: %d virtual instance(s) on ports %d-%d",
            self.numInstances, self.basePort, self.basePort + self.numInstances - 1))
      end
      self.initialized = true
      return true
   end

   local ok = false
   for _, inst in ipairs(self.instances) do
      local alive = self:_ping(inst)
      inst.available = alive
      if alive then ok = true end
      if self.verbose then
         print(string.format("[LLaMAOrchestrator] Instance %d (port %d): %s",
            inst.id, inst.port, alive and "UP" or "DOWN"))
      end
   end
   self.initialized = ok
   return ok
end

--- Send a completion request.
-- @param prompt   string
-- @param params   table: temperature, max_tokens, top_p, stop
-- @return         table: text, tokens, instance_id, latency_ms
function LLaMAOrchestrator:generate(prompt, params)
   params = params or {}
   assert(self.initialized, "LLaMAOrchestrator: call initialize() first")

   local inst = self:_selectInstance()
   if not inst then
      return {text = "", error = "No available instances"}
   end

   local t0 = os.clock()
   local result

   if self.stubMode then
      result = self:_stubGenerate(prompt, params, inst)
   else
      result = self:_httpGenerate(prompt, params, inst)
   end

   local latency = math.floor((os.clock() - t0) * 1000)
   inst.lastLatencyMs = latency
   result.latency_ms  = latency
   result.instance_id = inst.id

   if self.verbose then
      print(string.format(
         "[LLaMAOrchestrator] inst=%d port=%d latency=%dms tokens=%d",
         inst.id, inst.port, latency, result.tokens or 0))
   end

   return result
end

--- Dispatch multiple prompts concurrently across available instances.
-- (In single-threaded Lua this is round-robin sequential, but the interface
-- mirrors a parallel API.)
-- @param prompts  table of strings
-- @param params   shared generation params
-- @return         table of result tables
function LLaMAOrchestrator:batchGenerate(prompts, params)
   local results = {}
   for _, prompt in ipairs(prompts) do
      results[#results+1] = self:generate(prompt, params)
   end
   return results
end

--- Return a status snapshot.
function LLaMAOrchestrator:getStatus()
   local available = 0
   local instances = {}
   for _, inst in ipairs(self.instances) do
      if inst.available then available = available + 1 end
      instances[#instances+1] = {
         id           = inst.id,
         port         = inst.port,
         available    = inst.available,
         tokensServed = inst.tokensServed,
         requests     = inst.requests,
         errors       = inst.errors,
         lastLatencyMs = inst.lastLatencyMs,
      }
   end
   return {
      numInstances = self.numInstances,
      available    = available,
      stubMode     = self.stubMode,
      instances    = instances,
      queueLength  = #self.queue,
   }
end

-- ─── Private helpers ─────────────────────────────────────────────────────────

--- Select the least-loaded available instance.
function LLaMAOrchestrator:_selectInstance()
   local best, bestLoad = nil, math.huge
   for _, inst in ipairs(self.instances) do
      if inst.available then
         local load = inst.tokensServed
         if load < bestLoad then
            best     = inst
            bestLoad = load
         end
      end
   end
   return best
end

--- Ping an instance by requesting /health.
function LLaMAOrchestrator:_ping(inst)
   if not http then return false end
   local url = string.format("http://127.0.0.1:%d/health", inst.port)
   local ok, result = pcall(function()
      local body, code = http.request(url)
      return code == 200
   end)
   return ok and result
end

--- Real HTTP generation request.
function LLaMAOrchestrator:_httpGenerate(prompt, params, inst)
   local url = string.format("http://127.0.0.1:%d/completion", inst.port)
   local body = string.format(
      '{"prompt":%s,"n_predict":%d,"temperature":%.2f,"top_p":%.2f}',
      ("%q"):format(prompt),
      params.max_tokens or 256,
      params.temperature or 0.7,
      params.top_p or 0.9)

   inst.requests = inst.requests + 1
   local ok, resp = pcall(function()
      if http.request then
         return http.request{
            url    = url,
            method = "POST",
            source = require('ltn12').source.string(body),
            headers = {
               ["content-type"]   = "application/json",
               ["content-length"] = #body,
            },
         }
      end
   end)

   if not ok or not resp then
      inst.errors = inst.errors + 1
      return {text = "", error = "HTTP request failed"}
   end

   -- Parse minimal JSON
   local text   = resp:match('"content"%s*:%s*"(.-)"') or ""
   local tokens = tonumber(resp:match('"tokens_predicted"%s*:%s*(%d+)')) or 0
   inst.tokensServed = inst.tokensServed + tokens

   return {text = text, tokens = tokens}
end

--- Stub generator: echoes the prompt with a simple response.
function LLaMAOrchestrator:_stubGenerate(prompt, params, inst)
   local maxTok = params.max_tokens or 64
   inst.requests     = inst.requests + 1
   inst.tokensServed = inst.tokensServed + maxTok

   -- Simple deterministic stub response
   local words = {}
   for w in prompt:gmatch("%S+") do words[#words+1] = w end
   local response = string.format(
      "[stub inst=%d] Echo: %s ... [%d tokens]",
      inst.id,
      table.concat(words, " ", 1, math.min(5, #words)),
      maxTok)

   return {text = response, tokens = maxTok, stub = true}
end

function LLaMAOrchestrator:__tostring()
   return string.format(
      "nn.LLaMAOrchestrator(%d instances, base_port=%d, stub=%s)",
      self.numInstances, self.basePort, tostring(self.stubMode))
end

return LLaMAOrchestrator
