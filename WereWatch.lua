-- WereWatch
-- by gobbo (@gobbo1008)
WereWatch = {}
WereWatch.name = "WereWatch"
 
function WereWatch:Initialize()
	self.savedVariables = ZO_SavedVars:New("WereWatchSavedVariables", 1, nil, {})
	self.werewolf = IsWerewolf()
	local left = self.savedVariables.left
	local top = self.savedVariables.top
	WereWatchUI:ClearAnchors()
	WereWatchUI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end -- function
 
-- Load handler
function WereWatch.OnAddOnLoaded(event, addonName)
	if addonName == WereWatch.name then
		WereWatch:Initialize()
	end -- if
end -- function

local timelastrun = 0
function WereWatch.OnUpdate(timerun)
	if WereWatch.running then
		if (timerun - timelastrun) >= 0.1 then
			timelastrun = timerun
			WereWatchUILabel:SetText(WereWatch.ToMinSec(GetTimeStamp() - WereWatch.startTime))
		end -- if timerun - timelastrun
	elseif ((timerun - timelastrun) >= 5) and ((timerun - timelastrun) <= 6) then
		WereWatchUI:SetHidden(true)
	end -- if WereWatch.running
end -- function

function WereWatch.OnIndicatorMoveStop()
	WereWatch.savedVariables.left = WereWatchUI:GetLeft()
	WereWatch.savedVariables.top = WereWatchUI:GetTop()
end -- function

function WereWatch.OnWerewolfStateChanged(eventCode, werewolf)
	if werewolf ~= WereWatch.werewolf then
		-- state changed from previous
		WereWatch.werewolf = werewolf
		if werewolf then
			-- player turned into werewolf
			-- start the stopwatch
			WereWatch.startTime = GetTimeStamp()
			WereWatch.running = true
			WereWatchUI:SetHidden(false)
		else
			-- player turned into human again
			-- stop the stopwatch
			WereWatch.stopTime = GetTimeStamp()
			WereWatch.running = false
			-- calculate time difference and break down into minutes and seconds
			WereWatch.deltaTime = GetDiffBetweenTimeStamps(WereWatch.stopTime, WereWatch.startTime)
			-- announce to player
			d("[WereWatch] You held your werewolf form for ".. WereWatch.ToMinSec(WereWatch.deltaTime) .. ".")
		end -- if werewolf
	end -- if werewolf ~= WereWatch.werewolf
end -- function

function WereWatch.ToMinSec(timestamp)
	timestamp = math.floor(timestamp)
	local minutes = math.floor(timestamp/60)
	if minutes < 10 then
		minutes = "0" .. minutes
	end -- if
	local seconds = timestamp % 60
	if seconds < 10 then
		seconds = "0" .. seconds
	end -- if
	return minutes .. ":" .. seconds
end -- function

SLASH_COMMANDS["/ww"] = function(arg)
	if arg == "show" then
		WereWatchUI:SetHidden(false)
	elseif arg == "hide" then
		WereWatchUI:SetHidden(true)
	elseif arg == "start" then
		WereWatch.OnWerewolfStateChanged("debug", true)
	elseif arg == "stop" then
		WereWatch.OnWerewolfStateChanged("debug", false)
	elseif arg == "pos" then
		d("[WereWatch] Timer position: " .. WereWatchUI:GetLeft() .. ", " .. WereWatchUI:GetTop())
	end -- if
end -- function

EVENT_MANAGER:RegisterForEvent(WereWatch.name, EVENT_ADD_ON_LOADED, WereWatch.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(WereWatch.name, EVENT_WEREWOLF_STATE_CHANGED, WereWatch.OnWerewolfStateChanged)