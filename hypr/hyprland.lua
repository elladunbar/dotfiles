-- monitors
hl.monitor({ output = "DP-1", mode = "3440x1440@120", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "3440x0", scale = 1 })
hl.monitor({ output = "HEADLESS-2", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- get pywal variables (colors and wallpaper)
W = require("~/.cache/wal/colors.lua")

-- automatic starting
hl.on("hyprland.start", function()
	hl.exec_cmd("hyprpm reload")
	hl.exec_cmd("uwsm app -- awww-daemon")
	hl.exec_cmd("uwsm app -- pywalfox start")
	hl.exec_cmd("uwsm app -- xsettingsd")

	hl.exec_cmd("uwsm app -- firefox", { workspace = 1 })
	hl.exec_cmd("uwsm app -- element-desktop --password-store=gnome-libsecret", { workspace = 1 })
	hl.exec_cmd("uwsm app -- com.discordapp.Discord", { workspace = 1 })
	hl.exec_cmd("uwsm app -- openrgb", { workspace = 1 })
	hl.exec_cmd("uwsm app -- ghostty", { workspace = 2 })
	hl.exec_cmd("uwsm app -- ghostty", { workspace = 2 })
	hl.exec_cmd("uwsm app -- com.spotify.Client", { workspace = 10 })
end)

-- real settings
hl.config({
	general = {
		gaps_in = 8,
		gaps_out = 16,
		border_size = 4,
		col = { active_border = W.color10, inactive_border = W.color8 },

		layout = "scrolling",
	},

	decoration = {
		rounding = 12,

		blur = {
			enabled = true,
			size = 4,
			passes = 3,
			ignore_opacity = true,
			new_optimizations = true,
			noise = 0.06,
			contrast = 1.0,
			brightness = 1.0,
			vibrancy = 0.0,
		},

		shadow = { range = 120, render_power = 4, color = "0x88040404", offset = { 0, 10 } },
	},

	animations = { enabled = true },

	input = {
		kb_layout = "us",
		kb_options = "caps:swapescape",
		numlock_by_default = true,

		follow_mouse = 1,

		touchpad = { natural_scroll = true },

		sensitivity = 0,
	},

	group = {
		insert_after_current = true,
		col = { border_active = W.color10, border_inactive = W.color8 },

		groupbar = {
			enabled = true,
			font_family = "SF Pro Display",
			font_size = 18,
			gradients = true,
			height = 24,
			indicator_height = 0,
			render_titles = false,
			gradient_rounding = 12,
			gradient_round_only_edges = false,
			gaps_in = 4,
			gaps_out = 4,
			text_color = W.color0,
			col = { active = W.color10, inactive = W.color8 },
		},
	},

	misc = { disable_hyprland_logo = true, disable_splash_rendering = true, vrr = 2, disable_autoreload = true },

	binds = { focus_preferred_method = 1 },

	xwayland = { force_zero_scaling = true },

	render = { direct_scanout = false },

	cursor = { sync_gsettings_theme = true },

	ecosystem = { no_update_news = true, no_donation_nag = true },

	dwindle = { preserve_split = true },

	plugin = {
		hyprbars = {
			bar_color = W.background,
			bar_height = 32,
			col = { text = W.foreground },
			bar_title_enabled = true,
			bar_text_size = 18,
			bar_text_font = "SF Pro Display",
			bar_text_align = "center",
			bar_buttons_alignment = "left",
			bar_part_of_window = true,
			bar_precedence_over_border = true,
		},
	},
})

-- extra plugin configuration
hl.plugin.hyprbars.add_button({
	bg_color = W.color6,
	fg_color = W.foreground,
	size = 20,
	icon = "󰅖",
	action = "hyprctl eval 'hl.dsp.window.close()'",
})
hl.plugin.hyprbars.add_button({
	bg_color = W.color14,
	fg_color = W.foreground,
	size = 20,
	icon = "󰖯",
	action = "hyprctl eval 'hl.dsp.window.fullscreen({action = \"set\"})'",
})

-- layer rules
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "vicinae" }, blur = true, ignore_alpha = 0 })

