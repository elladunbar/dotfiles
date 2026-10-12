-- command line interface
require("hs.ipc")

-- scrolling window manager
PaperWM = hs.loadSpoon("PaperWM")
PaperWM:bindHotkeys({
	focus_left = { { "alt" }, "h" },
	focus_right = { { "alt" }, "l" },
	focus_up = { { "alt" }, "k" },
	focus_down = { { "alt" }, "j" },

	swap_left = { { "alt", "shift" }, "h" },
	swap_right = { { "alt", "shift" }, "l" },
	swap_up = { { "alt", "shift" }, "k" },
	swap_down = { { "alt", "shift" }, "j" },

	move_window_1 = { { "alt", "shift" }, "1" },
	move_window_2 = { { "alt", "shift" }, "2" },
	move_window_3 = { { "alt", "shift" }, "3" },
	move_window_4 = { { "alt", "shift" }, "4" },
	move_window_5 = { { "alt", "shift" }, "5" },
	move_window_6 = { { "alt", "shift" }, "6" },
	move_window_7 = { { "alt", "shift" }, "7" },
	move_window_8 = { { "alt", "shift" }, "8" },
	move_window_9 = { { "alt", "shift" }, "9" },

	increase_width = { { "alt", "ctrl" }, "l" },
	decrease_width = { { "alt", "ctrl" }, "h" },

	toggle_floating = { { "alt" }, "d" },
})
PaperWM.window_gap = { top = 0, bottom = 20, left = 20, right = 20 }
PaperWM.swipe_fingers = 3
PaperWM.swipe_gain = 2.0
PaperWM:start()

-- Orion registers with macOS under pid -1, so hs.window.filter (and therefore
-- PaperWM) never sees its windows. Watch Orion's real processes through the
-- accessibility API and forward their window events to PaperWM instead.
Orion = { observers = {}, windows = {} }

function Orion.handle(window, event)
	PaperWM.events.windowEventHandler(window, event, PaperWM)
end

function Orion.track(pid, element)
	local window = element and element:asHSWindow()
	-- skip helper windows like the 1x1 "Orion Preview", which PaperWM won't tile
	if not window or not window:isStandard() or not window:isMaximizable() or Orion.windows[window:id()] then
		return
	end
	Orion.windows[window:id()] = { pid = pid, window = window, element = element }
	Orion.handle(window, "windowVisible")
end

function Orion.untrack(id)
	local tracked = Orion.windows[id]
	if tracked then
		Orion.windows[id] = nil
		Orion.handle(tracked.window, "windowNotVisible")
	end
end

function Orion.focus(element)
	local window = element and element:asHSWindow()
	if window and Orion.windows[window:id()] then
		Orion.handle(window, "windowFocused")
	end
end

function Orion.watch(pid)
	if Orion.observers[pid] then
		return
	end
	local app = hs.axuielement.applicationElementForPID(pid)
	if not app then
		return
	end
	local observer = hs.axuielement.observer.new(pid)
	observer:callback(function(_, element, notification)
		if notification == "AXWindowCreated" or notification == "AXWindowDeminiaturized" then
			Orion.track(pid, element)
		elseif notification == "AXFocusedWindowChanged" then
			Orion.focus(element)
		elseif notification == "AXUIElementDestroyed" or notification == "AXWindowMiniaturized" then
			-- destroyed elements can't be queried, so drop every window that went away
			for id, tracked in pairs(Orion.windows) do
				if tracked.pid == pid and (not tracked.element:isValid() or tracked.window:isMinimized()) then
					Orion.untrack(id)
				end
			end
		end
	end)
	observer:addWatcher(app, "AXWindowCreated")
	observer:addWatcher(app, "AXFocusedWindowChanged")
	observer:addWatcher(app, "AXUIElementDestroyed")
	observer:addWatcher(app, "AXWindowMiniaturized")
	observer:addWatcher(app, "AXWindowDeminiaturized")
	observer:start()
	Orion.observers[pid] = observer

	for _, element in ipairs(app:attributeValue("AXWindows") or {}) do
		Orion.track(pid, element)
	end
end

function Orion.scan()
	local running = {}
	local output = hs.execute("/usr/bin/pgrep -x Orion") or ""
	for pid in output:gmatch("%d+") do
		pid = tonumber(pid)
		running[pid] = true
		Orion.watch(pid)
	end
	for pid, observer in pairs(Orion.observers) do
		if not running[pid] then
			observer:stop()
			Orion.observers[pid] = nil
			for id, tracked in pairs(Orion.windows) do
				if tracked.pid == pid then
					Orion.untrack(id)
				end
			end
		end
	end
end

-- hs.window:focus() and hs.window.focusedWindow() also go through the pid -1
-- application, so route them through Orion's real process instead
local window_mt = hs.getObjectMetatable("hs.window")
local focus = window_mt.focus
function window_mt.focus(window)
	local tracked = Orion.windows[window:id()]
	if not tracked then
		return focus(window)
	end
	window:becomeMain()
	hs.axuielement.applicationElementForPID(tracked.pid):setAttributeValue("AXFrontmost", true)
	return window
end

local focusedWindow = hs.window.focusedWindow
function hs.window.focusedWindow()
	for pid in pairs(Orion.observers) do
		local app = hs.axuielement.applicationElementForPID(pid)
		if app and app:attributeValue("AXFrontmost") then
			local element = app:attributeValue("AXFocusedWindow")
			local window = element and element:asHSWindow()
			if window then
				return window
			end
		end
	end
	return focusedWindow()
end

Orion.app_watcher = hs.application.watcher.new(function(name, event)
	if name ~= "Orion" then
		return
	end
	if event == hs.application.watcher.launched or event == hs.application.watcher.terminated then
		-- give the new process time to create its first window
		hs.timer.doAfter(1, Orion.scan)
	elseif event == hs.application.watcher.activated then
		Orion.scan()
		for pid in pairs(Orion.observers) do
			local app = hs.axuielement.applicationElementForPID(pid)
			Orion.focus(app and app:attributeValue("AXFocusedWindow"))
		end
	end
end)
Orion.app_watcher:start()
Orion.scan()

-- other window management hotkeys
for i = 1, 9 do
	hs.hotkey.bind({ "alt" }, tostring(i), function()
		local cmd = "/Applications/InstantSpaceSwitcher.app/Contents/MacOS/ISSCli index " .. tostring(i)
		os.execute(cmd)
	end)
end

-- app hotkeys
hs.hotkey.bind({ "alt" }, "e", function()
	hs.application.launchOrFocus("Finder")
end)

-- play video with clipboard content
hs.hotkey.bind({ "alt" }, "v", function()
	local cmd = 'PATH="/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin" '
		.. "/Users/ella/Code/sh/mpv/play.sh "
		.. hs.pasteboard.getContents()
		.. " &"
	os.execute(cmd)
end)

-- reload config
hs.hotkey.bind({ "alt" }, "r", function()
	if PaperWM then
		PaperWM:stop()
	end
	hs.reload()
end)
hs.alert.show("Reloaded Hammerspoon config!")
