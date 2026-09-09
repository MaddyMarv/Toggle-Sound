local mod = get_mod("toggle_sound")

local _speaking_durations = {}
local _hot_mic_flagged = {}
local _hot_muted_accounts = {}

local function _get_user_sound_setting(setting_name, default_val)
	local sound_settings = Application.user_setting and Application.user_setting("sound_settings")
	if sound_settings and sound_settings[setting_name] ~= nil then
		return sound_settings[setting_name]
	end
	return default_val
end

local function _notify_sound(message_key)
	if mod:get("sound_show_notifications") then
		mod:echo_localized(message_key)
	end
end

local function _notify_voice(message_key)
	if mod:get("voice_chat_show_notifications") then
		mod:echo_localized(message_key)
	end
end

local function _update_voice_chat_participants()
	local chat_manager = Managers.chat
	if chat_manager and chat_manager.player_mute_status_changed then
		chat_manager:player_mute_status_changed()
	end
end

local function _get_participant_name(participant)
	if not participant then
		return "Player"
	end
	local account_id = participant.account_id
	local social = Managers.data_service and Managers.data_service.social
	local player_info = account_id and social and social:get_player_info_by_account_id(account_id)
	if player_info then
		local char_name = player_info:character_name()
		local user_name = player_info:user_display_name()
		if char_name and char_name ~= "" and char_name ~= "N/A" then
			return char_name
		elseif user_name and user_name ~= "" then
			return user_name
		end
	end
	if participant.displayname and participant.displayname ~= "" and participant.displayname ~= "N/A" then
		return participant.displayname
	end
	return "Player"
end

local function _is_all_voice_chat_muted()
	return mod:get("mute_all_voice_chat") or (mod:get("mute_master_sound") and mod:get("include_voice_chat_in_master"))
end

local function _apply_voice_chat_volume()
	local is_muted = _is_all_voice_chat_muted()
	local target_vol = is_muted and 0 or _get_user_sound_setting("options_voip_volume_slider_v2", 50)
	Wwise.set_parameter("options_voip_volume_slider_v2", target_vol)

	local chat_manager = Managers.chat
	local Vivox = rawget(_G, "Vivox")
	if chat_manager and Vivox and Vivox.session_set_local_render_volume then
		local channels = chat_manager.connected_voip_channels and chat_manager:connected_voip_channels()
		if channels then
			local render_vol = is_muted and 0 or (target_vol <= 0.01 and 0 or math.lerp(25, 75, target_vol / 100))
			for session_handle, _ in pairs(channels) do
				Vivox.session_set_local_render_volume(session_handle, render_vol)
			end
		end
	end

	_update_voice_chat_participants()
end

local function _apply_master_sound()
	local is_muted = mod:get("mute_master_sound")
	if is_muted then
		Wwise.set_parameter("option_master_slider", 0)
		Wwise.set_state("options_mute_all", "true")
	else
		local original_vol = _get_user_sound_setting("option_master_slider", 100)
		Wwise.set_parameter("option_master_slider", original_vol)
		Wwise.set_state("options_mute_all", "false")
	end
	_apply_voice_chat_volume()
end

local function _apply_music()
	local is_muted = mod:get("mute_music")
	local vol = is_muted and 0 or _get_user_sound_setting("options_music_slider", 100)
	Wwise.set_parameter("options_music_slider", vol)
end

local function _apply_sfx()
	local is_muted = mod:get("mute_sfx")
	local vol = is_muted and 0 or _get_user_sound_setting("options_sfx_slider", 100)
	Wwise.set_parameter("options_sfx_slider", vol)
end

local function _restore_all_sound()
	local master_vol = _get_user_sound_setting("option_master_slider", 100)
	local music_vol = _get_user_sound_setting("options_music_slider", 100)
	local sfx_vol = _get_user_sound_setting("options_sfx_slider", 100)
	local voip_vol = _get_user_sound_setting("options_voip_volume_slider_v2", 50)

	Wwise.set_parameter("option_master_slider", master_vol)
	Wwise.set_parameter("options_music_slider", music_vol)
	Wwise.set_parameter("options_sfx_slider", sfx_vol)
	Wwise.set_parameter("options_voip_volume_slider_v2", voip_vol)
	Wwise.set_state("options_mute_all", "false")

	local chat_manager = Managers.chat
	if chat_manager and chat_manager.mic_volume_changed then
		chat_manager:mic_volume_changed()
	end

	_hot_muted_accounts = {}
	_hot_mic_flagged = {}
	_speaking_durations = {}

	_update_voice_chat_participants()
