-- Static analysis for the battleground-win-conditions WoW addon.  Run: luacheck .
--
-- WoW globals harvested with luacheck (it has no WoW API library of its own).
-- NOTE: luacheck must run under Lua <= 5.4 (it crashes on 5.5); the `luacheck`
-- on PATH is built against lua@5.4. We still lint WoW's 5.1 dialect via std.

std = "lua51"
max_line_length = false

-- All of libs/ is external/vendored (Ace3, LibStub, LibSharedMedia, ...).
exclude_files = {
  "libs", ".libraries", ".claude", ".vscode",
}

-- WoW idioms that aren't defects (config-level, not by churning signatures):
--   unused_args=false — event/callback/option handlers carry fixed positional
--     params a given handler often doesn't use.
--   432/self — `widget:SetScript("OnX", function(self) ... end)` inside a method
--     shadows the outer self (idiomatic; non-self shadows still flagged).
--   _ADDON — the `local _ADDON, NS = ...` addon-load vararg.
unused_args = false
ignore = { "_ADDON", "432/self" }

-- Globals the addon DEFINES/WRITES (saved-vars, slash handlers).
globals = {
  "BattlegroundWinConditionsDB", "SLASH_BGWC1", "SLASH_BGWC2", "SLASH_BGWC3", "SlashCmdList",
}

-- Blizzard client API the addon READS.
read_globals = {
  "wipe",
  "AceGUIWidgetLSMlists", "C_ChatInfo", "C_PvP", "C_Timer", "C_UIWidgetManager", "CopyTable",
  "CreateFrame", "Enum", "FACTION_ALLIANCE", "FACTION_HORDE", "FrameUtil", "GetClassColor",
  "GetInstanceInfo", "GetNumGroupMembers", "GetPlayerFactionGroup", "GetRealmName", "GetTime",
  "HOURS_MINUTES_SECONDS", "IsInGroup", "IsInGuild", "IsInInstance", "IsInRaid",
  "LE_PARTY_CATEGORY_HOME", "LE_PARTY_CATEGORY_INSTANCE", "LibStub", "MINUTES_SECONDS",
  "SECONDS_PER_DAY", "SECONDS_PER_HOUR", "SECONDS_PER_MIN", "UIParent", "UnitClass",
  "UnitExists", "UnitName", "format", "issecretvalue", "strsplit", "time",
}
