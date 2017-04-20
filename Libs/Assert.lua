----------------------------------------------------------------------------------------------------
-- Lua library Script for WildStar.
--
-- Copyright (C) 2016 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- This library adds different types of asserts
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local string = require "string"

local MAJOR, MINOR = "RaidCore:Assert-1.0", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then
  return -- no upgrade is needed
end
local assert, next, type = assert, next, type
local Assert = APkg and APkg.tPackage or {}
Assert.TYPES = {
  STRING = "string",
  NUMBER = "number",
  TABLE = "table",
  FUNCTION = "function",
  BOOL = "boolean",
  NIL = "nil",
  USERDATA = "userdata",
}

function Assert:Assert(condition, errorMessage, ...)
  if type(errorMessage) == "string" then
    errorMessage = string.format(errorMessage, ...)
  end
  assert(condition, errorMessage)
end

function Assert:EmptyTable(table, errorMessage, ...)
  self:Assert(next(table) ~= nil, errorMessage, ...)
end

function Assert:Equal(firstObject, secondObject, errorMessage, ...)
  self:Assert(firstObject == secondObject, errorMessage, ...)
end

function Assert:NotEqual(firstObject, secondObject, errorMessage, ...)
  self:Assert(firstObject ~= secondObject, errorMessage, ...)
end

function Assert:EqualOr(object, objects, errorMessage, ...)
  local objFound = false
  for i = 1, #objects do
    if object == objects[i] then
      objFound = true
      break
    end
  end
  self:Assert(objFound, errorMessage, ...)
end

function Assert:Type(object, typeName, errorMessage, ...)
  self:Assert(type(object) == typeName, errorMessage, ...)
end

function Assert:NotType(object, typeName, errorMessage, ...)
  self:Assert(type(object) ~= typeName, errorMessage, ...)
end

function Assert:NotNilOrFalse(object, errorMessage, ...)
  self:Assert(object, errorMessage, ...)
end

function Assert:TypeOr(object, types, errorMessage, ...)
  local typeName = type(object)
  local typeFound = false
  for i = 1, #types do
    if typeName == types[i] then
      typeFound = true
      break
    end
  end
  self:Assert(typeFound, errorMessage, ...)
end

function Assert:Table(table, errorMessage, ...)
  self:Type(table, self.TYPES.TABLE, errorMessage, ...)
end

function Assert:NotTable(table, errorMessage, ...)
  self:NotType(table, self.TYPES.TABLE, errorMessage, ...)
end

function Assert:String(str, errorMessage, ...)
  self:Type(str, self.TYPES.STRING, errorMessage, ...)
end

function Assert:NotString(str, errorMessage, ...)
  self:NotType(str, self.TYPES.STRING, errorMessage, ...)
end

function Assert:Bool(bool, errorMessage, ...)
  self:Type(bool, self.TYPES.BOOL, errorMessage, ...)
end

function Assert:NotBool(bool, errorMessage, ...)
  self:NotType(bool, self.TYPES.BOOL, errorMessage, ...)
end

function Assert:Function(func, errorMessage, ...)
  self:Type(func, self.TYPES.FUNCTION, errorMessage, ...)
end

function Assert:NotFunction(func, errorMessage, ...)
  self:NotType(func, self.TYPES.FUNCTION, errorMessage, ...)
end

function Assert:Nil(nilObject, errorMessage, ...)
  self:Type(nilObject, self.TYPES.NIL, errorMessage, ...)
end

function Assert:NotNil(nilObject, errorMessage, ...)
  self:NotType(nilObject, self.TYPES.NIL, errorMessage, ...)
end

function Assert:Userdata(userdata, errorMessage, ...)
  self:Type(userdata, self.TYPES.USERDATA, errorMessage, ...)
end

function Assert:NotUserdata(userdata, errorMessage, ...)
  self:NotType(userdata, self.TYPES.USERDATA, errorMessage, ...)
end

function Assert:Number(number, errorMessage, ...)
  self:Type(number, self.TYPES.NUMBER, errorMessage, ...)
end

function Assert:NotNumber(number, errorMessage, ...)
  self:NotType(number, self.TYPES.NUMBER, errorMessage, ...)
end

Apollo.RegisterPackage(Assert, MAJOR, MINOR, {})