-- window rules
hl.window_rule({ match = { class = "^(.*\\.exe)$" }, float = true })
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, float = true })
hl.window_rule({ match = { class = "^(steam_proton)$" }, float = true })
hl.window_rule({ match = { class = "(steam)", title = "negative:^(Steam)$" }, float = true })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Calculator)$" }, float = true })
hl.window_rule({ match = { class = "(imv)" }, float = true })
hl.window_rule({ match = { class = "(org.matplotlib.Matplotlib3)" }, float = true })
hl.window_rule({ match = { class = "(Matplotlib)" }, float = true })
hl.window_rule({ match = { class = "(firefox)", title = "(Picture-in-Picture)" }, float = true })

hl.window_rule({ match = { class = "^(com.mitchellh.ghostty)$" }, opacity = "1.0 override 0.85 override" })

hl.window_rule({ match = { class = "^(discord)$" }, opacity = "0.8 override 0.7 override" })
hl.window_rule({ match = { class = "^(Element)$" }, opacity = "0.8 override 0.7 override" })
hl.window_rule({ match = { class = "^(rstudio)$" }, opacity = "0.8 override 0.7 override" })

hl.window_rule({ match = { float = false }, ["hyprbars:no_bar"] = true })

-- set keybinds
hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- ghostty"))
hl.bind("SUPER + space", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- io.elementary.files"))
hl.bind("SUPER + T", hl.dsp.exec_cmd("daynight"))
hl.bind("SUPER + S", hl.dsp.exec_raw("grim - | wl-copy"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_raw('grim -g "$(slurp)" - | swappy -f - -o - | wl-copy'))
hl.bind("SUPER + V", hl.dsp.exec_raw('$HOME/Code/sh/mpv/play.sh "$(wl-paste)"'))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind("code:108", hl.dsp.exec_cmd("handy --toggle-transcription"))

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_raw(
		'wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2.5%+ && makoctl dismiss && notify-send "Volume: $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -c 11-)%"'
	)
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_raw(
		'wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2.5%- && makoctl dismiss && notify-send "Volume: $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -c 11-)%"'
	)
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("SUPER + XF86AudioRaiseVolume", hl.dsp.exec_cmd("streamraise"))
hl.bind("SUPER + XF86AudioLowerVolume", hl.dsp.exec_cmd("streamlower"))
hl.bind("SUPER + XF86AudioMute", hl.dsp.exec_cmd("streammute"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))

hl.bind("SUPER + R", hl.dsp.exec_raw("hyprctl reload && notify-send 'Reloaded Hyprland config!'"))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_raw("killall -SIGUSR2 waybar && notify-send 'Reloaded Waybar config!'"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exec_cmd("uwsm stop"))
hl.bind("SUPER + D", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + G", hl.dsp.group.toggle())
hl.bind("SUPER + Tab", hl.dsp.group.next())
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))

hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

hl.bind("SUPER + ALT + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind("SUPER + ALT + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind("SUPER + ALT + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind("SUPER + ALT + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))
hl.bind("SUPER + ALT + comma", hl.dsp.window.resize({ x = -1, y = 0, relative = true }))
hl.bind("SUPER + ALT + period", hl.dsp.window.resize({ x = 1, y = 0, relative = true }))
hl.bind("SUPER + ALT + V", hl.dsp.window.resize({ x = 2489, y = 1400 }))
hl.bind("SUPER + ALT + D", hl.dsp.window.resize({ x = 842, y = 1400 }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 10 do
	local key = i % 10
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + CTRL + H", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + L", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Y", hl.dsp.workspace.toggle_special())
hl.bind("SUPER + SHIFT + Y", hl.dsp.window.move({ workspace = "special" }))
