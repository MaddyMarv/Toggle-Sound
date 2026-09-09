local mod = get_mod("toggle_sound")

return {
	name = "Toggle Sound",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "group_sound",
				type = "group",
				tab = mod:localize("tab_sound"),
				sub_widgets = {
					{
						setting_id = "subgroup_master",
						type = "group",
						sub_widgets = {
							{
								setting_id = "mute_master_sound",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "keybind_mute_master_sound",
								type = "keybind",
								default_value = {},
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "cb_toggle_master_sound",
							},
							{
								setting_id = "include_voice_chat_in_master",
								type = "checkbox",
								default_value = true,
							},
						},
					},
					{
						setting_id = "subgroup_music",
						type = "group",
						sub_widgets = {
							{
								setting_id = "mute_music",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "keybind_mute_music",
								type = "keybind",
								default_value = {},
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "cb_toggle_music",
							},
						},
					},
					{
						setting_id = "subgroup_sfx",
						type = "group",
						sub_widgets = {
							{
								setting_id = "mute_sfx",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "keybind_mute_sfx",
								type = "keybind",
								default_value = {},
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "cb_toggle_sfx",
							},
						},
					},
					{
						setting_id = "subgroup_sound_notifications",
						type = "group",
						sub_widgets = {
							{
								setting_id = "sound_show_notifications",
								type = "checkbox",
								default_value = true,
							},
						},
					},
				},
			},
			{
				setting_id = "group_voice_chat",
				type = "group",
				tab = mod:localize("tab_voice_chat"),
				sub_widgets = {
					{
						setting_id = "subgroup_all_voice",
						type = "group",
						sub_widgets = {
							{
								setting_id = "mute_all_voice_chat",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "keybind_mute_all_voice_chat",
								type = "keybind",
								default_value = {},
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "cb_toggle_all_voice_chat",
							},
						},
					},
					{
						setting_id = "subgroup_non_friends",
						type = "group",
						sub_widgets = {
							{
								setting_id = "mute_non_friends_voice_chat",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "keybind_mute_non_friends_voice_chat",
								type = "keybind",
								default_value = {},
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "cb_toggle_non_friends_voice_chat",
							},
						},
					},
					{
						setting_id = "subgroup_console_voice",
						type = "group",
						sub_widgets = {
							{
								setting_id = "mute_console_voice_chat",
								type = "checkbox",
								default_value = false,
							},
							{
								setting_id = "keybind_mute_console_voice_chat",
								type = "keybind",
								default_value = {},
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "cb_toggle_console_voice_chat",
							},
							{
								setting_id = "console_voice_chat_ignore_friends",
								type = "checkbox",
								default_value = true,
							},
						},
					},
					{
						setting_id = "subgroup_voice_notifications",
						type = "group",
						sub_widgets = {
							{
								setting_id = "voice_chat_show_notifications",
								type = "checkbox",
								default_value = true,
							},
						},
					},
				},
			},
			{
				setting_id = "group_hot_mic",
				type = "group",
				tab = mod:localize("tab_hot_mic"),
				sub_widgets = {
					{
						setting_id = "subgroup_hot_mic_detection",
						type = "group",
						sub_widgets = {
							{
								setting_id = "enable_hot_mic_detector",
								type = "checkbox",
								default_value = true,
							},
							{
								setting_id = "hot_mic_threshold_seconds",
								type = "numeric",
								default_value = 8,
								range = { 3, 30 },
								decimals_number = 0,
								step_size_value = 1,
							},
							{
								setting_id = "hot_mic_ignore_friends",
								type = "checkbox",
								default_value = true,
							},
						},
					},
					{
						setting_id = "subgroup_hot_mic_actions",
						type = "group",
						sub_widgets = {
							{
								setting_id = "hot_mic_notify",
								type = "checkbox",
								default_value = true,
							},
							{
								setting_id = "keybind_reset_hot_mics",
								type = "keybind",
								default_value = {},
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "cb_reset_hot_mics",
							},
						},
					},
				},
			},
		},
	},
}
