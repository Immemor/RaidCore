GeminiTimer
===========

Wildstar Library - provides a central facility for registering timers that accept arguments.

GeminiTimer-1.0 provides a central facility for registering timers. 
GeminiTimer supports one-shot timers and repeating timers. All timers are stored in an efficient data structure that allows easy dispatching and fast rescheduling. Timers can be registered or canceled at any time, even from within a running timer, without conflict or large overhead.
GeminiTimer is currently limited to firing timers at a frequency of 0.1s.

All `:Schedule` functions will return a handle to the current timer, which you will need to store if you need to cancel the timer you just registered.

GeminiTimer-1.0 can be embeded into your addon, either explicitly by calling GeminiTimer:Embed(MyAddon) or by specifying it as an embeded library in your GeminiAddon. All functions will be available on your addon object and can be accessed directly, without having to explicitly call GeminiTimer itself.
It is recommended to embed GeminiTimer, otherwise you'll have to specify a custom `self` on all calls you make into GeminiTimer.



##GeminiTimer:CancelAllTimers()
Cancels all timers registered to the current addon object ('self')



##GeminiTimer:CancelTimer(id)
Cancels a timer with the given id, registered by the same addon object as used for `:ScheduleTimer` Both one-shot and repeating timers can be canceled with this function, as long as the `id` is valid and the timer has not fired yet or was canceled before.

###Parameters

**id**

		The id of the timer, as returned by `:ScheduleTimer` or `:ScheduleRepeatingTimer`


##GeminiTimer:ScheduleRepeatingTimer(func, delay, ...)
Schedule a repeating timer. 
The timer will fire every `delay` seconds, until canceled.

###Parameters

**func**

		Function to be called when the timer expires

**delay**

		Delay for the timer, in seconds.
**...**

		An optional, unlimited amount of arguments to pass to the callback function.

###Returns

**id**

		Id with which to identify this timer with (For CancelTimer)
		
###Usage

```lua
MyAddOn = Apollo.GetPackage("Gemini:Addon-1.0").tPackage:NewAddon("MyAddOn", false, {}, "Gemini:Timer-1.0")

function MyAddOn:OnEnable()
  self.timerCount = 0
  self.testTimer = self:ScheduleRepeatingTimer("TimerFeedback", 5)
end

function MyAddOn:TimerFeedback()
  self.timerCount = self.timerCount + 1
  Print(("%d seconds passed"):format(5 * self.timerCount))
  -- run 30 seconds in total
  if self.timerCount == 6 then
    self:CancelTimer(self.testTimer)
  end
end
```


##GeminiTimer:ScheduleTimer(func, delay, ...)
Schedule a new one-shot timer. 
The timer will fire once in `delay` seconds, unless canceled before.

###Parameters

**func**

		Function to be called when the timer expires

**delay**

		Delay for the timer, in seconds.

**...**

		An optional, unlimited amount of arguments to pass to the callback function.
###Returns

**id**

		Id with which to identify this timer with (For CancelTimer)
		
###Usage

```lua
MyAddOn = Apollo.GetPackage("Gemini:Addon-1.0").tPackage:NewAddon("MyAddOn", false, {}, "Gemini:Timer-1.0")

function MyAddOn:OnEnable()
  self:ScheduleTimer("TimerFeedback", 5)
end

function MyAddOn:TimerFeedback()
  Print("5 seconds passed")
end
```


##GeminiTimer:TimeLeft(id)
Returns the time left for a timer with the given id, registered by the current addon object ('self'). 
This function will return 0 when the id is invalid.

###Parameters

**id**

		The id of the timer, as returned by `:ScheduleTimer` or `:ScheduleRepeatingTimer`

###Return value

The time left on the timer.
