local _, NS = ...

local Info = {}
NS.Info = Info

local InfoFrame = CreateFrame("Frame")
InfoFrame:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, ...)
end)

local pairs = pairs
local ipairs = ipairs
local GetTime = GetTime
local next = next
local type = type

local sformat = string.format
local mmin = math.min
local mceil = math.ceil
local mfloor = math.floor

local Timer = C_Timer.After
local GetAreaPOIInfo = C_AreaPoiInfo.GetAreaPOIInfo
-- local GetAreaPOISecondsLeft = C_AreaPoiInfo.GetAreaPOISecondsLeft
local GetAreaPOIForMap = C_AreaPoiInfo.GetAreaPOIForMap
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
-- local GetAllWidgetsBySetID = C_UIWidgetManager.GetAllWidgetsBySetID
-- local GetTopCenterWidgetSetID = C_UIWidgetManager.GetTopCenterWidgetSetID
-- local GetPOITextureCoords = C_Minimap.GetPOITextureCoords

do
  local allyBases, allyIncBases, allyFinalBases, hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0, 0, 0, 0
  local allyTimers, hordeTimers, winTable = {}, {}, {}
  local capTime, numObjectives

  -- Base Info
  do
    local objectivesStore = {}
    local curMapID = 0
    local prevABases, prevHBases = 0, 0

    -- local overrideTimers = {}
    -- you dont assault on random eots like you do on rated eots
    -- local ignoredAtlas = {
    --   [112] = true,
    --   -- [397] = true,
    -- }
    local state = {
      ["NEUTRAL"] = 0,
      ["ALLY_CONTESTED"] = 1,
      ["ALLY_CONTROLLED"] = 2,
      ["HORDE_CONTESTED"] = 3,
      ["HORDE_CONTROLLED"] = 4,
    }
    local icons = {
      -- Tower/Lighthouse
      [6] = state.NEUTRAL,
      [9] = state.ALLY_CONTESTED,
      [11] = state.ALLY_CONTROLLED,
      [12] = state.HORDE_CONTESTED,
      [10] = state.HORDE_CONTROLLED,
      -- Mine/Quarry
      [16] = state.NEUTRAL,
      [17] = state.ALLY_CONTESTED,
      [18] = state.ALLY_CONTROLLED,
      [19] = state.HORDE_CONTESTED,
      [20] = state.HORDE_CONTROLLED,
      -- Lumber
      [21] = state.NEUTRAL,
      [22] = state.ALLY_CONTESTED,
      [23] = state.ALLY_CONTROLLED,
      [24] = state.HORDE_CONTESTED,
      [25] = state.HORDE_CONTROLLED,
      -- Blacksmith/Waterworks
      [26] = state.NEUTRAL,
      [27] = state.ALLY_CONTESTED,
      [28] = state.ALLY_CONTROLLED,
      [29] = state.HORDE_CONTESTED,
      [30] = state.HORDE_CONTROLLED,
      -- Farm
      [31] = state.NEUTRAL,
      [32] = state.ALLY_CONTESTED,
      [33] = state.ALLY_CONTROLLED,
      [34] = state.HORDE_CONTESTED,
      [35] = state.HORDE_CONTROLLED,
      -- Stables
      [36] = state.NEUTRAL,
      [37] = state.ALLY_CONTESTED,
      [38] = state.ALLY_CONTROLLED,
      [39] = state.HORDE_CONTESTED,
      [40] = state.HORDE_CONTROLLED,
      -- Market
      [207] = state.NEUTRAL,
      [208] = state.ALLY_CONTESTED,
      [205] = state.ALLY_CONTROLLED,
      [209] = state.HORDE_CONTESTED,
      [206] = state.HORDE_CONTROLLED,
      -- Ruins
      [212] = state.NEUTRAL,
      [213] = state.ALLY_CONTESTED,
      [210] = state.ALLY_CONTROLLED,
      [214] = state.HORDE_CONTESTED,
      [211] = state.HORDE_CONTROLLED,
      -- Shrine
      [217] = state.NEUTRAL,
      [218] = state.ALLY_CONTESTED,
      [215] = state.ALLY_CONTROLLED,
      [219] = state.HORDE_CONTESTED,
      [216] = state.HORDE_CONTROLLED,
    }
    local atlasIcons = {
      -- ALLY BELF
      ["eots_capPts-leftIcon2-state1"] = state.ALLY_CONTESTED,
      ["eots_capPts-leftIcon2-state2"] = state.ALLY_CONTROLLED,
      -- ALLY FRR
      ["eots_capPts-leftIcon3-state1"] = state.ALLY_CONTESTED,
      ["eots_capPts-leftIcon3-state2"] = state.ALLY_CONTROLLED,
      -- ALLY DR
      ["eots_capPts-leftIcon4-state1"] = state.ALLY_CONTESTED,
      ["eots_capPts-leftIcon4-state2"] = state.ALLY_CONTROLLED,
      -- ALLY MT
      ["eots_capPts-leftIcon5-state1"] = state.ALLY_CONTESTED,
      ["eots_capPts-leftIcon5-state2"] = state.ALLY_CONTROLLED,
      -- HORDE MT
      ["eots_capPts-rightIcon2-state1"] = state.HORDE_CONTESTED,
      ["eots_capPts-rightIcon2-state2"] = state.HORDE_CONTROLLED,
      -- HORDE DR
      ["eots_capPts-rightIcon3-state1"] = state.HORDE_CONTESTED,
      ["eots_capPts-rightIcon3-state2"] = state.HORDE_CONTROLLED,
      -- HORDE FRR
      ["eots_capPts-rightIcon4-state1"] = state.HORDE_CONTESTED,
      ["eots_capPts-rightIcon4-state2"] = state.HORDE_CONTROLLED,
      -- HORDE BELF
      ["eots_capPts-rightIcon5-state1"] = state.HORDE_CONTESTED,
      ["eots_capPts-rightIcon5-state2"] = state.HORDE_CONTROLLED,
      -- -- GREEN
      -- ["orbs-leftIcon1-state1"] = state.ALLY_CONTROLLED,
      -- -- PURPLE
      -- ["orbs-leftIcon2-state1"] = state.ALLY_CONTROLLED,
      -- -- BLUE
      -- ["orbs-leftIcon3-state1"] = state.ALLY_CONTROLLED,
      -- -- ORANGE
      -- ["orbs-leftIcon4-state1"] = state.ALLY_CONTROLLED,
    }

    function InfoFrame:AREA_POIS_UPDATED()
      if curMapID == 417 then -- Temple
        -- BaseId:
        -- 1683 = TOK - only one used here
        -- 2339 = DWG
        -- 1672 = EOTS
        -- 1645 = AB
        -- 1670 = TBFG
        -- if BaseId == 1683 then
        -- end
        -- temple base states are always state 1 which is technically contested in all other maps
        local baseInfo = GetDoubleStateIconRowVisualizationInfo(1683)

        if not baseInfo or not baseInfo.leftIcons then
          return
        end

        allyBases = 0
        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == 1 then
            allyBases = allyBases + 1
          end
        end
        hordeBases = 0
        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            hordeBases = hordeBases + 1
          end
        end

        if allyBases ~= prevABases or hordeBases ~= prevHBases then
          prevABases = allyBases
          prevHBases = hordeBases

          if allyBases == numObjectives then
            NS.Interface:UpdateBuff(
              NS.Interface.frame.buff,
              NS.ORB_BUFF_TIME,
              NS.formatTeamName(NS.ALLIANCE_NAME, NS.PLAYER_FACTION)
            )
          end

          if hordeBases == numObjectives then
            NS.Interface:UpdateBuff(
              NS.Interface.frame.buff,
              NS.ORB_BUFF_TIME,
              NS.formatTeamName(NS.HORDE_NAME, NS.PLAYER_FACTION)
            )
          end

          if allyBases ~= numObjectives and hordeBases ~= numObjectives then
            NS.Interface:StopBuff(NS.Interface.frame.buff)
          end
        end
      else -- All other maps
        local isAtlas = false
        local pois = GetAreaPOIForMap(curMapID)

        for _, areaPOIID in ipairs(pois) do
          local areaPOIInfo = GetAreaPOIInfo(curMapID, areaPOIID)
          -- local areaPoiID = areaPOIInfo.areaPoiID
          local atlasName = areaPOIInfo.atlasName
          local infoName = areaPOIInfo.name
          local infoTexture = areaPOIInfo.textureIndex
          -- local infoDescription = areaPOIInfo.description -- Neutral, Contested, Alliance/Horde Controlled
          -- local widgetSetID = areaPOIInfo.widgetSetID

          -- local isAllyCapping, isHordeCapping

          if atlasName then
            isAtlas = true
            -- isAllyCapping = atlasIcons[atlasName] == state.ALLY_CONTESTED
            -- isHordeCapping = atlasIcons[atlasName] == state.HORDE_CONTESTED
          elseif infoTexture then
            -- isAllyCapping = icons[infoTexture] == state.ALLY_CONTESTED
            -- isHordeCapping = icons[infoTexture] == state.HORDE_CONTESTED
          end

          -- can't use this method for temple
          -- the issue with counting orbs is they all say "Power Orb" so the table just
          -- overrides itself each orb taken and ever icon is leftIcon, never rightIcon
          -- and the icons output when not taken actually vs when taken
          if objectivesStore[infoName] ~= (atlasName and atlasName or infoTexture) then
            objectivesStore[infoName] = (atlasName and atlasName or infoTexture)

            -- if not ignoredAtlas[curMapID] and (isAllyCapping or isHordeCapping) then
            --   -- local newCapTime = GetAreaPOISecondsLeft
            --   --     and GetAreaPOISecondsLeft(areaPoiID)
            --   --     and GetAreaPOISecondsLeft(areaPoiID) * capTime
            --   --   or overrideTimers[curMapID]
            --   --   or capTime

            --   -- if newCapTime ~= 0 then
            --   --   -- print("newCapTime", newCapTime)
            --   -- end

            --   -- if isAllyCapping then
            --   --   -- print("isAllyCapping")
            --   -- else
            --   --   -- print("isHordeCapping")
            --   -- end
            -- end
          end
        end

        allyBases, allyIncBases, allyFinalBases, hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0, 0, 0, 0

        if isAtlas then -- essentially only eots
          -- maps using atlasName:
          -- - eots
          -- - tok -- not used here
          for k, v in pairs(objectivesStore) do
            if type(v) ~= "string" then
              -- Do nothing
            elseif atlasIcons[v] == state.ALLY_CONTROLLED then
              allyBases = allyBases + 1

              if allyTimers[k] then
                allyTimers[k] = nil
              end
            elseif atlasIcons[v] == state.HORDE_CONTROLLED then
              hordeBases = hordeBases + 1

              if hordeTimers[k] then
                hordeTimers[k] = nil
              end
            elseif atlasIcons[v] == state.ALLY_CONTESTED then
              allyIncBases = allyIncBases + 1

              if hordeTimers[k] then
                hordeTimers[k] = nil
              end
              if not allyTimers[k] or allyTimers[k] <= 0 then
                allyTimers[k] = capTime + GetTime()
              end
            elseif atlasIcons[v] == state.HORDE_CONTESTED then
              hordeIncBases = hordeIncBases + 1

              if allyTimers[k] then
                allyTimers[k] = nil
              end
              if not hordeTimers[k] or hordeTimers[k] <= 0 then
                hordeTimers[k] = capTime + GetTime()
              end
            end
          end
        else -- all other maps
          -- maps:
          -- - tbfg
          -- - ab
          -- - dwg
          for k, v in pairs(objectivesStore) do
            if type(v) ~= "number" then
              -- Do nothing
            elseif icons[v] == state.ALLY_CONTROLLED then
              allyBases = allyBases + 1

              if allyTimers[k] then
                allyTimers[k] = nil
              end
            elseif icons[v] == state.HORDE_CONTROLLED then
              hordeBases = hordeBases + 1

              if hordeTimers[k] then
                hordeTimers[k] = nil
              end
            elseif icons[v] == state.ALLY_CONTESTED then
              allyIncBases = allyIncBases + 1

              if hordeTimers[k] then
                hordeTimers[k] = nil
              end
              if allyTimers[k] == nil or (allyTimers[k] and allyTimers[k] - GetTime() <= 0) then
                allyTimers[k] = capTime + GetTime()
              end
            elseif icons[v] == state.HORDE_CONTESTED then
              hordeIncBases = hordeIncBases + 1

              if allyTimers[k] then
                allyTimers[k] = nil
              end
              if hordeTimers[k] == nil or (hordeTimers[k] and hordeTimers[k] - GetTime() <= 0) then
                hordeTimers[k] = capTime + GetTime()
              end
            end
          end
        end

        allyFinalBases = allyBases + allyIncBases
        hordeFinalBases = hordeBases + hordeIncBases
      end
    end

    function Info:StartBaseTracker(mapID, objectsCount, bgCaptime)
      -- local
      objectivesStore = {}
      curMapID = mapID
      prevABases, prevHBases = 0, 0
      -- global
      capTime = bgCaptime
      numObjectives = objectsCount
      allyBases, allyIncBases, allyFinalBases, hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0, 0, 0, 0
      InfoFrame:RegisterEvent("AREA_POIS_UPDATED")
    end

    function Info:StopBaseTracker()
      InfoFrame:UnregisterEvent("AREA_POIS_UPDATED")
    end
  end

  -- Score Info
  do
    local prevText, prevFutText, prevFlagMessage = "", "", ""
    local prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
    local timeBetweenEachTick, prevTick, prevWinTime, prevFutWinTime = 0, 0, 0, 0
    local minScore, maxScore, aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0, 0, 0
    local aRemain, hRemain, aTicksToWin, hTicksToWin, winTime = 0, 0, 0, 0, 0
    local aIncBases, prevAIncBases, hIncBases, prevHIncBases = 0, 0, 0, 0
    local curBaseResources, curFlagResources = {}, {}
    local curTickRate, curMapID = 0, 0

    local function UpdatePredictor()
      if
        aIncrease ~= prevAIncrease
        or hIncrease ~= prevHIncrease
        or timeBetweenEachTick ~= prevTick
        or aIncBases ~= prevAIncBases
        or hIncBases ~= prevHIncBases
      then
        -- Scores can reduce in (OLD) DWG
        if aIncrease > 60 or hIncrease > 60 or aIncrease < 0 or hIncrease < 0 then
          -- > 60 increase means captured a flag/cart in EotS/(OLD) DWG
          NS.Interface:StopBanner(NS.Interface.frame.banner)
          NS.Interface:StopInfo(NS.Interface.frame.info)
          NS.Interface:ClearAllText()
          prevAIncrease, prevHIncrease = -1, -1
          return
        end

        prevAIncrease, prevHIncrease, prevTick, prevAIncBases, prevHIncBases =
          aIncrease, hIncrease, timeBetweenEachTick, aIncBases, hIncBases

        local currentWinTicks = mmin(aTicksToWin, hTicksToWin)
        local currentAWinTime = aTicksToWin == 10000 and aTicksToWin or aTicksToWin * timeBetweenEachTick
        local currentHWinTime = hTicksToWin == 10000 and hTicksToWin or hTicksToWin * timeBetweenEachTick
        local currentWinTime = currentWinTicks * timeBetweenEachTick

        if allyIncBases == 0 and hordeIncBases == 0 then
          local winTicks = mmin(aTicksToWin, hTicksToWin)
          winTime = winTicks * timeBetweenEachTick

          local aWins = aTicksToWin < hTicksToWin
          local finalAScore = aWins and maxScore or aScore + (hTicksToWin * aIncrease)
          local finalHScore = aWins and hScore + (aTicksToWin * hIncrease) or maxScore

          if aTicksToWin == hTicksToWin or finalAScore == finalHScore then
            local winText = "TIE"
            local winColor = { r = 0, g = 0, b = 0 }

            NS.Interface:UpdateBanner(NS.Interface.frame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevWinTime then
              prevWinTime = winTime
            end

            NS.Interface:StopInfo(NS.Interface.frame.info)
            NS.Interface:ClearAllText()

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            local loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"
            -- local winNoun = NS.getCorrectName(winName, NS.PLAYER_FACTION)
            local winColor = winText == "WIN" and { r = 36, g = 126, b = 36 } or { r = 175, g = 34, b = 47 }
            local txt = sformat("Final Score: %d - %d", finalAScore, finalHScore)

            NS.Interface:UpdateBanner(NS.Interface.frame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevWinTime then
              prevWinTime = winTime
            end

            NS.Interface:UpdateFinalScore(NS.Interface.frame.score, finalAScore, finalHScore)
            if txt ~= prevText then
              prevText = txt
            end

            local winBases = aWins and allyBases or hordeBases
            local loseBases = aWins and hordeBases or allyBases
            local winScore = aWins and aScore or hScore
            local loseScore = aWins and hScore or aScore

            winTable = {}
            for bases = loseBases + 1, numObjectives do
              local table = NS.checkWinCondition(
                bases,
                numObjectives,
                winBases,
                loseBases,
                winTime,
                winScore,
                loseScore,
                0,
                0,
                curBaseResources,
                maxScore,
                currentWinTime,
                winName,
                loseName
              )

              for a, b in pairs(table) do
                winTable[a] = b
              end
            end
          end
        else
          local aBaseIncrease, aTimeIncrease, aScoreIncrease =
            NS.getIncomingBaseInfo(allyTimers, allyBases, allyIncBases, curBaseResources, currentWinTime)
          local hBaseIncrease, hTimeIncrease, hScoreIncrease =
            NS.getIncomingBaseInfo(hordeTimers, hordeBases, hordeIncBases, curBaseResources, currentWinTime)

          local aFutureScore = aScore
          local newAScore = aFutureScore + aScoreIncrease
          if newAScore < maxScore then
            aFutureScore = newAScore
          end

          local hFutureScore = hScore
          local newHScore = hFutureScore + hScoreIncrease
          if newHScore < maxScore then
            hFutureScore = newHScore
          end

          local newAllyBases = allyBases + aBaseIncrease
          local newHordeBases = hordeBases + hBaseIncrease

          if aTimeIncrease ~= 0 or hTimeIncrease ~= 0 then
            if aTimeIncrease > hTimeIncrease then
              local timeDifference = aTimeIncrease - hTimeIncrease
              local scoreDifference = hFutureScore + timeDifference * curBaseResources[newHordeBases]
              if scoreDifference < maxScore then
                hFutureScore = scoreDifference
              end
            elseif hTimeIncrease > aTimeIncrease then
              local timeDifference = hTimeIncrease - aTimeIncrease
              local scoreDifference = aFutureScore + timeDifference * curBaseResources[newAllyBases]
              if scoreDifference < maxScore then
                aFutureScore = scoreDifference
              end
            end
          end

          if aTimeIncrease > currentWinTime then
            aFutureScore = aScore
          end

          if hTimeIncrease > currentWinTime then
            hFutureScore = hScore
          end

          local aFutureIncrease = curBaseResources[newAllyBases]
          local hFutureIncrease = curBaseResources[newHordeBases]

          if currentWinTime < NS.ASSAULT_TIME + NS.CONTESTED_TIME then
            aFutureIncrease = curBaseResources[allyBases]
            hFutureIncrease = curBaseResources[hordeBases]
          end

          local aFutureTicksToWin = NS.getWinTime(maxScore, aFutureScore, aFutureIncrease)
          local hFutureTicksToWin = NS.getWinTime(maxScore, hFutureScore, hFutureIncrease)

          local aWins = aFutureTicksToWin < hFutureTicksToWin
          local winTimeIncrease = aWins and aTimeIncrease or hTimeIncrease
          local winScoreIncrease = aWins and aScoreIncrease or hScoreIncrease

          local wT = mmin(aFutureTicksToWin, hFutureTicksToWin)
          local winTicks = wT + winTimeIncrease

          if allyIncBases == 0 and currentAWinTime < hFutureTicksToWin then
            winTicks = currentAWinTime
          end

          if hordeIncBases == 0 and currentHWinTime < aFutureTicksToWin then
            winTicks = currentHWinTime
          end

          winTime = winTicks

          local finalAScore = aWins and maxScore or aFutureScore + (wT * aFutureIncrease)
          local finalHScore = aWins and hFutureScore + (wT * hFutureIncrease) or maxScore

          if aFutureTicksToWin == hFutureTicksToWin or finalAScore == finalHScore then
            local winText = "TIE"
            local winColor = { r = 0, g = 0, b = 0 }

            NS.Interface:UpdateBanner(NS.Interface.frame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevWinTime then
              prevWinTime = winTime
            end

            NS.Interface:StopInfo(NS.Interface.frame.info)
            NS.Interface:ClearAllText()

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local newWinBases = aWins and newAllyBases or newHordeBases
            local newLoseBases = aWins and newHordeBases or newAllyBases

            if currentWinTime < NS.ASSAULT_TIME + NS.CONTESTED_TIME then
              newWinBases = aWins and allyBases or hordeBases
              newLoseBases = aWins and hordeBases or allyBases
            end

            local oldLoseBases = aWins and allyBases or hordeBases
            local winScore = aWins and aFutureScore or hFutureScore
            local loseScore = aWins and hFutureScore or aFutureScore
            local winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            local loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"
            -- local winNoun = NS.getCorrectName(winName, NS.PLAYER_FACTION)
            local winColor = winText == "WIN" and { r = 36, g = 126, b = 36 } or { r = 175, g = 34, b = 47 }
            local txt = sformat("Final Score: %d - %d", finalAScore, finalHScore)

            NS.Interface:UpdateBanner(NS.Interface.frame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevFutWinTime then
              prevFutWinTime = winTime
            end

            NS.Interface:UpdateFinalScore(NS.Interface.frame.score, finalAScore, finalHScore)
            if txt ~= prevFutText then
              prevFutText = txt
            end

            winTable = {}
            for bases = oldLoseBases + 1, numObjectives do
              local table = NS.checkWinCondition(
                bases,
                numObjectives,
                newWinBases,
                newLoseBases,
                winTime,
                winScore,
                loseScore,
                winTimeIncrease,
                winScoreIncrease,
                curBaseResources,
                maxScore,
                currentWinTime,
                winName,
                loseName
              )

              for a, b in pairs(table) do
                winTable[a] = b
              end
            end
          end
        end

        local firstKey, _ = next(winTable)
        if firstKey and winTable[firstKey] then
          NS.Interface:UpdateInfo(NS.Interface.frame.info, winTime - 0.5, winTable)
        end

        if NS.isEOTS(curMapID) and (aScore > 0 or hScore > 0) then
          if NS.PLAYER_FACTION == NS.ALLIANCE_NAME and aScore > 0 then
            local flagValue = curFlagResources[allyBases]
            local flagMessage = NS.formatScore(NS.ALLIANCE_NAME, flagValue)

            NS.Interface:UpdateFlagValue(NS.Interface.frame.flag, flagMessage)
          elseif NS.PLAYER_FACTION == NS.HORDE_NAME and hScore > 0 then
            local flagValue = curFlagResources[hordeBases]
            local flagMessage = NS.formatScore(NS.HORDE_NAME, flagValue)

            NS.Interface:UpdateFlagValue(NS.Interface.frame.flag, flagMessage)
          end
        end
      end
    end

    function InfoFrame:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetType = widgetInfo.widgetType

        -- DataId:
        -- 1689 = TOK
        -- 2074 = DWG
        -- 1671 = Everything Else
        if widgetID == 1689 or widgetID == 2074 or widgetID == 1671 then
          local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(widgetID)

          if not scoreInfo or not scoreInfo.leftBarMax then
            return
          end

          if prevTime == 0 then
            prevTime = GetTime()
            prevAScore, prevHScore = scoreInfo.leftBarValue, scoreInfo.rightBarValue
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
            aIncBases = allyIncBases
            hIncBases = hordeIncBases
            -- Always round ticks upwards. 1.2 ticks will always be 2 ticks to end.
            -- If ticks are 0 (no bases) then set to a random huge number (10,000)
            aTicksToWin = NS.getWinTime(maxScore, aScore, aIncrease)
            hTicksToWin = NS.getWinTime(maxScore, hScore, hIncrease)
            -- Round to the closest time
            timeBetweenEachTick = elapsed % 1 >= 0.5 and mceil(elapsed) or mfloor(elapsed)
            prevAScore, prevHScore = aScore, hScore

            Timer(0.5, UpdatePredictor)
          else
            -- If elapsed < 0.5 then the event fired twice because both alliance and horde have bases.
            -- 1st update = alliance, 2nd update = horde
            -- If only one faction has bases, the event only fires once.
            -- Unfortunately we need to wait for the 2nd event to fire (the horde update) to know the true horde stats.
            -- In this one where we have 2 updates, we overwrite the horde stats from the 1st update.
            hScore = scoreInfo.rightBarValue -- Horde Bar
            hIncrease = hScore - prevHScore
            hIncBases = hordeIncBases
            -- Always round ticks upwards. 1.2 ticks will always be 2 ticks to end.
            -- If ticks are 0 (no bases) then set to a random huge number (10,000)
            hTicksToWin = NS.getWinTime(maxScore, hScore, hIncrease)
            prevHScore = hScore
          end
        end
      end
    end

    function Info:StartScoreTracker(mapID, baseResources, tickRate, flagResources)
      prevText, prevFutText, prevFlagMessage = "", "", ""
      prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
      timeBetweenEachTick, prevTick, prevWinTime, prevFutWinTime = 0, 0, 0, 0
      minScore, maxScore, aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0, 0, 0
      aRemain, hRemain, aTicksToWin, hTicksToWin, winTime = 0, 0, 0, 0, 0
      aIncBases, prevAIncBases, hIncBases, prevHIncBases = 0, 0, 0, 0
      curBaseResources, curFlagResources = baseResources, flagResources
      curTickRate, curMapID = tickRate, mapID

      InfoFrame:RegisterEvent("UPDATE_UI_WIDGET")
    end

    function Info:StopScoreTracker()
      InfoFrame:UnregisterEvent("UPDATE_UI_WIDGET")
    end
  end
end