end

local function _is_console_player(player_info)
	if not player_info or not player_info.platform then
		return false
	end
	local platform = player_info:platform()
	return platform == "xbox" or platform == "psn" or platform == "ps5"
end

mod:hook("PlayerInfo", "is_voice_muted", function(func, self)
	if mod:is_enabled() then
		if _is_all_voice_chat_muted() then
			return true
		end
		if mod:get("mute_non_friends_voice_chat") and not self:is_friend() then
			return true
		end
		if mod:get("mute_console_voice_chat") and _is_console_player(self) then
			if not (mod:get("console_voice_chat_ignore_friends") and self:is_friend()) then
				return true
			end
		end
		local account_id = self:account_id()
		if account_id and _hot_muted_accounts[account_id] then
			if not (mod:get("hot_mic_ignore_friends") and self:is_friend()) then
				return true
			end
		end
	end
	return func(self)
end)

mod:hook("BackgroundMute", "update", function(func, self, dt, t)
	if mod:is_enabled() and mod:get("mute_master_sound") then
		self._had_focus = Window.has_focus()
		return
	end
	return func(self, dt, t)
end)

mod:hook_safe("ChatManager", "mic_volume_changed", function(self)
	if not mod:is_enabled() then
		return
	end
	if _is_all_voice_chat_muted() then
		local Vivox = rawget(_G, "Vivox")
		if Vivox and Vivox.session_set_local_render_volume and self._sessions then
			for session_handle, _ in pairs(self._sessions) do
				Vivox.session_set_local_render_volume(session_handle, 0)
			end
		end
	end
end)

mod.update = function(dt)
	if not mod:is_enabled() or not mod:get("enable_hot_mic_detector") then
		return
	end

	local chat_manager = Managers.chat
	local sessions = chat_manager and chat_manager._sessions
	if not sessions then
		return
	end

	local threshold = mod:get("hot_mic_threshold_seconds") or 8
	local notify = mod:get("hot_mic_notify")
	local ignore_friends = mod:get("hot_mic_ignore_friends")

	for _, channel in pairs(sessions) do
		if channel.participants then
			for _, participant in pairs(channel.participants) do
				local account_id = participant.account_id
				if account_id and not participant.is_current_user then
					local is_friend = false
					if ignore_friends then
						local social = Managers.data_service and Managers.data_service.social
						local player_info = social and social:get_player_info_by_account_id(account_id)
						is_friend = player_info and player_info:is_friend() or false
					end

					if not is_friend and participant.is_speaking then
						local current_dur = (_speaking_durations[account_id] or 0) + dt
						_speaking_durations[account_id] = current_dur

						if current_dur >= threshold and not _hot_mic_flagged[account_id] then
							_hot_mic_flagged[account_id] = true
							_hot_muted_accounts[account_id] = true
							_update_voice_chat_participants()
							if notify then
								local player_name = _get_participant_name(participant)
								mod:echo_localized("msg_hot_mic_muted", player_name)
							end
						end
					else
						_speaking_durations[account_id] = 0
						if not _hot_muted_accounts[account_id] then
							_hot_mic_flagged[account_id] = nil
						end
					end
				end
			end
		end
	end
end

mod.cb_toggle_all_voice_chat = function()
	if not mod:is_enabled() then
		return
	end
	local new_val = not mod:get("mute_all_voice_chat")
	mod:set("mute_all_voice_chat", new_val, true)
	_apply_voice_chat_volume()
	_notify_voice(new_val and "msg_voice_all_muted" or "msg_voice_all_unmuted")
end

mod.cb_toggle_non_friends_voice_chat = function()
	if not mod:is_enabled() then
		return
	end
	local new_val = not mod:get("mute_non_friends_voice_chat")
	mod:set("mute_non_friends_voice_chat", new_val, true)
	_apply_voice_chat_volume()
	_notify_voice(new_val and "msg_voice_non_friends_muted" or "msg_voice_non_friends_unmuted")
end

mod.cb_toggle_console_voice_chat = function()
	if not mod:is_enabled() then
		return
	end
	local new_val = not mod:get("mute_console_voice_chat")
	mod:set("mute_console_voice_chat", new_val, true)
	_apply_voice_chat_volume()
	_notify_voice(new_val and "msg_voice_console_muted" or "msg_voice_console_unmuted")
end

