return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`toggle_sound` mod must be lower than DMF in load order.")

		new_mod("toggle_sound", {
			mod_script       = "toggle_sound/scripts/mods/toggle_sound/toggle_sound",
			mod_data         = "toggle_sound/scripts/mods/toggle_sound/toggle_sound_data",
			mod_localization = "toggle_sound/scripts/mods/toggle_sound/toggle_sound_localization",
		})
	end,
	packages = {},
}
