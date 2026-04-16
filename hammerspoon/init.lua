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
	local cmd = "~/Code/sh/mpv/play.sh " .. hs.pasteboard.getContents()
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
