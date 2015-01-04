--- **Gemini:Timer-1.0** provides a central facility for registering timers.
-- GeminiTimer supports one-shot timers and repeating timers. All timers are stored in an efficient
-- data structure that allows easy dispatching and fast rescheduling. Timers can be registered, rescheduled
-- or canceled at any time, even from within a running timer, without conflict or large overhead.\\
-- GeminiTimer is currently limited to firing timers at a frequency of 0.1s. This constant may change
-- in the future, but for now it seemed like a good compromise in efficiency and accuracy.
--
-- All `:Schedule` functions will return a handle to the current timer, which you will need to store if you
-- need to cancel or reschedule the timer you just registered.
--
-- **Gemini:Timer-1.0** can be embeded into your addon, either explicitly by calling GeminiTimer:Embed(MyAddon) or by 
-- specifying it as an embeded library in your AceAddon. All functions will be available on your addon object
-- and can be accessed directly, without having to explicitly call GeminiTimer itself.\\
-- It is recommended to embed GeminiTimer, otherwise you'll have to specify a custom `self` on all calls you
-- make into GeminiTimer.
-- @class file
-- @name Gemini:Timer-1.0

--[[
	Basic assumptions:
	* In a typical system, we do more re-scheduling per second than there are timer pulses per second
	* Regardless of timer implementation, we cannot guarantee timely delivery due to FPS restriction (may be as low as 10)

	This implementation:
		CON: The smallest timer interval is constrained by HZ (currently 1/10s).
		PRO: It will still correctly fire any timer slower than HZ over a length of time, e.g. 0.11s interval -> 90 times over 10 seconds
		PRO: In lag bursts, the system simly skips missed timer intervals to decrease load
		CON: Algorithms depending on a timer firing "N times per minute" will fail
		PRO: (Re-)scheduling is O(1) with a VERY small constant. It's a simple linked list insertion in a hash bucket.
		CAUTION: The BUCKETS constant constrains how many timers can be efficiently handled. With too many hash collisions, performance will decrease.
		
	Major assumptions upheld:
	- ALLOWS scheduling multiple timers with the same funcref/method
	- ALLOWS scheduling more timers during OnUpdate processing
	- ALLOWS unscheduling ANY timer (including the current running one) at any time, including during OnUpdate processing
]]

local MAJOR, MINOR = "Gemini:Timer-1.0", 3
-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end
-- Set a reference to the actual package or create an empty table
local GeminiTimer = APkg and APkg.tPackage or {}

GeminiTimer.hash = GeminiTimer.hash or {}         -- Array of [0..BUCKET-1] = linked list of timers (using .next member)
GeminiTimer.selfs = GeminiTimer.selfs or {}       -- Array of [self]={[handle]=timerobj, [handle2]=timerobj2, ...}

-- Lua APIs
local assert, error, loadstring = assert, error, loadstring
local setmetatable, rawset, rawget = setmetatable, rawset, rawget
local select, pairs, type, next, tostring = select, pairs, type, next, tostring
local floor, max, min = math.floor, math.max, math.min
local tconcat = table.concat
local GetTime = os.clock

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: 

-- Simple ONE-SHOT timer cache. Much more efficient than a full compost for our purposes.
local timerCache = nil

--[[
	Timers will not be fired more often than HZ-1 times per second. 
	Keep at intended speed PLUS ONE or we get bitten by floating point rounding errors (n.5 + 0.1 can be n.599999)
	If this is ever LOWERED, all existing timers need to be enforced to have a delay >= 1/HZ on lib upgrade.
	If this number is ever changed, all entries need to be rehashed on lib upgrade.
	]]
local HZ = 11

--[[
	Prime for good distribution
	If this number is ever changed, all entries need to be rehashed on lib upgrade.
]]
local BUCKETS = 131

local hash = GeminiTimer.hash
for i=1,BUCKETS do
	hash[i] = hash[i] or false	-- make it an integer-indexed array; it's faster than hashes
end

--[[
	 xpcall safecall implementation
]]

local tLibError = Apollo.GetPackage("Gemini:LibError-1.0")
local fnErrorHandler = tLibError and tLibError.tPackage and tLibError.tPackage.Error or Print

local xpcall = xpcall

