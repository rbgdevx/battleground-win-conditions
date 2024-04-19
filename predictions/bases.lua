local _, NS = ...

local next = next
local pairs = pairs
local GetTime = GetTime

local sfind = string.find
local smatch = string.match
local mmin = math.min
local mceil = math.ceil
local mfloor = math.floor

local After = C_Timer.After
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo

local Banner = NS.Banner
local Score = NS.Score
local Bases = NS.Bases
local Flag = NS.Flag
local Interface = NS.Interface

local BasePrediction = {}
NS.BasePrediction = BasePrediction

local BaseFrame = CreateFrame("Frame", "BaseFrame")
BaseFrame:SetScript("OnEvent", function(_, event, ...)
  if BasePrediction[event] then
    BasePrediction[event](BasePrediction, ...)
  end
end)

do
  local allyBases, allyIncBases = 0, 0
  local hordeBases, hordeIncBases = 0, 0
  local allyFlags, hordeFlags = 0, 0
  local allyTimers, hordeTimers, winTable = {}, {}, {}
  local curMapID, curTickRate, curMapInfo = 0, 0, {}
  local maxBases = 0

  function BasePrediction:GetFlagValue(winName, maxScore, winScore, loseScore, winBases, loseBases)
    if NS.isEOTS(curMapID) and (allyBases > 0 or hordeBases > 0) then
      local flagsNeeded = loseBases > 0
          and NS.calculateFlagsToCatchUp(maxScore, winScore, loseScore, winBases, loseBases, curMapInfo, curTickRate)
        or 0

      if flagsNeeded == 0 then
        Flag.text:SetFormattedText("")
        Flag.text:SetAlpha(0)
      else
        Flag:SetText(Flag.text, NS.PLAYER_FACTION, winName, flagsNeeded)
      end
    end
  end

  function BasePrediction:FlagTracker(widgetID)
    -- widgetType == 14
    -- 1672 = EOTS
    if widgetID == 1672 then
      -- Eye of the Storm
      allyFlags = 0
      hordeFlags = 0

      local flagInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not flagInfo or not flagInfo.leftIcons or not flagInfo.rightIcons then
        return
      end

      for _, v in pairs(flagInfo.leftIcons) do
        if v.iconState == 1 then
          local str = v.state1Tooltip

          if sfind(str, "flag") then
            allyFlags = allyFlags + 1
          end
        end
      end

      for _, v in pairs(flagInfo.rightIcons) do
        if v.iconState == 1 then
          local str = v.state1Tooltip

          if sfind(str, "flag") then
            hordeFlags = hordeFlags + 1
          end
        end
      end
    end
  end

  do
    local prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
    local timeBetweenEachTick, prevTick, winTime = 0, 0, 0
    local minScore, maxScore, aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0, 0, 0
    local prevABases, prevHBases, prevAIncBases, prevHIncBases = 0, 0, 0, 0

    function BasePrediction:BasePredictor()
      if aScore < 1500 and hScore < 1500 then
        local allyTicksToWin = NS.getWinTicks(maxScore, aScore, curTickRate, curMapInfo.baseResources[allyBases])
        local allyTimeToWin = NS.getWinTime(allyTicksToWin, curTickRate)

        local hordeTicksToWin = NS.getWinTicks(maxScore, hScore, curTickRate, curMapInfo.baseResources[hordeBases])
        local hordeTimeToWin = NS.getWinTime(hordeTicksToWin, curTickRate)

        local currentWinTicks = mmin(allyTicksToWin, hordeTicksToWin)
        local currentWinTime = mmin(allyTimeToWin, hordeTimeToWin)

        if allyIncBases == 0 and hordeIncBases == 0 then
          local winTicks = currentWinTicks
          winTime = currentWinTime

          if allyTicksToWin == hordeTicksToWin then
            local winText = "TIE"

            Banner:Start(winTime, winText)
            Bases:Stop(Bases.text, Bases.timerAnimationGroup)
            Score.text:SetFormattedText("")
            Score.text:SetAlpha(0)
            Flag.text:SetFormattedText("")
            Flag.text:SetAlpha(0)

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local aWins = allyTicksToWin < hordeTicksToWin

            local allyIncrease = curTickRate * curMapInfo.baseResources[allyBases]
            local afs = aWins and maxScore or aScore + (currentWinTicks * allyIncrease)
            local finalAScore = (allyBases == 0 and allyIncBases == 0) and aScore or afs

            local hordeIncrease = curTickRate * curMapInfo.baseResources[hordeBases]
            local hfs = aWins and hScore + (currentWinTicks * hordeIncrease) or maxScore
            local finalHScore = (hordeBases == 0 and hordeIncBases == 0) and hScore or hfs

            local winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            local loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"

            Banner:Start(winTime, winText)
            Score:SetText(Score.text, finalAScore, finalHScore)

            -- local currentWinbases = aWins and allyBases or hordeBases

            local winBases = aWins and allyBases or hordeBases
            local loseBases = aWins and hordeBases or allyBases
            local winScore = aWins and aScore or hScore
            local loseScore = aWins and hScore or aScore

            winTable = {}
            for needBases = loseBases + 1, maxBases do
              local table = NS.checkWinCondition(
                needBases,
                winBases,
                loseBases,
                winScore,
                loseScore,
                winName,
                loseName,
                winTicks,
                0,
                maxBases,
                maxScore,
                winTime,
                curTickRate,
                curMapInfo.baseResources
              )

              for a, b in pairs(table) do
                winTable[a] = b
              end
            end

            if NS.db.global.maps.eyeofthestorm.showflaginfo then
              self:GetFlagValue(winName, maxScore, winScore, loseScore, winBases, loseBases)
            end
          end
        else
          local aBaseIncrease, aTimeIncrease, aScoreIncrease =
            NS.getIncomingBaseInfo(allyTimers, allyBases, allyIncBases, curMapInfo.baseResources, currentWinTime)
          local hBaseIncrease, hTimeIncrease, hScoreIncrease =
            NS.getIncomingBaseInfo(hordeTimers, hordeBases, hordeIncBases, curMapInfo.baseResources, currentWinTime)

          local newAllyScore = aScore + aScoreIncrease
          local newHordeScore = hScore + hScoreIncrease

          local newAllyBases = allyBases + aBaseIncrease
          local newHordeBases = hordeBases + hBaseIncrease

          local aFutureScore = newAllyScore
          local hFutureScore = newHordeScore

          local winTimeIncrease = 0

          if aTimeIncrease ~= 0 or hTimeIncrease ~= 0 then
            if aTimeIncrease > hTimeIncrease then
              local timeDifference = aTimeIncrease - hTimeIncrease
              local scoreDifference = hFutureScore + timeDifference * curMapInfo.baseResources[newHordeBases]
              if scoreDifference < maxScore then
                hFutureScore = scoreDifference

                if aTimeIncrease < currentWinTime then
                  winTimeIncrease = aTimeIncrease
                end
              end
            elseif hTimeIncrease > aTimeIncrease then
              local timeDifference = hTimeIncrease - aTimeIncrease
              local scoreDifference = aFutureScore + timeDifference * curMapInfo.baseResources[newAllyBases]
              if scoreDifference < maxScore then
                aFutureScore = scoreDifference

                if hTimeIncrease < currentWinTime then
                  winTimeIncrease = hTimeIncrease
                end
              end
            end
          end

          local allyFutureTicksToWin =
            NS.getWinTicks(maxScore, aFutureScore, curTickRate, curMapInfo.baseResources[newAllyBases])
          local allyFutureTimeToWin = NS.getWinTime(allyFutureTicksToWin, curTickRate)

          local hordeFutureTicksToWin =
            NS.getWinTicks(maxScore, hFutureScore, curTickRate, curMapInfo.baseResources[newHordeBases])
          local hordeFutureTimeToWin = NS.getWinTime(hordeFutureTicksToWin, curTickRate)

          local futureWinTicks = mmin(allyFutureTicksToWin, hordeFutureTicksToWin)
          local futureWinTime = mmin(allyFutureTimeToWin, hordeFutureTimeToWin)

          local winTicks = futureWinTicks
          winTime = futureWinTime + winTimeIncrease

          if allyFutureTicksToWin == hordeFutureTicksToWin then
            local winText = "TIE"

            Banner:Start(winTime, winText)
            Bases:Stop(Bases.text, Bases.timerAnimationGroup)
            Score.text:SetFormattedText("")
            Score.text:SetAlpha(0)
            Flag.text:SetFormattedText("")
            Flag.text:SetAlpha(0)

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local aWins = allyFutureTicksToWin < hordeFutureTicksToWin

            local allyFutureIncrease = curTickRate * curMapInfo.baseResources[newAllyBases]
            local afs = aWins and maxScore or aFutureScore + (winTicks * allyFutureIncrease)
            local finalAScore = (allyBases == 0 and allyIncBases == 0) and aScore or afs

            local hordeFutureIncrease = curTickRate * curMapInfo.baseResources[newHordeBases]
            local hfs = aWins and hFutureScore + (winTicks * hordeFutureIncrease) or maxScore
            local finalHScore = (hordeBases == 0 and hordeIncBases == 0) and hScore or hfs

            -- local currentWinBases = aWins and allyBases or hordeBases
            local currentLoseBases = aWins and hordeBases or allyBases

            local winBases = aWins and newAllyBases or newHordeBases
            local loseBases = aWins and newHordeBases or newAllyBases
            local winScore = aWins and aFutureScore or hFutureScore
            local loseScore = aWins and hFutureScore or aFutureScore

            local winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            local loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"

            Banner:Start(winTime, winText)
            Score:SetText(Score.text, finalAScore, finalHScore)

            winTable = {}
            for needBases = currentLoseBases + 1, maxBases do
              local table = NS.checkWinCondition(
                needBases,
                winBases,
                loseBases,
                winScore,
                loseScore,
                winName,
                loseName,
                winTicks,
                winTimeIncrease,
                maxBases,
                maxScore,
                winTime,
                curTickRate,
                curMapInfo.baseResources
              )

              for a, b in pairs(table) do
                winTable[a] = b
              end
            end

            if NS.db.global.maps.eyeofthestorm.showflaginfo then
              self:GetFlagValue(winName, maxScore, winScore, loseScore, winBases, loseBases)
            end
          end
        end

        local firstKey = next(winTable)
        if firstKey and winTable[firstKey] then
          Bases:Start(winTime, winTable)
        end
      end
    end

    function BasePrediction:GetObjectivesByMapID(mapID)
      -- mapID == Zone ID in-game
      -- DWG = 1576
      -- EOTS = 112, 397
      -- AB = 1366, 1383, 837
      -- TBFG = 275
      if mapID == 1366 or mapID == 1383 or mapID == 837 then
        -- Arathi Basin
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(1645)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            allyIncBases = allyIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if horde had the base, now they dont
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if fresh capture for alliance, or they once had it lose it fully then got it again
            if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
              allyTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            allyBases = allyBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            hordeIncBases = hordeIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if alliance had the base, now they dont
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if fresh capture for horde, or they once had it lose it fully then got it again
            if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
              hordeTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            hordeBases = hordeBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end
      elseif mapID == 1576 then
        -- Deepwind Gorge
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(2339)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            allyIncBases = allyIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if horde had the base, now they dont
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if fresh capture for alliance
            if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
              allyTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            allyBases = allyBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            hordeIncBases = hordeIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if alliance had the base, now they dont
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if fresh capture for horde
            if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
              hordeTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            hordeBases = hordeBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end
      elseif mapID == 275 then
        -- The Battle for Gilneas
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(1670)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            allyIncBases = allyIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if horde had the base, now they dont
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if fresh capture for alliance
            if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
              allyTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            allyBases = allyBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            hordeIncBases = hordeIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if alliance had the base, now they dont
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if fresh capture for horde
            if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
              hordeTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            hordeBases = hordeBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end
      elseif mapID == 112 or mapID == 397 then
        -- Eye of the Storm
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0
        allyFlags = 0
        hordeFlags = 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(1672)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip -- Alliance has assaulted the Mage Tower

            if sfind(str, "flag") == nil then
              allyIncBases = allyIncBases + 1

              local base = smatch(str, "assaulted the (.+)")
              -- if horde had the base, now they dont
              if hordeTimers[base] then
                hordeTimers[base] = nil
              end
              -- if fresh capture for alliance
              if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
                allyTimers[base] = NS.CONTESTED_TIME + GetTime()
              end
            else
              allyFlags = allyFlags + 1
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip -- Alliance has captured the Mage Tower

            allyBases = allyBases + 1

            local base = smatch(str, "captured the (.+)")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip -- Horde has assaulted the Mage Tower

            if sfind(str, "flag") == nil then
              hordeIncBases = hordeIncBases + 1

              local base = smatch(str, "assaulted the (.+)")
              -- if alliance had the base, now they dont
              if allyTimers[base] then
                allyTimers[base] = nil
              end
              -- if fresh capture for horde
              if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
                hordeTimers[base] = NS.CONTESTED_TIME + GetTime()
              end
            else
              hordeFlags = hordeFlags + 1
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip -- Horde has captured the Mage Tower

            hordeBases = hordeBases + 1

            local base = smatch(str, "captured the (.+)")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end
      end
    end

    function BasePrediction:GetScoreByMapID(mapID)
      -- mapID == Zone ID in-game
      -- DWG = 1576
      -- EOTS = 112, 397
      -- AB = 1366, 1383, 837
      -- TBFG = 275
      if mapID == 1366 or mapID == 1383 or mapID == 837 or mapID == 275 or mapID == 112 or mapID == 397 then
        -- Arathi Basin, The Battle for Gilneas, Eye of the Storm
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(1671)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        minScore = scoreInfo.leftBarMin -- Min Bar
        maxScore = scoreInfo.leftBarMax -- Max Bar
        aScore = scoreInfo.leftBarValue -- Alliance Bar
        hScore = scoreInfo.rightBarValue -- Horde Bar
      elseif mapID == 1576 then
        -- Deepwind Gorge
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(2074)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        minScore = scoreInfo.leftBarMin -- Min Bar
        maxScore = scoreInfo.leftBarMax -- Max Bar
        aScore = scoreInfo.leftBarValue -- Alliance Bar
        hScore = scoreInfo.rightBarValue -- Horde Bar
      end
    end

    function BasePrediction:ObjectiveTracker(widgetID)
      -- widgetType == 14
      -- 2339 = DWG
      -- 1672 = EOTS
      -- 1645 = AB
      -- 1670 = TBFG
      if widgetID == 1645 or widgetID == 1670 or widgetID == 2339 then
        -- Arathi Basin, The Battle for Gilneas, Deepwind Gorge
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            allyIncBases = allyIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if horde had the base, now they dont
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if fresh capture for alliance, or they once had it lose it fully then got it again
            if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
              allyTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            allyBases = allyBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            hordeIncBases = hordeIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if alliance had the base, now they dont
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if fresh capture for horde, or they once had it lose it fully then got it again
            if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
              hordeTimers[base] = NS.CONTESTED_TIME + GetTime()
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip

            hordeBases = hordeBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end
      elseif widgetID == 1672 then
        -- Eye of the Storm
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip -- Alliance has assaulted the Mage Tower

            if sfind(str, "flag") == nil then
              allyIncBases = allyIncBases + 1

              local base = smatch(str, "assaulted the (.+)")
              -- if horde had the base, now they dont
              if hordeTimers[base] then
                hordeTimers[base] = nil
              end
              -- if fresh capture for alliance, or they once had it lose it fully then got it again
              if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
                allyTimers[base] = NS.CONTESTED_TIME + GetTime()
              end
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip -- Alliance has captured the Mage Tower

            allyBases = allyBases + 1

            local base = smatch(str, "captured the (.+)")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip -- Horde has assaulted the Mage Tower

            if sfind(str, "flag") == nil then
              hordeIncBases = hordeIncBases + 1

              local base = smatch(str, "assaulted the (.+)")
              -- if alliance had the base, now they dont
              if allyTimers[base] then
                allyTimers[base] = nil
              end
              -- if fresh capture for horde, or they once had it lose it fully then got it again
              if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
                hordeTimers[base] = NS.CONTESTED_TIME + GetTime()
              end
            end
          elseif v.iconState == 2 then
            local str = v.state2Tooltip -- Horde has captured the Mage Tower

            hordeBases = hordeBases + 1

            local base = smatch(str, "captured the (.+)")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end
      end

      if widgetID == 1645 or widgetID == 1670 or widgetID == 2339 or widgetID == 1672 then
        -- Arathi Basin, The Battle for Gilneas, Deepwind Gorge, Eye of the Storm
        if
          allyBases ~= prevABases
          or hordeBases ~= prevHBases
          or allyIncBases ~= prevAIncBases
          or hordeIncBases ~= prevHIncBases
        then
          prevABases = allyBases
          prevHBases = hordeBases
          prevAIncBases = allyIncBases
          prevHIncBases = hordeIncBases

          self:BasePredictor()
        end
      end
    end

    function BasePrediction:ScoreTracker(widgetID)
      -- widgetType == 3
      -- 2074 = DWG
      -- 1671 = AB, TBFG, EOTS
      if widgetID == 1671 or widgetID == 2074 then
        -- Arathi Basin, The Battle for Gilneas, Eye of the Storm, Deepwind Gorge
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(widgetID)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        if prevTime == 0 then
          prevTime = GetTime()
          prevAScore = scoreInfo.leftBarValue
          prevHScore = scoreInfo.rightBarValue
          return
        end

        local t = GetTime()
        local elapsed = t - prevTime
        prevTime = t

        if elapsed > 0.5 then
          -- If there's only 1 update, it could be either alliance or horde, so we update both stats in this one
          minScore = scoreInfo.leftBarMin -- Min Bar
          maxScore = scoreInfo.leftBarMax -- Max Bar
          aScore = scoreInfo.leftBarValue -- Alliance Bar
          hScore = scoreInfo.rightBarValue -- Horde Bar
          aIncrease = aScore - prevAScore
          hIncrease = hScore - prevHScore
          -- Round to the closest time
          timeBetweenEachTick = elapsed % 1 >= 0.5 and mceil(elapsed) or mfloor(elapsed)
          prevAScore = aScore
          prevHScore = hScore

          After(0.5, function()
            if aIncrease ~= prevAIncrease or hIncrease ~= prevHIncrease or timeBetweenEachTick ~= prevTick then
              -- Scores can reduce in DWG
              if aIncrease > 60 or hIncrease > 60 or aIncrease < 0 or hIncrease < 0 then
                -- > 60 increase means captured a flag/cart in EOTS/DWG
                Interface:Clear()

                prevAIncrease = -1
                prevHIncrease = -1
                return
              end

              prevAIncrease = aIncrease
              prevHIncrease = hIncrease
              prevTick = timeBetweenEachTick

              BasePrediction:BasePredictor()
            end
          end)
        else
          -- If elapsed < 0.5 then the event fired twice because both alliance and horde have bases.
          -- 1st update = alliance, 2nd update = horde
          -- If only one faction has bases, the event only fires once.
          -- Unfortunately we need to wait for the 2nd event to fire (the horde update) to know the true horde stats.
          -- In this one where we have 2 updates, we overwrite the horde stats from the 1st update.
          hScore = scoreInfo.rightBarValue -- Horde Bar
          hIncrease = hScore - prevHScore
          prevHScore = hScore
        end
      end
    end

    function BasePrediction:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        BasePrediction:ScoreTracker(widgetID)
        BasePrediction:ObjectiveTracker(widgetID)
        BasePrediction:FlagTracker(widgetID)
      end
    end

    function BasePrediction:StartInfoTracker(mapID, tickRate, mapResources, maxResources)
      -- local
      prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
      timeBetweenEachTick, prevTick, winTime = 0, 0, 0
      minScore, maxScore, aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0, 0, 0
      prevABases, prevHBases, prevAIncBases, prevHIncBases = 0, 0, 0, 0
      -- global
      curMapID, curTickRate, curMapInfo = mapID, tickRate, mapResources
      allyBases, allyIncBases = 0, 0
      hordeBases, hordeIncBases = 0, 0
      allyFlags, hordeFlags = 0, 0
      allyTimers, hordeTimers, winTable = {}, {}, {}
      maxBases = maxResources

      self:GetScoreByMapID(curMapID)
      self:GetObjectivesByMapID(curMapID)

      BaseFrame:RegisterEvent("UPDATE_UI_WIDGET")
    end
  end
end

function BasePrediction:StopInfoTracker()
  BaseFrame:UnregisterEvent("UPDATE_UI_WIDGET")
end
