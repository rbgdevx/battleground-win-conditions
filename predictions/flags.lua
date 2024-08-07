local _, NS = ...

local pairs = pairs
local tnumber = tonumber
local smatch = strmatch
local CreateFrame = CreateFrame
local select = select
local UnitName = UnitName
local UnitExists = UnitExists
local GetRealmName = GetRealmName

local sfind = string.find

local After = C_Timer.After
local GetIconAndTextWidgetVisualizationInfo = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo
-- local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID

local Banner = NS.Banner
local Stacks = NS.Stacks

local FlagPrediction = {}
NS.FlagPrediction = FlagPrediction

local FlagsFrame = CreateFrame("Frame", "FlagsFrame")
FlagsFrame:SetScript("OnEvent", function(_, event, ...)
  if FlagPrediction[event] then
    FlagPrediction[event](FlagPrediction, ...)
  end
end)

do
  local allyFlagCarrier, hordeFlagCarrier, flagCarrier = nil, nil, nil
  local allyFlags, hordeFlags = 0, 0
  local curMapID = 0
  local allyHasFlag, hordeHasFlag = false, false
  local stacksCounting = false
  local currentStacks = 0

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

    function FlagPrediction:UNIT_AURA(unitTarget, updateInfo)
      if flagCarrier == nil then
        return
      end
      if updateInfo.isFullUpdate then
        return
      end
      -- updates to stacks are only ever adds, not updates
      if updateInfo.addedAuras then
        if unitTarget == "arena1" or unitTarget == "arena2" then
          for _, aura in pairs(updateInfo.addedAuras) do
            if aura and (aura.spellId == 46392 or aura.spellId == 46393) then -- Focused Assault, Brutal Assault
              -- we need to make sure that we're tracking stacks here
              -- but also in the manual stack counter so globally we know
              -- regardless of where stacks are accruing we need to ensure
              -- we aren't restarting stack counter if upon aura add we're
              -- still at the same stacks as before drop/pickup/aura removed
              if NS.CURRENT_STACKS ~= aura.applications then
                stacksCounting = true
                NS.STACKS_COUNTING = stacksCounting
                currentStacks = aura.applications
                NS.CURRENT_STACKS = currentStacks
                Stacks:Start(NS.STACK_TIME, aura.applications)
                break
              end
            end
          end
        end
      end
      -- if updateInfo.updatedAuraInstanceIDs then
      --   if unitTarget == "arena1" or unitTarget == "arena2" then
      --     for _, auraInstanceID in pairs(updateInfo.updatedAuraInstanceIDs) do
      --       local aura = GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID)
      --       if aura and (aura.spellId == 46392 or aura.spellId == 46393) then -- Focused Assault, Brutal Assault
      --         if NS.CURRENT_STACKS ~= aura.applications then
      --           stacksCounting = true
      --           NS.STACKS_COUNTING = stacksCounting
      --           currentStacks = aura.applications
      --           NS.CURRENT_STACKS = currentStacks
      --           Stacks:Start(NS.STACK_TIME, aura.applications)
      --           break
      --         end
      --       end
      --     end
      --   end
      -- end
      -- if updateInfo.removedAuraInstanceIDs then
      --   if unitTarget == "arena1" or unitTarget == "arena2" then
      --     for _, aura in pairs(updateInfo.removedAuraInstanceIDs) do
      --       if aura and (aura.spellId == 46392 or aura.spellId == 46393) then -- Focused Assault, Brutal Assault
      --         stacksCounting = false
      --         NS.STACKS_COUNTING = stacksCounting
      --         currentStacks = 0
      --         NS.CURRENT_STACKS = currentStacks
      --         Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
      --         break
      --       end
      --     end
      --   end
      -- end
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

            local name, realm = UnitName("arena2")
            local nameAndRealm = name
            if realm then
              nameAndRealm = name .. "-" .. realm
            else
              nameAndRealm = name .. "-" .. GetRealmName()
            end

            allyFlagCarrier = nameAndRealm
            allyHasFlag = true
            flagCarrier = "arena2"
            NS.HAS_FLAG_CARRIER = true
          end
        end

        for _, v in pairs(flagInfo.rightIcons) do
          if v.iconState == 1 then
            hordeFlags = hordeFlags + 1

            local name, realm = UnitName("arena1")
            local nameAndRealm = name
            if realm then
              nameAndRealm = name .. "-" .. realm
            else
              nameAndRealm = name .. "-" .. GetRealmName()
            end

            hordeFlagCarrier = nameAndRealm
            hordeHasFlag = true
            flagCarrier = "arena1"
            NS.HAS_FLAG_CARRIER = true
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

    function FlagPrediction:GetStacksByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        if UnitExists("arena1") or UnitExists("arena2") then
          for i = 1, 2 do
            local unitID = "arena" .. i
            if unitID then
              local function filterDebuffs(...)
                local spellId = select(10, ...)
                if spellId and (spellId == 46392 or spellId == 46393) then -- Focused Assault, Brutal Assault
                  stacksCounting = true
                  NS.STACKS_COUNTING = stacksCounting
                  if unitID == "arena1" then
                    hordeHasFlag = true
                  end
                  if unitID == "arena2" then
                    allyHasFlag = true
                  end
                  flagCarrier = unitID
                  NS.HAS_FLAG_CARRIER = true
                  return true
                end
              end
              AuraUtil.ForEachAura(unitID, "HARMFUL", nil, filterDebuffs)
              local function filterBuffs(...)
                local spellId = select(10, ...)
                if spellId and (spellId == 23333 or spellId == 156618) then -- Horde Flag
                  hordeHasFlag = true
                  flagCarrier = unitID
                  NS.HAS_FLAG_CARRIER = true
                  return true
                end
                if spellId and (spellId == 23335 or spellId == 156621) then -- Alliance Flag
                  allyHasFlag = true
                  flagCarrier = unitID
                  NS.HAS_FLAG_CARRIER = true
                  return true
                end
              end
              AuraUtil.ForEachAura(unitID, "HELPFUL", nil, filterBuffs)
            end
          end
          if flagCarrier ~= nil then
            FlagsFrame:RegisterEvent("UNIT_AURA")
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
      local pickedName = string.match(message, "picked up by (.+)%!") -- horde picked ally flag
      if pickedName then
        hordeFlagCarrier = pickedName
        hordeHasFlag = true
        NS.HAS_FLAG_CARRIER = true
        if allyFlagCarrier and stacksCounting == false then
          flagCarrier = "arena2"
          FlagsFrame:RegisterEvent("UNIT_AURA")
          stacksCounting = true
          NS.STACKS_COUNTING = stacksCounting
          Stacks:Start(NS.STACK_TIME, 0)
        end
      end
      local droppedName = string.match(message, "dropped by (.+)%!") -- horde dropped ally flag
      if droppedName then
        hordeHasFlag = false
        if allyHasFlag == false then
          NS.HAS_FLAG_CARRIER = false
        end
      end
      local flagReturned = sfind(message, "returned to its base by") -- ally flag returned by ally
      if flagReturned then
        hordeFlagCarrier = nil
        hordeHasFlag = false
        if allyFlagCarrier == nil and stacksCounting then
          FlagsFrame:UnregisterEvent("UNIT_AURA")
          allyHasFlag = false
          flagCarrier = nil
          NS.HAS_FLAG_CARRIER = false
          stacksCounting = false
          NS.STACKS_COUNTING = stacksCounting
          Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
        end
      end
      local flagCaptured = sfind(message, "captured the") -- alliance captured horde flag
      if flagCaptured then
        FlagsFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        flagCarrier = nil
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
        self:GetRemainingTime(6, NS.ALLIANCE_NAME)
      end
      local wins = sfind(message, "wins") -- ally wins
      if wins then
        FlagsFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        flagCarrier = nil
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
        Banner:Stop(Banner, Banner.timerAnimationGroup)
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_HORDE(message)
      local pickedName = string.match(message, "picked up by (.+)%!") -- ally picked horde flag
      if pickedName then
        allyFlagCarrier = pickedName
        allyHasFlag = true
        NS.HAS_FLAG_CARRIER = true
        if hordeFlagCarrier and stacksCounting == false then
          flagCarrier = "arena2"
          FlagsFrame:RegisterEvent("UNIT_AURA")
          stacksCounting = true
          NS.STACKS_COUNTING = stacksCounting
          Stacks:Start(NS.STACK_TIME, 0)
        end
      end
      local droppedName = string.match(message, "dropped by (.+)%!") -- ally dropped horde flag
      if droppedName then
        allyHasFlag = false
        if hordeHasFlag == false then
          NS.HAS_FLAG_CARRIER = false
        end
      end
      local flagReturned = sfind(message, "returned to its base by") -- horde flag returned by horde
      if flagReturned then
        allyFlagCarrier = nil
        allyHasFlag = false
        if hordeFlagCarrier == nil and stacksCounting then
          FlagsFrame:UnregisterEvent("UNIT_AURA")
          hordeHasFlag = false
          flagCarrier = nil
          NS.HAS_FLAG_CARRIER = false
          stacksCounting = false
          NS.STACKS_COUNTING = stacksCounting
          Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
        end
      end
      local flagCaptured = sfind(message, "captured the") -- horde captured alliance flag
      if flagCaptured then
        FlagsFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        flagCarrier = nil
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
        self:GetRemainingTime(6, NS.HORDE_NAME)
      end
      local wins = sfind(message, "wins") -- horde wins
      if wins then
        FlagsFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        flagCarrier = nil
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
        Banner:Stop(Banner, Banner.timerAnimationGroup)
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_NEUTRAL(message)
      local flagsReturned = string.find(message, "placed at their bases") -- all flags returned
      if flagsReturned then
        FlagsFrame:UnregisterEvent("UNIT_AURA")
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        flagCarrier = nil
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
      end
    end

    --[[
    -- while this tracks updates to who has the flag
    -- it doesnt provide a safe way to detect dropped stacks
    --
    -- since we can know if both teams have no flag
    -- but not know if the flags were returned post drop
    -- i.e. someone can re-pick either flag before it gets returned, retaining stacks
    --
    -- seen, unseen, cleared, destroyed
    -- as alliance arena1 is horde, arena2 is ally
    --
    -- this updates more often sometimes then when someone actually picks the flag,
    -- so we can't use this reliably
    --]]
    -- function FlagPrediction:ARENA_OPPONENT_UPDATE(unitToken, updateReason)
    --   -- make sure we dont spam updates when the game is over
    --   if aScore < 3 and hScore < 3 then
    --     -- we only care about the flag carriers
    --     if unitToken == "arena1" or unitToken == "arena2" then
    --       -- old code here
    --     end
    --   end
    -- end

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
      allyFlagCarrier, hordeFlagCarrier, flagCarrier = nil, nil, nil
      NS.HAS_FLAG_CARRIER = false
      allyFlags, hordeFlags = 0, 0
      allyHasFlag, hordeHasFlag = false, false
      curMapID = mapID
      stacksCounting = false
      NS.STACKS_COUNTING = stacksCounting
      currentStacks = 0
      NS.CURRENT_STACKS = currentStacks

      self:GetScoreByMapID(curMapID)
      self:GetObjectivesByMapID(curMapID)
      self:GetTimeByMapID(curMapID)
      self:GetStacksByMapID(curMapID)

      FlagsFrame:RegisterEvent("UPDATE_UI_WIDGET")
      -- FlagsFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
      FlagsFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
      FlagsFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
      FlagsFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    end
  end
end

function FlagPrediction:StopInfoTracker()
  NS.db.global.lastFlagCapBy = ""
  FlagsFrame:UnregisterEvent("UNIT_AURA")
  FlagsFrame:UnregisterEvent("UPDATE_UI_WIDGET")
  -- FlagsFrame:UnregisterEvent("ARENA_OPPONENT_UPDATE")
  FlagsFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
  FlagsFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
  FlagsFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
end
