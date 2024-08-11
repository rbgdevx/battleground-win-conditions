local _, NS = ...

local pairs = pairs
local ipairs = ipairs
local tnumber = tonumber
local CreateFrame = CreateFrame
local select = select
local UnitName = UnitName
local UnitExists = UnitExists
local GetRealmName = GetRealmName

local sfind = string.find
local smatch = string.match

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

local flagDebuffSpellIds = {
  [46392] = true, -- Focused Assault
  [46393] = true, -- Brutal Assault
}

do
  local allyFlagCarrier, hordeFlagCarrier, flagCarrier = nil, nil, nil
  local allyFlags, hordeFlags = 0, 0
  local curMap = {
    id = 0,
    stackTime = 0,
  }
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

        local winName, winText

        if aScore == hScore then
          if NS.db.global.lastFlagCapBy == NS.ALLIANCE_NAME then
            winName = NS.ALLIANCE_NAME
          elseif NS.db.global.lastFlagCapBy == NS.HORDE_NAME then
            winName = NS.HORDE_NAME
          end
        else
          winName = (aScore > hScore) and NS.ALLIANCE_NAME or NS.HORDE_NAME
        end

        if winName then
          winText = (winName == NS.PLAYER_FACTION) and "WIN" or "LOSE"
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

    local function handleAura(aura, spellIds, isRemoved)
      if aura and spellIds[aura.spellId] then
        if isRemoved then
          stacksCounting = false
          NS.STACKS_COUNTING = stacksCounting
          currentStacks = 0
          NS.CURRENT_STACKS = currentStacks
          Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
        else
          if NS.CURRENT_STACKS ~= aura.applications then
            stacksCounting = true
            NS.STACKS_COUNTING = stacksCounting
            currentStacks = aura.applications
            NS.CURRENT_STACKS = currentStacks
            Stacks:Start(curMap.stackTime, aura.applications)
          end
        end
      end
    end

    function FlagPrediction:UNIT_AURA(unitTarget, updateInfo)
      if updateInfo.isFullUpdate or flagCarrier == nil then
        return
      end

      if unitTarget == "arena1" or unitTarget == "arena2" then
        if updateInfo.addedAuras then
          for _, aura in ipairs(updateInfo.addedAuras) do
            handleAura(aura, flagDebuffSpellIds, false)
          end
        end
        -- stacks are only ever added not updated
        -- if updateInfo.updatedAuraInstanceIDs then
        -- 	for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
        -- 		local aura = GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID)
        -- 		handleAura(aura, flagDebuffSpellIds, false)
        -- 	end
        -- end
        -- we're tracking stacks being removed elsewhere
        -- if updateInfo.removedAuraInstanceIDs then
        -- 	for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
        -- 		local aura = GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID)
        -- 		handleAura(aura, flagDebuffSpellIds, true)
        -- 	end
        -- end
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

            local name, realm = UnitName("arena2")
            local nameAndRealm = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())

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
            local nameAndRealm = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())

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

    local function filterDebuffs(unitID, ...)
      local spellId = select(10, ...)
      if spellId and (spellId == 46392 or spellId == 46393) then -- Focused Assault, Brutal Assault
        stacksCounting = true
        NS.STACKS_COUNTING = stacksCounting
        if unitID == "arena1" then
          hordeHasFlag = true
        elseif unitID == "arena2" then
          allyHasFlag = true
        end
        flagCarrier = unitID
        NS.HAS_FLAG_CARRIER = true
        return true
      end
    end

    local function filterBuffs(unitID, ...)
      local spellId = select(10, ...)
      if spellId then
        if spellId == 23333 or spellId == 156618 then -- Horde Flag
          hordeHasFlag = true
          flagCarrier = unitID
          NS.HAS_FLAG_CARRIER = true
          return true
        elseif spellId == 23335 or spellId == 156621 then -- Alliance Flag
          allyHasFlag = true
          flagCarrier = unitID
          NS.HAS_FLAG_CARRIER = true
          return true
        end
      end
    end

    function FlagPrediction:GetStacksByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339, TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        if UnitExists("arena1") or UnitExists("arena2") then
          for i = 1, 2 do
            local unitID = "arena" .. i
            if unitID then
              -- Apply debuff filtering
              AuraUtil.ForEachAura(unitID, "HARMFUL", nil, function(...)
                return filterDebuffs(unitID, ...)
              end)

              -- Apply buff filtering
              AuraUtil.ForEachAura(unitID, "HELPFUL", nil, function(...)
                return filterBuffs(unitID, ...)
              end)
            end
          end

          if flagCarrier then
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

    local function resetFlagState()
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

    local function handleFlagCapture(teamName)
      resetFlagState()
      FlagPrediction:GetRemainingTime(6, teamName)
    end

    local function handleFlagReturn(carrier, enemyFlagCarrier)
      if carrier == "ally" then
        allyFlagCarrier = nil
        allyHasFlag = false
      elseif carrier == "horde" then
        hordeFlagCarrier = nil
        hordeHasFlag = false
      end
      if enemyFlagCarrier == nil and stacksCounting then
        resetFlagState()
      end
    end

    local function handleFlagPickup(carrier, enemyFlagCarrier, unitID)
      if carrier == "ally" then
        allyFlagCarrier = unitID
        allyHasFlag = true
      elseif carrier == "horde" then
        hordeFlagCarrier = unitID
        hordeHasFlag = true
      end
      NS.HAS_FLAG_CARRIER = true
      if enemyFlagCarrier and stacksCounting == false then
        flagCarrier = "arena2"
        FlagsFrame:RegisterEvent("UNIT_AURA")
        stacksCounting = true
        NS.STACKS_COUNTING = stacksCounting
        Stacks:Start(curMap.stackTime, 0)
      end
    end

    local function handleWin()
      resetFlagState()
      Banner:Stop(Banner, Banner.timerAnimationGroup)
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_ALLIANCE(message, _, _, _, _)
      local pickedName = smatch(message, "picked up by (.+)%!") -- horde picked ally flag
      if pickedName then
        handleFlagPickup("horde", allyFlagCarrier, pickedName)
      end

      local droppedName = smatch(message, "dropped by (.+)%!") -- horde dropped ally flag
      if droppedName then
        hordeHasFlag = false
        if allyHasFlag == false then
          NS.HAS_FLAG_CARRIER = false
        end
      end

      if sfind(message, "returned to its base by") then -- ally flag returned by ally
        handleFlagReturn("horde", allyFlagCarrier)
      end

      if sfind(message, "captured the") then -- alliance captured horde flag
        handleFlagCapture(NS.ALLIANCE_NAME)
      end

      if sfind(message, "wins") then -- ally wins
        handleWin()
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_HORDE(message, _, _, _, _)
      local pickedName = smatch(message, "picked up by (.+)%!") -- ally picked horde flag
      if pickedName then
        handleFlagPickup("ally", hordeFlagCarrier, pickedName)
      end

      local droppedName = smatch(message, "dropped by (.+)%!") -- ally dropped horde flag
      if droppedName then
        allyHasFlag = false
        if hordeHasFlag == false then
          NS.HAS_FLAG_CARRIER = false
        end
      end

      if sfind(message, "returned to its base by") then -- horde flag returned by horde
        handleFlagReturn("ally", hordeFlagCarrier)
      end

      if sfind(message, "captured the") then -- horde captured alliance flag
        handleFlagCapture(NS.HORDE_NAME)
      end

      if sfind(message, "wins") then -- horde wins
        handleWin()
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_NEUTRAL(message)
      local flagsReturned = string.find(message, "placed at their bases") -- all flags returned
      if flagsReturned then
        resetFlagState()
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

    function FlagPrediction:StartInfoTracker(mapInfo)
      -- local
      winTime = 0
      aScore, hScore = 0, 0
      -- global
      allyFlagCarrier, hordeFlagCarrier, flagCarrier = nil, nil, nil
      NS.HAS_FLAG_CARRIER = false
      allyFlags, hordeFlags = 0, 0
      allyHasFlag, hordeHasFlag = false, false
      curMap = mapInfo
      stacksCounting = false
      NS.STACKS_COUNTING = stacksCounting
      currentStacks = 0
      NS.CURRENT_STACKS = currentStacks

      self:GetScoreByMapID(curMap.id)
      self:GetObjectivesByMapID(curMap.id)
      self:GetTimeByMapID(curMap.id)
      self:GetStacksByMapID(curMap.id)

      -- FlagsFrame:RegisterEvent("UNIT_AURA")
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