local function CreateDispatcher(argCount)
	local code = [[
		local xpcall, eh = ...	-- our arguments are received as unnamed values in "..." since we don't have a proper function declaration
		local method, ARGS
		local function call() return method(ARGS) end
	
		local function dispatch(func, ...)
			 method = func
			 if not method then return end
			 ARGS = ...
			 return xpcall(call, eh)
		end
	
		return dispatch
	]]
	
	local ARGS = {}
	for i = 1, argCount do ARGS[i] = "arg"..i end
	code = code:gsub("ARGS", tconcat(ARGS, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, fnErrorHandler)
end

local Dispatchers = setmetatable({}, {
	__index=function(self, argCount)
		local dispatcher = CreateDispatcher(argCount)
		rawset(self, argCount, dispatcher)
		return dispatcher
	end
})
Dispatchers[0] = function(func)
	return xpcall(func, fnErrorHandler)
end
 
local function safecall(func, ...)
	return Dispatchers[select('#', ...)](func, ...)
end

local lastint = floor(GetTime() * HZ)

-- --------------------------------------------------------------------
-- OnUpdate handler
--
-- traverse buckets, always chasing "now", and fire timers that have expired

local function OnUpdate()
	local now = GetTime()
	local nowint = floor(now * HZ)
	
	-- Have we passed into a new hash bucket?
	if nowint == lastint then return end
	
	local soon = now + 1 -- +1 is safe as long as 1 < HZ < BUCKETS/2
	
	-- Pass through each bucket at most once
	-- Happens on e.g. instance loads, but COULD happen on high local load situations also
	for curint = (max(lastint, nowint - BUCKETS) + 1), nowint do -- loop until we catch up with "now", usually only 1 iteration
		local curbucket = (curint % BUCKETS)+1
		-- Yank the list of timers out of the bucket and empty it. This allows reinsertion in the currently-processed bucket from callbacks.
		local nexttimer = hash[curbucket]
		hash[curbucket] = false -- false rather than nil to prevent the array from becoming a hash

		while nexttimer do
			local timer = nexttimer
			nexttimer = timer.next
			local when = timer.when
			
			if when < soon then
				-- Call the timer func, either as a method on given object, or a straight function ref
				local callback = timer.func
				if type(callback) == "string" then
					safecall(timer.object[timer.func], timer.object, unpack(timer.args, 1, timer.argCount))
				elseif callback then
					safecall(timer.func, unpack(timer.args, 1, timer.argCount))
				else
					-- probably nilled out by CancelTimer
					timer.delay = nil -- don't reschedule it
				end

				local delay = timer.delay	-- NOW make a local copy, can't do it earlier in case the timer cancelled itself in the callback
				
				if not delay then
					-- single-shot timer (or cancelled)
					GeminiTimer.selfs[timer.object][tostring(timer)] = nil
					timerCache = timer
				else
					-- repeating timer
					local newtime = when + delay
					if newtime < now then -- Keep lag from making us firing a timer unnecessarily. (Note that this still won't catch too-short-delay timers though.)
						newtime = now + delay
					end
					timer.when = newtime
					
					-- add next timer execution to the correct bucket
					local bucket = (floor(newtime * HZ) % BUCKETS) + 1
					timer.next = hash[bucket]
					hash[bucket] = timer
				end
			else -- if when>=soon 
				-- reinsert (yeah, somewhat expensive, but shouldn't be happening too often either due to hash distribution)
				timer.next = hash[curbucket]
				hash[curbucket] = timer
			end -- if when<soon ... else
		end -- while nexttimer do
	end -- for curint=lastint,nowint
	
	lastint = nowint
end

-- ---------------------------------------------------------------------
-- new( repeating, func , delay, args )
--
-- repeating(boolean) - repeating timer, or oneshot
-- func( function or string ) - direct function ref or method name in our object for the function
-- delay(int) - delay for the timer
-- args(variant) - any arguments to be passed to the callback function
--
-- returns the handle of the timer for later processing (canceling etc)
local function new(self, repeating, func, delay, ...)
	if delay < (1 / (HZ - 1)) then
		delay = 1 / (HZ - 1)
	end
	
	-- Create and stuff timer in the correct hash bucket
	local now = GetTime()
	local timer = timerCache or {}	-- Get new timer object (from cache if available)
	timerCache = nil
	
	timer.object = self
	timer.func = func
	timer.delay = (repeating and delay)
	timer.args = { ... }
	timer.argCount = select("#", ...)
	timer.when = now + delay

	local bucket = (floor((now+delay)*HZ) % BUCKETS) + 1
	timer.next = hash[bucket]
	hash[bucket] = timer

	-- Insert timer in our self->handle->timer registry
	local handle = tostring(timer)
	
	local selftimers = GeminiTimer.selfs[self]
	if not selftimers then
		selftimers = {}
		GeminiTimer.selfs[self] = selftimers
	end
	selftimers[handle] = timer
	selftimers.__ops = (selftimers.__ops or 0) + 1

	return handle
end

--- Schedule a new one-shot timer.
-- The timer will fire once in `delay` seconds, unless canceled before.
-- @param func Callback function for the timer pulse (funcref or method name).
-- @param delay Delay for the timer, in seconds.
-- @param args Optional arguments to be passed to the callback function.
-- @usage
-- MyAddon = Apollo.GetPackage("Gemini:Addon-1.0").tPackage:NewAddon("TimerTest", false, {}, "Gemini:Timer-1.0")
-- 
-- function MyAddon:OnEnable()
--   local strConfirm = ", really!"
--   self:ScheduleTimer("TimerFeedback", 5, strConfirm)
-- end
--
-- function MyAddon:TimerFeedback(strPassed)
--   Print("5 seconds passed" .. strPased)
-- end
function GeminiTimer:ScheduleTimer(func, delay, ...)
	if not func or not delay then
		error(MAJOR..": ScheduleTimer(callback, delay, args...): 'callback' and 'delay' must have set values.", 2)
	end
	if type(func) == "string" then
		if type(self) ~= "table" then
			error(MAJOR..": ScheduleTimer(callback, delay, args...): 'self' - must be a table.", 2)
		elseif not self[func] then
			error(MAJOR..": ScheduleTimer(callback, delay, args...): Tried to register '"..func.."' as the callback, but it doesn't exist in the module.", 2)
		end
	end
	return new(self, nil, func, delay, ...)
end

--- Schedule a repeating timer.
-- The timer will fire every `delay` seconds, until canceled.
-- @param func Callback function for the timer pulse (funcref or method name).
-- @param delay Delay for the timer, in seconds.
-- @param args Optional arguments to be passed to the callback function.
-- @usage
-- MyAddon = Apollo.GetPackage("Gemini:Addon-1.0").tPackage:NewAddon("TimerTest", false, {}, "Gemini:Timer-1.0")
-- 
-- function MyAddon:OnEnable()
--   self.timerCount = 0
--   self.testTimer = self:ScheduleRepeatingTimer("TimerFeedback", 5)
-- end
--
-- function MyAddon:TimerFeedback()
--   self.timerCount = self.timerCount + 1
--   print(("%d seconds passed"):format(5 * self.timerCount))
--   -- run 30 seconds in total
--   if self.timerCount == 6 then
--     self:CancelTimer(self.testTimer)
--   end
-- end
function GeminiTimer:ScheduleRepeatingTimer(func, delay, ...)
	if not func or not delay then
		error(MAJOR..": ScheduleRepeatingTimer(callback, delay, args...): 'callback' and 'delay' must have set values.", 2)
	end
	if type(func) == "string" then
		if type(self) ~= "table" then
			error(MAJOR..": ScheduleRepeatingTimer(callback, delay, args...): 'self' - must be a table.", 2)
		elseif not self[func] then
			error(MAJOR..": ScheduleRepeatingTimer(callback, delay, args...): Tried to register '"..func.."' as the callback, but it doesn't exist in the module.", 2)
		end
	end
	return new(self, true, func, delay, ...)
end

--- Cancels a timer with the given handle, registered by the same addon object as used for `:ScheduleTimer`
-- Both one-shot and repeating timers can be canceled with this function, as long as the `handle` is valid
-- and the timer has not fired yet or was canceled before.
-- @param handle The handle of the timer, as returned by `:ScheduleTimer` or `:ScheduleRepeatingTimer`
-- @param silent If true, no error is raised if the timer handle is invalid (expired or already canceled)
-- @return True if the timer was successfully cancelled.
function GeminiTimer:CancelTimer(handle, silent)
	if not handle then return end -- nil handle -> bail out without erroring
	if type(handle) ~= "string" then
		error(MAJOR..": CancelTimer(handle): 'handle' - expected a string", 2)	-- for now, anyway
	end
	local selftimers = GeminiTimer.selfs[self]
	local timer = selftimers and selftimers[handle]
	if silent then
		if timer then
			timer.func = nil	-- don't run it again
			timer.delay = nil	-- if this is the currently-executing one: don't even reschedule 
			-- The timer object is removed in the OnUpdate loop
		end
		return not not timer	-- might return "true" even if we double-cancel. we'll live.
	else
		if not timer then
			error(MAJOR..": CancelTimer(handle[, silent]): '"..tostring(handle).."' - no such timer registered")
			return false
		end
		if not timer.func then 
			error(MAJOR..": CancelTimer(handle[, silent]): '"..tostring(handle).."' - timer already cancelled or expired")
			return false
		end
		timer.func = nil		-- don't run it again
		timer.delay = nil		-- if this is the currently-executing one: don't even reschedule 
		return true
	end
end

--- Cancels all timers registered to the current addon object ('self')
function GeminiTimer:CancelAllTimers()
	if not(type(self) == "string" or type(self) == "table") then
		error(MAJOR..": CancelAllTimers(): 'self' - must be a string or a table",2)
	end
	if self == GeminiTimer then
		error(MAJOR..": CancelAllTimers(): supply a meaningful 'self'", 2)
	end
	
	local selftimers = GeminiTimer.selfs[self]
	if selftimers then
		for handle,v in pairs(selftimers) do
			if type(v) == "table" then  -- avoid __ops, etc
				GeminiTimer.CancelTimer(self, handle, true)
			end
		end
	end
end

--- Returns the time left for a timer with the given handle, registered by the current addon object ('self').
-- This function will raise a warning when the handle is invalid, but not stop execution.
-- @param handle The handle of the timer, as returned by `:ScheduleTimer` or `:ScheduleRepeatingTimer`
-- @return The time left on the timer, or false if the handle is invalid.
function GeminiTimer:TimeLeft(handle)
	if not handle then return end
	if type(handle) ~= "string" then
		error(MAJOR..": TimeLeft(handle): 'handle' - expected a string", 2)    -- for now, anyway
	end
	local selftimers = GeminiTimer.selfs[self]
	local timer = selftimers and selftimers[handle]
	if not timer then
		error(MAJOR..": TimeLeft(handle): '"..tostring(handle).."' - no such timer registered")
		return false
	end
	return timer.when - GetTime()
end


-- ---------------------------------------------------------------------
-- When we exit combat: Run through our .selfs[] array step by step
-- and clean it out - otherwise the table indices can grow indefinitely
-- if an addon starts and stops a lot of timers. GeminiBucket does this!
--

local lastCleaned = nil

local function OnExitCombat()
	-- Get the next 'self' to process
	local selfs = GeminiTimer.selfs
	local self = next(selfs, lastCleaned)
	if not self then
		self = next(selfs)
	end
	lastCleaned = self
	if not self then	-- should only happen if .selfs[] is empty
		return
	end
	
	-- Time to clean it out?
	local list = selfs[self]
	if (list.__ops or 0) < 250 then	-- 250 slosh indices = ~10KB wasted (worst case!). For one 'self'.
		return
	end
	
	-- Create a new table and copy all members over
	local newlist = {}
	local n=0
	for k,v in pairs(list) do
		newlist[k] = v
		if type(v)=="table" and v.callback then -- if the timer is actually live: count it
			n=n+1
		end
	end
	newlist.__ops = 0	-- Reset operation count
	
	-- And since we now have a count of the number of live timers, check that it's reasonable. Emit a warning if not.
	if n>BUCKETS then
		Print(MAJOR..": Warning: The addon/module '"..tostring(self).."' has "..n.." live timers. Surely that's not intended?")
	end
	
	selfs[self] = newlist
end

-- ---------------------------------------------------------------------
-- Embed handling

GeminiTimer.embeds = GeminiTimer.embeds or {}

local mixins = {
	"ScheduleTimer", "ScheduleRepeatingTimer", 
	"CancelTimer", "CancelAllTimers",
	"TimeLeft"
}

function GeminiTimer:Embed(target)
	GeminiTimer.embeds[target] = true
	for _,v in pairs(mixins) do
		target[v] = GeminiTimer[v]
	end
	return target
end

-- GeminiTimer:OnEmbedDisable( target )
-- target (object) - target object that GeminiTimer is embedded in.
--
-- cancel all timers registered for the object
function GeminiTimer:OnEmbedDisable( target )
	target:CancelAllTimers()
end


for addon in pairs(GeminiTimer.embeds) do
	GeminiTimer:Embed(addon)
end

-- ---------------------------------------------------------------------
-- Debug tools (expose copies of internals to test suites)
GeminiTimer.debug = GeminiTimer.debug or {}
GeminiTimer.debug.HZ = HZ
GeminiTimer.debug.BUCKETS = BUCKETS

-- ---------------------------------------------------------------------
-- Finishing touchups

function GeminiTimer:OnFrameChange()
	OnUpdate()
end

function GeminiTimer:OnEnteredCombat(unitChecked, bInCombat)
	if unitChecked == GameLib.GetPlayerUnit() and not bInCombat then
		OnExitCombat()
	end
end

-- Initialization routines
function GeminiTimer:OnLoad()
	Apollo.RegisterEventHandler("NextFrame", "OnFrameChange", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
end

function GeminiTimer:OnDependencyError(strDep, strError) return false end

Apollo.RegisterPackage(GeminiTimer, MAJOR, MINOR, {})