mod.cb_reset_hot_mics = function()
	if not mod:is_enabled() then
		return
	end
	local had_mutes = next(_hot_muted_accounts) ~= nil
	_hot_muted_accounts = {}
	_hot_mic_flagged = {}
	_speaking_durations = {}
	_update_voice_chat_participants()
	if had_mutes and mod:get("hot_mic_notify") then
		mod:echo_localized("msg_hot_mics_reset")
	end
end

mod.cb_toggle_master_sound = function()
	if not mod:is_enabled() then
		return
	end
	local new_val = not mod:get("mute_master_sound")
	mod:set("mute_master_sound", new_val, true)
	_apply_master_sound()
	_notify_sound(new_val and "msg_master_muted" or "msg_master_unmuted")
end

mod.cb_toggle_music = function()
	if not mod:is_enabled() then
		return
	end
	local new_val = not mod:get("mute_music")
	mod:set("mute_music", new_val, true)
	_apply_music()
	_notify_sound(new_val and "msg_music_muted" or "msg_music_unmuted")
end

mod.cb_toggle_sfx = function()
	if not mod:is_enabled() then
		return
	end
	local new_val = not mod:get("mute_sfx")
	mod:set("mute_sfx", new_val, true)
	_apply_sfx()
	_notify_sound(new_val and "msg_sfx_muted" or "msg_sfx_unmuted")
end

mod.on_setting_changed = function(setting_id)
	if setting_id == "mute_master_sound" or setting_id == "include_voice_chat_in_master" then
		_apply_master_sound()
	elseif setting_id == "mute_all_voice_chat" or setting_id == "mute_non_friends_voice_chat" or setting_id == "mute_console_voice_chat" or setting_id == "console_voice_chat_ignore_friends" then
		_apply_voice_chat_volume()
	elseif setting_id == "mute_music" then
		_apply_music()
	elseif setting_id == "mute_sfx" then
		_apply_sfx()
	elseif setting_id == "enable_hot_mic_detector" and not mod:get("enable_hot_mic_detector") then
		_hot_muted_accounts = {}
		_hot_mic_flagged = {}
		_speaking_durations = {}
		_update_voice_chat_participants()
	end
end

mod.on_all_mods_loaded = function()
	if mod:get("mute_master_sound") then
		_apply_master_sound()
	end
	if mod:get("mute_all_voice_chat") or mod:get("mute_non_friends_voice_chat") or mod:get("mute_console_voice_chat") then
		_apply_voice_chat_volume()
	end
	if mod:get("mute_music") then
		_apply_music()
	end
	if mod:get("mute_sfx") then
		_apply_sfx()
	end
end

mod.on_disabled = function()
	_restore_all_sound()
end

mod.on_unload = function()
	_restore_all_sound()
end

local function _handle_mute_command(subcommand)
	subcommand = subcommand and string.lower(subcommand)

	if not subcommand or subcommand == "" or subcommand == "all" or subcommand == "master" then
		mod.cb_toggle_master_sound()
	elseif subcommand == "music" then
		mod.cb_toggle_music()
	elseif subcommand == "sfx" then
		mod.cb_toggle_sfx()
	elseif subcommand == "vc" or subcommand == "voice" then
		mod.cb_toggle_all_voice_chat()
	elseif subcommand == "nonfriend" or subcommand == "nonfriends" or subcommand == "non-friends" or subcommand == "non_friends" or subcommand == "friends" then
		mod.cb_toggle_non_friends_voice_chat()
	elseif subcommand == "console" or subcommand == "consoles" or subcommand == "xbox" or subcommand == "psn" or subcommand == "ps5" then
		mod.cb_toggle_console_voice_chat()
	elseif subcommand == "reset" then
		mod.cb_reset_hot_mics()
	elseif subcommand == "help" then
		mod:echo_localized("cmd_mute_help_header")
		mod:echo_localized("cmd_mute_help_all")
		mod:echo_localized("cmd_mute_help_music")
		mod:echo_localized("cmd_mute_help_sfx")
		mod:echo_localized("cmd_mute_help_vc")
		mod:echo_localized("cmd_mute_help_nonfriends")
		mod:echo_localized("cmd_mute_help_console")
		mod:echo_localized("cmd_mute_help_reset")
		mod:echo_localized("cmd_mute_help_help")
	else
		mod:echo_localized("cmd_mute_unknown", subcommand)
	end
end

mod:command("mute", mod:localize("cmd_mute_desc"), _handle_mute_command)
mod:command("unmute", mod:localize("cmd_mute_desc"), _handle_mute_command)
