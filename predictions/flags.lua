local _, NS = ...

local pairs = pairs
local tnumber = tonumber
local smatch = strmatch
local GetNumArenaOpponents = GetNumArenaOpponents
local CreateFrame = CreateFrame
local select = select
local UnitIsFriend = UnitIsFriend

local sfind = string.find

local After = C_Timer.After
local GetIconAndTextWidgetVisualizationInfo = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo

local Banner = NS.Banner
local Stacks = NS.Stacks

local FlagPrediction = {}
NS.FlagPrediction = FlagPrediction

local FlagFrame = CreateFrame("Frame", "FlagFrame")
FlagFrame:SetScript("OnEvent", function(_, event, ...)
  if FlagPrediction[event] then
    FlagPrediction[event](FlagPrediction, ...)
  end
end)

do
  local allyFlagCarrier, hordeFlagCarrier, flagCarrier = nil, nil, nil
  local allyFlags, hordeFlags = 0, 0
  local curMapID = 0
  local stacksCounting = false

  function FlagPrediction:FlagTracker(widgetID)
    -- widgetType == 14
    -- 1640 = WSG, TP
    if widgetID == 1640 then
      -- Warsong Gulch, Twin Peaks
      allyFlags = 0
      hordeFlags = 0

      local flagInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not flagInfo or not flagInfo.leftIcons or not flagInfo.rightIcons then
        return
      end

      for _, v in pairs(flagInfo.leftIcons) do
        if v.iconState == 1 then
          allyFlags = allyFlags + 1
        end
      end

      for _, v in pairs(flagInfo.rightIcons) do
        if v.iconState == 1 then
          hordeFlags = hordeFlags + 1
        end
      end
    end
  end

  do
    local winTime = 0
    local aScore, hScore = 0, 0

    function FlagPrediction:FlagPredictor(team)
      if aScore == 0 and hScore == 0 then
        Banner:Start(winTime, "TIE")
      elseif aScore < 3 and hScore < 3 then
        if team then
          NS.db.global.lastFlagCapBy = team
        end

        if aScore == hScore then
          local aWins = NS.db.global.lastFlagCapBy == NS.ALLIANCE_NAME
          local hWins = NS.db.global.lastFlagCapBy == NS.HORDE_NAME

          if aWins then
            local winName = NS.ALLIANCE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"

            Banner:Start(winTime, winText)
          elseif hWins then
            local winName = NS.HORDE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"

            Banner:Start(winTime, winText)
          end
        else
          local aWins = aScore > hScore
          local winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
          local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"

          Banner:Start(winTime, winText)
        end
      end
    end

    function FlagPrediction:GetRemainingTime(widgetID, team)
      local timeInfo = GetIconAndTextWidgetVisualizationInfo(widgetID)

      if timeInfo and timeInfo.text and timeInfo.state == 1 then
        local minutes, seconds = smatch(timeInfo.text, "(%d+):(%d+)")

        minutes = tnumber(minutes)
        seconds = tnumber(seconds)

        if minutes and seconds then
          local remaining = seconds + NS.minutesToSeconds(minutes)

          if remaining > 0 then
            winTime = remaining + 1
            self:FlagPredictor(team)
          end
        end
      end
    end

    function FlagPrediction:GetObjectivesByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        allyFlags = 0
        hordeFlags = 0

        local flagInfo = GetDoubleStateIconRowVisualizationInfo(1640)

        if not flagInfo or not flagInfo.leftIcons or not flagInfo.rightIcons then
          return
        end

        for _, v in pairs(flagInfo.leftIcons) do
          if v.iconState == 1 then
            allyFlags = allyFlags + 1
          end
        end

        for _, v in pairs(flagInfo.rightIcons) do
          if v.iconState == 1 then
            hordeFlags = hordeFlags + 1
          end
        end
      end
    end

    function FlagPrediction:GetTimeByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        After(0, function()
          self:GetRemainingTime(6)
        end)
      end
    end

    function FlagPrediction:GetScoreByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(2)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        aScore = scoreInfo.leftBarValue -- Alliance Bar
        hScore = scoreInfo.rightBarValue -- Horde Bar

        if aScore > 0 and hScore > 0 then
          if aScore > hScore then
            NS.db.global.lastFlagCapBy = NS.ALLIANCE_NAME
          elseif hScore > aScore then
            NS.db.global.lastFlagCapBy = NS.HORDE_NAME
          end
        end
      end
    end

    function FlagPrediction:UNIT_AURA(unitTarget, updateInfo)
      if updateInfo.isFullUpdate then
        return
      end
      if flagCarrier and flagCarrier == unitTarget then
        if updateInfo.addedAuras then
          for _, aura in pairs(updateInfo.addedAuras) do
            if aura and (aura.spellId == 46392 or aura.spellId == 46393) then -- Focused Assault, Brutal Assault
              FlagFrame:UnregisterEvent("UNIT_AURA")
              stacksCounting = true
              Stacks:Start(NS.STACK_TIME, aura.applications)
              break
            end
          end
        end
        if updateInfo.updatedAuraInstanceIDs then
          for _, auraInstanceID in pairs(updateInfo.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID)
            if aura and (aura.spellId == 46392 or aura.spellId == 46393) then -- Focused Assault, Brutal Assault
              FlagFrame:UnregisterEvent("UNIT_AURA")
              stacksCounting = true
              Stacks:Start(NS.STACK_TIME, aura.applications)
              break
            end
          end
        end
      end
    end

    function FlagPrediction:GetStacksByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        local hasFlag = false
        -- Warsong Gulch, Twin Peaks
        if GetNumArenaOpponents() >= 1 then
          for i = 1, GetNumArenaOpponents() do
            local unitID = "arena" .. i
            if unitID then
              local function filterDebuffs(...)
                local spellId = select(10, ...)
                if spellId and (spellId == 46392 or spellId == 46393) then -- Focused Assault, Brutal Assault
                  if UnitIsFriend(unitID, "player") then
                    allyFlagCarrier = unitID
                  else
                    hordeFlagCarrier = unitID
                  end
                  hasFlag = true
                  flagCarrier = unitID
                  return true
                end
              end
              AuraUtil.ForEachAura(unitID, "HARMFUL", nil, filterDebuffs)
              local function filterBuffs(...)
                local spellId = select(10, ...)
                if spellId and (spellId == 23333 or spellId == 156618) then -- Horde Flag
                  hasFlag = true
                  flagCarrier = unitID
                  hordeFlagCarrier = unitID
                  return true
                end
                if spellId and (spellId == 23335 or spellId == 156621) then -- Alliance Flag
                  hasFlag = true
                  allyFlagCarrier = unitID
                  flagCarrier = unitID
                  return true
                end
              end
              AuraUtil.ForEachAura(unitID, "HELPFUL", nil, filterBuffs)
            end
          end
          if hasFlag then
            FlagFrame:RegisterEvent("UNIT_AURA")
          end
        end
      end
    end

    function FlagPrediction:ScoreTracker(widgetID)
      -- widgetType == 3
      -- 2 = WG, TP
      if widgetID == 2 then
        -- Warsong Gulch, Twin Peaks
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(widgetID)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        aScore = scoreInfo.leftBarValue -- Alliance Bar
        hScore = scoreInfo.rightBarValue -- Horde Bar
      end
    end

    function FlagPrediction:TimeTracker(widgetID)
      -- widgetType == 0
      -- 6 = WG, TP
      if widgetID == 6 then
        local timeInfo = GetIconAndTextWidgetVisualizationInfo(widgetID)

        if not timeInfo or not timeInfo.text or timeInfo.state ~= 1 then
          return
        end

        self:GetRemainingTime(widgetID)
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_ALLIANCE(message)
      local pickedName = string.match(message, "picked up by (.+)") -- horde picked ally flag
      if pickedName then
        hordeFlagCarrier = pickedName
        if allyFlagCarrier and stacksCounting == false then
          stacksCounting = true
          Stacks:Start(NS.STACK_TIME, 0)
        end
      end
      local flagReturned = string.find(message, "returned to its base by") -- ally flag returned by ally
      if flagReturned then
        hordeFlagCarrier = nil
        if allyFlagCarrier == nil then
          stacksCounting = false
          Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
        end
      end
      local flagCaptured = sfind(message, "captured the") -- alliance captured horde flag
      if flagCaptured then
        FlagFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        stacksCounting = false
        Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup, NS.ALLIANCE_NAME)
        self:GetRemainingTime(6, NS.ALLIANCE_NAME)
      end
      local wins = string.find(message, "wins") -- ally wins
      if wins then
        FlagFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        stacksCounting = false
        Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_HORDE(message)
      local pickedName = string.match(message, "picked up by (.+)") -- ally picked horde flag
      if pickedName then
        allyFlagCarrier = pickedName
        if hordeFlagCarrier and stacksCounting == false then
          stacksCounting = true
          Stacks:Start(NS.STACK_TIME, 0)
        end
      end
      local flagReturned = string.find(message, "returned to its base by") -- horde flag returned by horde
      if flagReturned then
        allyFlagCarrier = nil
        if hordeFlagCarrier == nil then
          stacksCounting = false
          Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
        end
      end
      local flagCaptured = sfind(message, "captured the") -- horde captured alliance flag
      if flagCaptured then
        FlagFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        stacksCounting = false
        Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
        self:GetRemainingTime(6, NS.HORDE_NAME)
      end
      local wins = string.find(message, "wins") -- horde wins
      if wins then
        FlagFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        stacksCounting = false
        Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_NEUTRAL(message)
      local flagsReturned = string.find(message, "placed at their bases") -- all flags returned
      if flagsReturned then
        FlagFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        stacksCounting = false
        Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
      end
    end

    --[[
    -- while this tracks updates to who has the flag
    -- it doesnt provide a safe way to detect dropped stacks
    --
    -- since we can know if both teams have no flag
    -- but not know if the flags were returned post drop
    -- i.e. someone can re-pick either flag before it gets returned, retaining stacks
    --]]
    function FlagPrediction:ARENA_OPPONENT_UPDATE(unitToken, updateReason)
      -- Only run when flags are dropped
      if updateReason == "cleared" then
        -- ignore pet frames
        if sfind(unitToken, "pet") == nil then
          -- ensure there are no flag carriers on both sides
          if GetNumArenaOpponents() == 0 then
            -- make sure we dont spam updates when the game is over
            if aScore < 3 and hScore < 3 then
              -- this doesn't mean flags have been returned
              -- which means the stacks might not have been reset yet
              -- so we can't rely on resetting here

              -- allyFlagCarrier = nil
              -- hordeFlagCarrier = nil
              -- stacksCounting = false
              -- Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
            end
          end
        end
      end
    end

    function FlagPrediction:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        FlagPrediction:ScoreTracker(widgetID)
        FlagPrediction:FlagTracker(widgetID)
        FlagPrediction:TimeTracker(widgetID)
      end
    end

    function FlagPrediction:StartInfoTracker(mapID)
      -- local
      winTime = 0
      aScore, hScore = 0, 0
      -- global
      curMapID = mapID
      allyFlags, hordeFlags = 0, 0
      stacksCounting = false

      self:GetScoreByMapID(curMapID)
      self:GetObjectivesByMapID(curMapID)
      self:GetTimeByMapID(curMapID)
      self:GetStacksByMapID(curMapID)

      FlagFrame:RegisterEvent("UPDATE_UI_WIDGET")
      FlagFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
      FlagFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
      FlagFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
      FlagFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    end
  end
end

function FlagPrediction:StopInfoTracker()
  NS.db.global.lastFlagCapBy = ""
  FlagFrame:UnregisterEvent("UNIT_AURA")
  FlagFrame:UnregisterEvent("UPDATE_UI_WIDGET")
  FlagFrame:UnregisterEvent("ARENA_OPPONENT_UPDATE")
  FlagFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
  FlagFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
  FlagFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
end
