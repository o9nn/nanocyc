-- a9nn/AtomSpace.lua
-- OpenCog-inspired hypergraph knowledge base.
--
-- Atoms are the fundamental units: Nodes (typed, named) and Links (typed,
-- connecting other atoms).  Each atom carries a TruthValue (strength + count)
-- and an AttentionValue (STI + LTI).
--
-- This implementation is a pure-Lua in-memory store; it does not require any
-- external dependencies.

local nn    = require('a9nn.nn_ns')
local Class = nn.Class

-- ─── TruthValue ───────────────────────────────────────────────────────────────

local TruthValue = {}
TruthValue.__index = TruthValue

function TruthValue.new(strength, count)
   return setmetatable({
      strength = strength or 1.0,
      count    = count    or 1.0,
   }, TruthValue)
end

function TruthValue:confidence()
   return self.count / (self.count + 1.0)
end

function TruthValue:__tostring()
   return string.format("<s=%.3f, c=%.1f>", self.strength, self.count)
end

-- ─── AttentionValue ───────────────────────────────────────────────────────────

local AttentionValue = {}
AttentionValue.__index = AttentionValue

function AttentionValue.new(sti, lti)
   return setmetatable({sti = sti or 0, lti = lti or 0}, AttentionValue)
end

-- ─── Atom ─────────────────────────────────────────────────────────────────────

local Atom = {}
Atom.__index = Atom
local _atomID = 0

function Atom.new(atomType, name, outgoing, tv, av)
   _atomID = _atomID + 1
   return setmetatable({
      id       = _atomID,
      type     = atomType,
      name     = name    or "",
      outgoing = outgoing or {},   -- list of atom IDs (for Links)
      tv       = tv or TruthValue.new(1, 1),
      av       = av or AttentionValue.new(0, 0),
      incoming = {},               -- set of link IDs that reference this atom
   }, Atom)
end

function Atom:isNode() return #self.outgoing == 0 end
function Atom:isLink() return #self.outgoing > 0  end

function Atom:__tostring()
   if self:isNode() then
      return string.format("(%s \"%s\" %s)", self.type, self.name, tostring(self.tv))
   else
      return string.format("(%s %s %s)", self.type,
         table.concat(self.outgoing, ","), tostring(self.tv))
   end
end

-- ─── AtomSpace ────────────────────────────────────────────────────────────────

local AtomSpace, _ = Class.class('nn.AtomSpace')

function AtomSpace:__init()
   self.atoms     = {}    -- id → Atom
   self.nodeIndex = {}    -- type+name → id
   self.linkIndex = {}    -- type+outgoing_key → id
   self.typeIndex  = {}   -- type → {id, ...}
end

--- Add or retrieve a Node.
-- @param atomType  string, e.g. "ConceptNode"
-- @param name      string identifier
-- @param tv        TruthValue (optional)
-- @return          Atom
function AtomSpace:addNode(atomType, name, tv)
   local key = atomType .. "|" .. name
   if self.nodeIndex[key] then
      local existing = self.atoms[self.nodeIndex[key]]
      if tv then existing.tv = tv end
      return existing
   end
   local atom = Atom.new(atomType, name, {}, tv)
   self.atoms[atom.id]    = atom
   self.nodeIndex[key]    = atom.id
   self.typeIndex[atomType] = self.typeIndex[atomType] or {}
   table.insert(self.typeIndex[atomType], atom.id)
   return atom
end

--- Add or retrieve a Link.
-- @param atomType  string, e.g. "InheritanceLink"
-- @param outgoing  list of Atom objects (or IDs)
-- @param tv        TruthValue (optional)
-- @return          Atom
function AtomSpace:addLink(atomType, outgoing, tv)
   local ids = {}
   for _, a in ipairs(outgoing) do
      ids[#ids+1] = type(a) == "table" and a.id or a
   end
   local key = atomType .. "|" .. table.concat(ids, ",")
   if self.linkIndex[key] then
      local existing = self.atoms[self.linkIndex[key]]
      if tv then existing.tv = tv end
      return existing
   end
   local atom = Atom.new(atomType, "", ids, tv)
   self.atoms[atom.id]   = atom
   self.linkIndex[key]   = atom.id
   self.typeIndex[atomType] = self.typeIndex[atomType] or {}
   table.insert(self.typeIndex[atomType], atom.id)
   -- Update incoming sets
   for _, id in ipairs(ids) do
      if self.atoms[id] then
         self.atoms[id].incoming[atom.id] = true
      end
   end
   return atom
end

--- Retrieve atom by id.
function AtomSpace:getAtom(id)
   return self.atoms[id]
end

--- Retrieve node by type+name.
function AtomSpace:getNode(atomType, name)
   local key = atomType .. "|" .. name
   local id  = self.nodeIndex[key]
   return id and self.atoms[id] or nil
end

--- Return all atoms of a given type.
function AtomSpace:getAtomsOfType(atomType)
   local out   = {}
   local ids   = self.typeIndex[atomType] or {}
   for _, id in ipairs(ids) do
      out[#out+1] = self.atoms[id]
   end
   return out
end

--- Incoming set of an atom (links that reference it).
function AtomSpace:getIncoming(atom)
   local out = {}
   for id in pairs(atom.incoming) do
      out[#out+1] = self.atoms[id]
   end
   return out
end

--- Simple pattern matching: return links of given type whose outgoing set
--- contains all of the supplied atoms (in any position).
function AtomSpace:getLinks(linkType, atoms)
   local mustHave = {}
   for _, a in ipairs(atoms or {}) do
      mustHave[type(a)=="table" and a.id or a] = true
   end
   local results = {}
   for _, atom in pairs(self.atoms) do
      if atom.type == linkType and atom:isLink() then
         local match = true
         for id in pairs(mustHave) do
            local found = false
            for _, oid in ipairs(atom.outgoing) do
               if oid == id then found = true; break end
            end
            if not found then match = false; break end
         end
         if match then results[#results+1] = atom end
      end
   end
   return results
end

--- Remove an atom (and clean up indices).
function AtomSpace:removeAtom(atomOrId)
   local id   = type(atomOrId) == "table" and atomOrId.id or atomOrId
   local atom = self.atoms[id]
   if not atom then return false end

   -- Remove from typeIndex
   local tidx = self.typeIndex[atom.type]
   if tidx then
      for i, v in ipairs(tidx) do
         if v == id then table.remove(tidx, i); break end
      end
   end

   -- Remove from nodeIndex / linkIndex
   if atom:isNode() then
      self.nodeIndex[atom.type .. "|" .. atom.name] = nil
   else
      local key = atom.type .. "|" .. table.concat(atom.outgoing, ",")
      self.linkIndex[key] = nil
      -- Update incoming sets of outgoing atoms
      for _, oid in ipairs(atom.outgoing) do
         if self.atoms[oid] then
            self.atoms[oid].incoming[id] = nil
         end
      end
   end

   self.atoms[id] = nil
   return true
end

--- Count atoms.
function AtomSpace:size()
   local n = 0
   for _ in pairs(self.atoms) do n = n + 1 end
   return n
end

function AtomSpace:__tostring()
   return string.format("nn.AtomSpace(%d atoms)", self:size())
end

return {
   AtomSpace     = AtomSpace,
   TruthValue    = TruthValue,
   AttentionValue = AttentionValue,
}
