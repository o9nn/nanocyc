-- a9nn/tensor.lua
-- Pure-Lua tensor implementation for environments without Torch.
-- Provides a minimal but functional N-dimensional tensor with math ops.
-- When Torch is present, this module is bypassed and torch.Tensor is used.

local Tensor = {}
Tensor.__index = Tensor

-- ─── Constructor ──────────────────────────────────────────────────────────────

--- Create a new 1-D or 2-D Tensor.
-- @param data   table of numbers (flat) or nil
-- @param rows   number of rows  (for 2-D)
-- @param cols   number of cols  (for 2-D, optional)
function Tensor.new(data, rows, cols)
   local t = setmetatable({}, Tensor)
   if type(data) == "table" then
      t.data  = {}
      for i, v in ipairs(data) do t.data[i] = v end
      t.size_ = {#data}
   elseif type(data) == "number" then
      -- Tensor.new(n)  →  1-D of length n
      t.data  = {}
      for i = 1, data do t.data[i] = 0 end
      t.size_ = {data}
   elseif rows and cols then
      t.data  = {}
      for i = 1, rows * cols do t.data[i] = 0 end
      t.size_ = {rows, cols}
   elseif rows then
      t.data  = {}
      for i = 1, rows do t.data[i] = 0 end
      t.size_ = {rows}
   else
      t.data  = {}
      t.size_ = {0}
   end
   return t
end

--- Create a zero tensor of the given shape.
function Tensor.zeros(...)
   local args = {...}
   local t = setmetatable({}, Tensor)
   if #args == 1 then
      t.data  = {}
      for i = 1, args[1] do t.data[i] = 0 end
      t.size_ = {args[1]}
   elseif #args == 2 then
      t.data  = {}
      for i = 1, args[1] * args[2] do t.data[i] = 0 end
      t.size_ = {args[1], args[2]}
   end
   return t
end

--- Create a tensor filled with ones.
function Tensor.ones(...)
   local t = Tensor.zeros(...)
   for i = 1, #t.data do t.data[i] = 1 end
   return t
end

--- Create a tensor filled with uniform random values in [0,1).
function Tensor.rand(...)
   local t = Tensor.zeros(...)
   for i = 1, #t.data do t.data[i] = math.random() end
   return t
end

--- Create a tensor filled with standard-normal random values.
function Tensor.randn(...)
   local t = Tensor.zeros(...)
   for i = 1, #t.data do
      -- Box-Muller transform
      local u1 = math.max(math.random(), 1e-10)
      local u2 = math.random()
      t.data[i] = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
   end
   return t
end

-- ─── Shape helpers ────────────────────────────────────────────────────────────

function Tensor:nDim()    return #self.size_ end
function Tensor:size(dim) return dim and self.size_[dim] or self.size_ end
function Tensor:nElement()
   local n = 1
   for _, s in ipairs(self.size_) do n = n * s end
   return n
end

function Tensor:__tostring()
   if #self.size_ == 1 then
      local parts = {}
      for _, v in ipairs(self.data) do
         parts[#parts+1] = string.format("%.4f", v)
      end
      return "Tensor[" .. table.concat(parts, ", ") .. "]"
   else
      local r, c = self.size_[1], self.size_[2]
      local lines = {}
      for i = 1, r do
         local row = {}
         for j = 1, c do
            row[#row+1] = string.format("%.4f", self.data[(i-1)*c + j])
         end
         lines[#lines+1] = "  " .. table.concat(row, "  ")
      end
      return "Tensor[\n" .. table.concat(lines, "\n") .. "\n]"
   end
end

-- ─── Element access ───────────────────────────────────────────────────────────

function Tensor:get(...)
   local idx = {...}
   if #self.size_ == 1 then
      return self.data[idx[1]]
   else
      local r, c = idx[1], idx[2]
      return self.data[(r-1) * self.size_[2] + c]
   end
end

function Tensor:set(...)
   local args = {...}
   if #self.size_ == 1 then
      self.data[args[1]] = args[2]
   else
      self.data[(args[1]-1) * self.size_[2] + args[2]] = args[3]
   end
end

-- ─── Arithmetic ───────────────────────────────────────────────────────────────

function Tensor:clone()
   local t = setmetatable({}, Tensor)
   t.data  = {}
   for i, v in ipairs(self.data) do t.data[i] = v end
   t.size_ = {}
   for i, v in ipairs(self.size_) do t.size_[i] = v end
   return t
end

function Tensor:fill(v)
   for i = 1, #self.data do self.data[i] = v end
   return self
end

function Tensor:zero()  return self:fill(0) end

function Tensor:add(other)
   local out = self:clone()
   if type(other) == "number" then
      for i = 1, #out.data do out.data[i] = out.data[i] + other end
   else
      assert(#self.data == #other.data, "Tensor size mismatch in add")
      for i = 1, #out.data do out.data[i] = out.data[i] + other.data[i] end
   end
   return out
end

function Tensor:sub(other)
   local out = self:clone()
   if type(other) == "number" then
      for i = 1, #out.data do out.data[i] = out.data[i] - other end
   else
      assert(#self.data == #other.data, "Tensor size mismatch in sub")
      for i = 1, #out.data do out.data[i] = out.data[i] - other.data[i] end
   end
   return out
end

function Tensor:mul(scalar)
   local out = self:clone()
   for i = 1, #out.data do out.data[i] = out.data[i] * scalar end
   return out
end

function Tensor:cmul(other)
   assert(#self.data == #other.data, "Tensor size mismatch in cmul")
   local out = self:clone()
   for i = 1, #out.data do out.data[i] = out.data[i] * other.data[i] end
   return out
end

function Tensor:cdiv(other)
   assert(#self.data == #other.data, "Tensor size mismatch in cdiv")
   local out = self:clone()
   for i = 1, #out.data do out.data[i] = out.data[i] / (other.data[i] + 1e-12) end
   return out
end

--- Matrix multiply: (m×k) × (k×n) → (m×n)
function Tensor:mm(other)
   assert(#self.size_ == 2 and #other.size_ == 2, "mm requires 2-D tensors")
   local m, k1, k2, n = self.size_[1], self.size_[2], other.size_[1], other.size_[2]
   assert(k1 == k2, "Incompatible shapes for mm: " .. k1 .. " vs " .. k2)
   local out = Tensor.zeros(m, n)
   for i = 1, m do
      for j = 1, n do
         local s = 0
         for k = 1, k1 do
            s = s + self.data[(i-1)*k1+k] * other.data[(k-1)*n+j]
         end
         out.data[(i-1)*n+j] = s
      end
   end
   return out
end

--- Matrix-vector multiply: (m×n) × (n,) → (m,)
function Tensor:mv(vec)
   assert(#self.size_ == 2 and #vec.size_ == 1, "mv: need 2-D matrix and 1-D vector")
   local m, n = self.size_[1], self.size_[2]
   assert(n == #vec.data, "Incompatible shapes for mv")
   local out = Tensor.zeros(m)
   for i = 1, m do
      local s = 0
      for j = 1, n do
         s = s + self.data[(i-1)*n+j] * vec.data[j]
      end
      out.data[i] = s
   end
   return out
end

--- Transpose of a 2-D tensor.
function Tensor:t()
   assert(#self.size_ == 2, "t() requires 2-D tensor")
   local r, c = self.size_[1], self.size_[2]
   local out = Tensor.zeros(c, r)
   for i = 1, r do
      for j = 1, c do
         out.data[(j-1)*r+i] = self.data[(i-1)*c+j]
      end
   end
   return out
end

--- Apply element-wise function.
function Tensor:apply(fn)
   local out = self:clone()
   for i = 1, #out.data do out.data[i] = fn(out.data[i]) end
   return out
end

function Tensor:sum()
   local s = 0
   for _, v in ipairs(self.data) do s = s + v end
   return s
end

function Tensor:mean()  return self:sum() / #self.data end
function Tensor:max()
   local m = self.data[1] or 0
   for _, v in ipairs(self.data) do if v > m then m = v end end
   return m
end
function Tensor:min()
   local m = self.data[1] or 0
   for _, v in ipairs(self.data) do if v < m then m = v end end
   return m
end
function Tensor:norm()
   local s = 0
   for _, v in ipairs(self.data) do s = s + v * v end
   return math.sqrt(s)
end

function Tensor:reshape(...)
   local args = {...}
   local total = 1
   for _, d in ipairs(args) do total = total * d end
   assert(total == #self.data, "Reshape: total elements must match")
   local out = self:clone()
   out.size_ = args
   return out
end

-- Concatenate two 1-D tensors
function Tensor.cat(a, b)
   assert(#a.size_ == 1 and #b.size_ == 1, "cat: only 1-D supported")
   local out = Tensor.zeros(#a.data + #b.data)
   for i, v in ipairs(a.data) do out.data[i] = v end
   for i, v in ipairs(b.data) do out.data[#a.data + i] = v end
   return out
end

--- Slice a 1-D tensor [from, to] (1-indexed, inclusive).
function Tensor:slice(from, to)
   assert(#self.size_ == 1, "slice: only 1-D supported")
   to = to or #self.data
   local out = Tensor.zeros(to - from + 1)
   for i = from, to do out.data[i - from + 1] = self.data[i] end
   return out
end

--- Uniform initialisation: each element ∈ [-stdv, stdv]
function Tensor:uniform(stdv)
   stdv = stdv or 1
   for i = 1, #self.data do
      self.data[i] = (math.random() * 2 - 1) * stdv
   end
   return self
end

--- Normal initialisation: N(mean, std)
function Tensor:normal(mean, std)
   mean = mean or 0
   std  = std  or 1
   for i = 1, #self.data do
      local u1 = math.max(math.random(), 1e-10)
      local u2 = math.random()
      self.data[i] = mean + std * math.sqrt(-2*math.log(u1)) * math.cos(2*math.pi*u2)
   end
   return self
end

math.pi = math.pi or 3.141592653589793

return Tensor
