-- a9nn/class.lua
-- Lightweight class system that mirrors torch.class() semantics.
-- Used when Torch is not available.

local Class = {}
Class._registry = {}

--- Declare a new class, optionally inheriting from a parent.
-- @param name     string like 'nn.Linear'
-- @param parent   string like 'nn.Module' (optional)
-- @return class-table (also callable as constructor), parent class-table
function Class.class(name, parent)
   local cls = {}
   -- cls.__index = cls  allows instances to find methods in cls
   cls.__index = cls
   cls.__name  = name

   -- The metatable for the class object itself:
   --   __call  → creates instances
   --   __index → inherits methods from parent (NOT from cls, to avoid loops)
   local classMT = {}
   classMT.__call = function(klass, ...)
      local inst = setmetatable({}, klass)
      if inst.__init then inst:__init(...) end
      return inst
   end

   if parent then
      local parentCls = Class._registry[parent]
      assert(parentCls, "Parent class not found: " .. tostring(parent))
      -- Method inheritance: if cls lacks a method, look in parentCls
      classMT.__index = parentCls
      cls._parent     = parentCls
   end

   setmetatable(cls, classMT)

   Class._registry[name] = cls
   return cls, parent and Class._registry[parent] or nil
end

--- Look up a registered class by name.
function Class.get(name)
   return Class._registry[name]
end

--- Return the class name of an instance.
function Class.typename(inst)
   local mt = getmetatable(inst)
   return mt and mt.__name or tostring(inst)
end

--- Check if inst is an instance of class named `name`.
function Class.isInstanceOf(inst, name)
   local mt = getmetatable(inst)
   while mt do
      if mt.__name == name then return true end
      mt = getmetatable(mt)
      if mt then mt = mt.__index end
   end
   return false
end

return Class
