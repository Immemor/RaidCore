LibJSON
=======

dkJSON for Wildstar, now in package format!

For examples and documentation see the [dkJSON wiki](http://dkolf.de/src/dkjson-lua.fsl/wiki?name=Documentation)

As Wildstar does not have the LPeg library there is no LPeg support.

Short Example assuming a window (wndMain) with a JSONOutput Editbox/Label/Window:
```lua
function MyAddon:OnTest()
	local tTestTable = {
		foo = "Bar",
		baz = { "Bat", 5 },
		5,
	}
	local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
	self.wndMain:FindChild("JSONOutput"):SetText(JSON.encode(tTestTable))
end
```