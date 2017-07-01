-- WereWatch
-- by gobbo (@gobbo1008)
WereWatch = {}
WereWatch.name = "WereWatch"
WereWatch.version = 1.3
 
function WereWatch:Initialize()
	self.savedVariables = ZO_SavedVars:New("WereWatchSavedVariables", 1, nil, {})
	self.werewolf = IsWerewolf()
	local left = self.savedVariables.left
	local top = self.savedVariables.top
	if self.savedVariables.bestTime == nil then
		self.savedVariables.bestTime = 0
	end -- if
	WereWatchUI:ClearAnchors()
	WereWatchUI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
	WereWatch.evalOptions()
	-- Here be LibAddonMenu dragons
	local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")
	local panelData = {
		type = "panel",
		name = "WereWatch",
		author = "gobbo",
		version = "" .. WereWatch.version,
		registerForRefresh = true,
    }
	LAM:RegisterAddonPanel("WereWatchOptions", panelData)
	local optionsData = {
		[1] = {
			type = "checkbox",
			name = "Enable timer",
			tooltip = "Enables the timer UI element.",
			getFunc = function() return WereWatch.savedVariables.optionsTimer end,
			setFunc = function(value)
					WereWatch.savedVariables.optionsTimer = value
					WereWatch.evalOptions()
					if not value then
						WereWatchUI:SetHidden(true)
					end
				end,
		},
		[2] = {
			type = "checkbox",
			name = "Enable chat message",
			tooltip = "Enables the chat message at the end of the werewolf run.",
			getFunc = function() return WereWatch.savedVariables.optionsMessage end,
			setFunc = function(value) WereWatch.savedVariables.optionsMessage = value end,
		},
		[3] = {
			type = "checkbox",
			name = "Force-show timer",
			tooltip = "Force-shows the timer to allow you to place it where you want it. Will auto-hide on next transformation back to human.",
			getFunc = function() return not WereWatchUI:IsHidden() end,
			setFunc = function(value) WereWatchUI:SetHidden(not value) end,
		},
		[4] = {
			type = "description",
			-- width = "half",
			reference = "WereWatchOptionsBestTime",
			title = "Current best time: " .. WereWatch.ToMinSec(WereWatch.savedVariables.bestTime),
		},
		[5] = {
			type = "button",
			width = "half",
			name = "Reset best time",
			tooltip = "Resets your best time.",
			func = function() WereWatch.savedVariables.bestTime = 0 end,
		},
		[6] = {
			type = "button",
			width = "half",
			name = "Reset timer position",
			tooltip = "Should you have accidentally moved the timer somwhere you can't reach it, this will reset it to the upper left corner of the screen.",
			func = function() 
					WereWatchUI:ClearAnchors()
					WereWatchUI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)
				end,
		},
		[7] = {
			-- Helper control to refresh the best time label. Not sure if this is neccessary, but it works.
			-- Please open an issue or a pull request if there is a better or easier way to do it, I'm new to this stuff
			type = "custom",
			refreshFunc = function()
					WereWatchOptionsBestTime.data.title = "Current best time: " .. WereWatch.ToMinSec(WereWatch.savedVariables.bestTime)
					WereWatchOptionsBestTime.UpdateValue(WereWatchOptionsBestTime)
				end,
		},
	}
	LAM:RegisterOptionControls("WereWatchOptions", optionsData)
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
			if (WereWatch.savedVariables.optionsTimer) then
				WereWatchUI:SetHidden(false)
			end -- if
		else
			-- player turned into human again
			-- stop the stopwatch
			WereWatch.stopTime = GetTimeStamp()
			WereWatch.running = false
			-- calculate time difference
			WereWatch.deltaTime = GetDiffBetweenTimeStamps(WereWatch.stopTime, WereWatch.startTime)
			-- check for best time
			if WereWatch.savedVariables.bestTime ~= nil then
				if WereWatch.deltaTime > WereWatch.savedVariables.bestTime then
					-- New best time!
					if (WereWatch.savedVariables.optionsMessage) then
						d("[WereWatch] You held your werewolf form for ".. WereWatch.ToMinSec(WereWatch.deltaTime) .. ". This beats your previous best time of " .. WereWatch.ToMinSec(WereWatch.savedVariables.bestTime) .. "!")
					end
					WereWatch.savedVariables.bestTime = WereWatch.deltaTime
				elseif WereWatch.deltaTime <= WereWatch.savedVariables.bestTime then
					-- No new best time.
					if (WereWatch.savedVariables.optionsMessage) then
						d("[WereWatch] You held your werewolf form for " .. WereWatch.ToMinSec(WereWatch.deltaTime) .. ". Your best time is " .. WereWatch.ToMinSec(WereWatch.savedVariables.bestTime) .. ".")
					end
				end -- if WereWatch.deltaTime
			else
				if (WereWatch.savedVariables.optionsMessage) then
					d("[WereWatch] You held your werewolf form for ".. WereWatch.ToMinSec(WereWatch.deltaTime) .. ". No previous best time found.")
				end
				WereWatch.savedVariables.bestTime = WereWatch.deltaTime
			end -- if WereWatch.savedVariables.bestTime
		end -- if werewolf
	end -- if werewolf ~= WereWatch.werewolf
end -- function

function WereWatch.OnLinkedWorldPositionChanged(eventCode)
	if WereWatch.werewolf then
		WereWatch.OnWerewolfStateChanged(eventCode, IsWerewolf())
	end -- if
end -- function

function WereWatch.OnPlayerDead(eventCode)
	if WereWatch.werewolf then
		WereWatch.OnWerewolfStateChanged(eventCode, IsWerewolf())
	end -- if
end -- function

function WereWatch.evalOptions()
	if WereWatch.savedVariables.optionsTimer == nil then
		WereWatch.savedVariables.optionsTimer = true
	end
	if WereWatch.savedVariables.optionsMessage == nil then
		WereWatch.savedVariables.optionsMessage = true
	end
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
	if arg == "start" then
		WereWatch.OnWerewolfStateChanged("debug", true)
	elseif arg == "stop" then
		WereWatch.OnWerewolfStateChanged("debug", false)
	elseif arg == "pos" then
		d("[WereWatch] Timer position: " .. WereWatchUI:GetLeft() .. ", " .. WereWatchUI:GetTop())
	elseif arg == "best" then
		d("[WereWatch] Your current best time is " .. WereWatch.ToMinSec(WereWatch.savedVariables.bestTime) .. ".")
	elseif tonumber(arg) >= 0 then
		WereWatch.savedVariables.bestTime = tonumber(arg)
	end -- if
end -- function

EVENT_MANAGER:RegisterForEvent(WereWatch.name, EVENT_ADD_ON_LOADED, WereWatch.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(WereWatch.name, EVENT_WEREWOLF_STATE_CHANGED, WereWatch.OnWerewolfStateChanged)
EVENT_MANAGER:RegisterForEvent(WereWatch.name, EVENT_LINKED_WORLD_POSITION_CHANGED, WereWatch.OnLinkedWorldPositionChanged)
EVENT_MANAGER:RegisterForEvent(WereWatch.name, EVENT_PLAYER_DEAD, WereWatch.OnPlayerDead)