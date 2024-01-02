local _, NS = ...

local next = next
local pairs = pairs
local GetTime = GetTime
local CreateFrame = CreateFrame

local sfind = string.find
local smatch = string.match
local sformat = string.format
local mmin = math.min
local mceil = math.ceil
local mfloor = math.floor

local Timer = C_Timer.After
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo
local GetCaptureBarWidgetVisualizationInfo = C_UIWidgetManager.GetCaptureBarWidgetVisualizationInfo

local Info = {}
NS.Info = Info

local InfoFrame = CreateFrame("Frame", "BGWCInfoFrame")
InfoFrame:SetScript("OnEvent", function(_, event, ...)
  if Info[event] then
    Info[event](Info, ...)
  end
end)

do
  local allyBases, allyIncBases, allyFinalBases = 0, 0, 0
  local hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0
  local allyCarts, hordeCarts = 0, 0
  local allyOrbs, hordeOrbs, allyFlags, hordeFlags = 0, 0, 0, 0
  local allyTimers, hordeTimers, winTable = {}, {}, {}
  local curMapID, curTickRate, curMapInfo = 0, 0, {}
  local prevAOrbs, prevHOrbs = 0, 0
  local maxObjectives = 0

  local function GetFlagValue()
    if NS.isEOTS(curMapID) and (allyBases > 0 or hordeBases > 0) then
      if NS.PLAYER_FACTION == NS.ALLIANCE_NAME and allyBases > 0 then
        local flagValue = curMapInfo.flagResources[allyBases]
        local flagMessage = NS.formatScore(NS.ALLIANCE_NAME, flagValue)

        NS.Interface:UpdateFlagValue(NS.InterfaceFrame.flag, flagMessage)
      elseif NS.PLAYER_FACTION == NS.HORDE_NAME and hordeBases > 0 then
        local flagValue = curMapInfo.flagResources[hordeBases]
        local flagMessage = NS.formatScore(NS.HORDE_NAME, flagValue)

        NS.Interface:UpdateFlagValue(NS.InterfaceFrame.flag, flagMessage)
      end
    end
  end

  local function GetObjectivesByMapID(mapID)
    -- mapID == Zone ID in-game
    -- TOK = 417
    -- DWG = 1576
    -- EOTS = 112, 397
    -- AB = 1366, 1383, 837
    -- TBFG = 275
    -- SSM = 423
    -- WSG = 1339
    -- TP = 206
    if mapID == 417 then
      -- Templf of Kotmogu
      allyOrbs, hordeOrbs = 0, 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(1683)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      -- temple base states are always state 1 which is technically contested in all other maps
      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          allyOrbs = allyOrbs + 1
        end
      end

      for _, v in pairs(baseInfo.rightIcons) do
        if v.iconState == 1 then
          hordeOrbs = hordeOrbs + 1
        end
      end

      if allyOrbs ~= prevAOrbs or hordeOrbs ~= prevHOrbs then
        prevAOrbs = allyOrbs
        prevHOrbs = hordeOrbs

        if allyOrbs == maxObjectives then
          NS.Interface:UpdateBuff(
            NS.InterfaceFrame.buff,
            NS.ORB_BUFF_TIME,
            NS.formatTeamName(NS.ALLIANCE_NAME, NS.PLAYER_FACTION)
          )
        end

        if hordeOrbs == maxObjectives then
          NS.Interface:UpdateBuff(
            NS.InterfaceFrame.buff,
            NS.ORB_BUFF_TIME,
            NS.formatTeamName(NS.HORDE_NAME, NS.PLAYER_FACTION)
          )
        end

        if allyOrbs ~= maxObjectives and hordeOrbs ~= maxObjectives then
          NS.Interface:StopBuff(NS.InterfaceFrame.buff)
        end
      end
    elseif mapID == 1366 or mapID == 1383 or mapID == 837 then
      -- Arathi Basin
      allyBases, allyIncBases, allyFinalBases = 0, 0, 0
      hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0

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

      allyFinalBases = allyBases + allyIncBases
      hordeFinalBases = hordeBases + hordeIncBases
    elseif mapID == 1576 then
      -- Deepwind Gorge
      allyBases, allyIncBases, allyFinalBases = 0, 0, 0
      hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0

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

      allyFinalBases = allyBases + allyIncBases
      hordeFinalBases = hordeBases + hordeIncBases
    elseif mapID == 275 then
      -- The Battle for Gilneas
      allyBases, allyIncBases, allyFinalBases = 0, 0, 0
      hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0

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

      allyFinalBases = allyBases + allyIncBases
      hordeFinalBases = hordeBases + hordeIncBases
    elseif mapID == 112 or mapID == 397 then
      -- Eye of the Storm
      allyBases, allyIncBases, allyFinalBases = 0, 0, 0
      hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(1672)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          local str = v.state1Tooltip

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
          end
        elseif v.iconState == 2 then
          local str = v.state2Tooltip

          allyBases = allyBases + 1

          local base = smatch(str, "captured the (.+)[%p]*")
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
          end
        elseif v.iconState == 2 then
          local str = v.state2Tooltip

          hordeBases = hordeBases + 1

          local base = smatch(str, "captured the (.+)[%p]*")
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

      GetFlagValue()

      allyFinalBases = allyBases + allyIncBases
      hordeFinalBases = hordeBases + hordeIncBases
    elseif mapID == 423 then
      -- Silvershard Mines
      allyCarts, hordeCarts = 0, 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(1700)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          allyCarts = allyCarts + 1
        end
      end
      for _, v in pairs(baseInfo.rightIcons) do
        if v.iconState == 1 then
          hordeCarts = hordeCarts + 1
        end
      end
    end
  end

  function Info:CaptureBarTracker(widgetID)
    -- widgetType == 1
    -- 521 -- all bases random eots
    -- 732 -- lava cart
    -- 794 -- top cart
    -- 795 -- mid cart
    if widgetID == 521 or widgetID == 723 or widgetID == 794 or widgetID == 795 then
      local captureInfo = GetCaptureBarWidgetVisualizationInfo(widgetID)

      if not captureInfo or not captureInfo.barMaxValue then
        return
      end

      -- local barMinValue = captureInfo.barMinValue -- 100 (friendly)
      -- local barMaxValue = captureInfo.barMaxValue -- 0 (enemy)
      -- local barValue = captureInfo.barValue -- (starts at 50)
      -- local isVisible = captureInfo.shownState -- 1 (shown) or 0 (not)
      -- local neutralZoneCenter = captureInfo.neutralZoneCenter -- 50
      -- local neutralZoneSize = captureInfo.neutralZoneSize -- 40/4 (40 on random eots/4 on carts)
      -- so that means your team wins with 71+ (50+(40/2))=70
      -- 50 being middle and 40 point buffer (20 each side)
      -- 100 being fully controlled, 0 being enemy controlled
      -- so positive progression = taking it, negative = losing it
      -- print("barValue", widgetID, barValue, isVisible == 1, neutralZoneCenter, neutralZoneSize)
    end
  end

  function Info:FlagTracker(widgetID)
    -- widgetType == 14
    -- 1672 = EOTS
    -- 1640 = WSG, TP
    if widgetID == 1672 then
      -- Eye of the Storm
      allyFlags = 0
      hordeFlags = 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          local str = v.state1Tooltip

          if sfind(str, "flag") then
            allyFlags = allyFlags + 1
          end
        end
      end

      for _, v in pairs(baseInfo.rightIcons) do
        if v.iconState == 1 then
          local str = v.state1Tooltip

          if sfind(str, "flag") then
            hordeFlags = hordeFlags + 1
          end
        end
      end
    elseif widgetID == 1640 then
      -- Warsong Gulch, Twin Peaks
      allyFlags = 0
      hordeFlags = 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          allyFlags = allyFlags + 1
        end
      end

      for _, v in pairs(baseInfo.rightIcons) do
        if v.iconState == 1 then
          hordeFlags = hordeFlags + 1
        end
      end
    end
  end

  function Info:ObjectiveTracker(widgetID)
    -- widgetType == 14
    -- 1683 = TOK
    -- 2339 = DWG
    -- 1672 = EOTS
    -- 1645 = AB
    -- 1670 = TBFG
    -- 1700 = SSM
    -- 1640 = WSG, TP
    if widgetID == 1683 then
      -- Templf of Kotmogu
      allyOrbs, hordeOrbs = 0, 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      -- temple base states are always state 1 which is technically contested in all other maps
      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          allyOrbs = allyOrbs + 1
        end
      end

      for _, v in pairs(baseInfo.rightIcons) do
        if v.iconState == 1 then
          hordeOrbs = hordeOrbs + 1
        end
      end

      if allyOrbs ~= prevAOrbs or hordeOrbs ~= prevHOrbs then
        prevAOrbs = allyOrbs
        prevHOrbs = hordeOrbs

        if allyOrbs == maxObjectives then
          NS.Interface:UpdateBuff(
            NS.InterfaceFrame.buff,
            NS.ORB_BUFF_TIME,
            NS.formatTeamName(NS.ALLIANCE_NAME, NS.PLAYER_FACTION)
          )
        end

        if hordeOrbs == maxObjectives then
          NS.Interface:UpdateBuff(
            NS.InterfaceFrame.buff,
            NS.ORB_BUFF_TIME,
            NS.formatTeamName(NS.HORDE_NAME, NS.PLAYER_FACTION)
          )
        end

        if allyOrbs ~= maxObjectives and hordeOrbs ~= maxObjectives then
          NS.Interface:StopBuff(NS.InterfaceFrame.buff)
        end
      end
    elseif widgetID == 1645 or widgetID == 1670 or widgetID == 2339 then
      -- Arathi Basin, The Battle for Gilneas, Deepwind Gorge
      allyBases, allyIncBases, allyFinalBases = 0, 0, 0
      hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0

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

      allyFinalBases = allyBases + allyIncBases
      hordeFinalBases = hordeBases + hordeIncBases
    elseif widgetID == 1672 then
      -- Eye of the Storm
      allyBases, allyIncBases, allyFinalBases = 0, 0, 0
      hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          local str = v.state1Tooltip

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
          local str = v.state2Tooltip

          allyBases = allyBases + 1

          local base = smatch(str, "captured the (.+)[%p]*")
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
          local str = v.state2Tooltip

          hordeBases = hordeBases + 1

          local base = smatch(str, "captured the (.+)[%p]*")
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

      GetFlagValue()

      allyFinalBases = allyBases + allyIncBases
      hordeFinalBases = hordeBases + hordeIncBases
    elseif widgetID == 1700 then
      -- Silvershard Mines
      allyCarts, hordeCarts = 0, 0

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      for _, v in pairs(baseInfo.leftIcons) do
        if v.iconState == 1 then
          allyCarts = allyCarts + 1
        end
      end
      for _, v in pairs(baseInfo.rightIcons) do
        if v.iconState == 1 then
          hordeCarts = hordeCarts + 1
        end
      end
    end
  end

  do
    local prevText, prevFutText = "", ""
    local prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
    local timeBetweenEachTick, prevTick, prevWinTime, prevFutWinTime = 0, 0, 0, 0
    local minScore, maxScore, aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0, 0, 0
    local aTicksToWin, hTicksToWin, winTime = 0, 0, 0
    local prevABases, prevHBases, prevAIncBases, prevHIncBases = 0, 0, 0, 0

    local function ScorePredictor()
      if
        aIncrease ~= prevAIncrease
        or hIncrease ~= prevHIncrease
        or timeBetweenEachTick ~= prevTick
        or allyBases ~= prevABases
        or hordeBases ~= prevHBases
        or allyIncBases ~= prevAIncBases
        or hordeIncBases ~= prevHIncBases
      then
        -- Scores can reduce in DWG
        if aIncrease > 60 or hIncrease > 60 or aIncrease < 0 or hIncrease < 0 then
          -- > 60 increase means captured a flag/cart in EOTS/DWG
          NS.Interface:StopBanner(NS.InterfaceFrame.banner)
          NS.Interface:StopInfo(NS.InterfaceFrame.info)
          NS.Interface:ClearAllText()

          prevAIncrease, prevHIncrease = -1, -1
          return
        end

        prevAIncrease = aIncrease
        prevHIncrease = hIncrease
        prevTick = timeBetweenEachTick
        prevABases = allyBases
        prevHBases = hordeBases
        prevAIncBases = allyIncBases
        prevHIncBases = hordeIncBases

        local currentAWinTime = aTicksToWin
        local currentHWinTime = hTicksToWin
        local currentWinTime = mmin(currentAWinTime, currentHWinTime)

        if allyIncBases == 0 and hordeIncBases == 0 then
          winTime = currentWinTime

          local aWins = currentAWinTime < currentHWinTime

          local afs = aWins and maxScore or aScore + (winTime * curMapInfo.baseResources[allyBases])
          local hfs = aWins and hScore + (winTime * curMapInfo.baseResources[hordeBases]) or maxScore
          local finalAScore = (allyBases == 0 and allyIncBases == 0) and aScore or afs
          local finalHScore = (hordeBases == 0 and hordeIncBases == 0) and hScore or hfs

          if currentAWinTime == currentHWinTime or finalAScore == finalHScore then
            local winText = "TIE"
            local winColor = { r = 0, g = 0, b = 0 }

            NS.Interface:UpdateBanner(NS.InterfaceFrame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevWinTime then
              prevWinTime = winTime
            end

            NS.Interface:StopInfo(NS.InterfaceFrame.info)
            NS.Interface:ClearAllText()

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            local loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"
            local winColor = winText == "WIN" and { r = 36, g = 126, b = 36 } or { r = 175, g = 34, b = 47 }
            local txt = sformat("Final Score: %d - %d", finalAScore, finalHScore)

            NS.Interface:UpdateBanner(NS.InterfaceFrame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevWinTime then
              prevWinTime = winTime
            end

            NS.Interface:UpdateFinalScore(NS.InterfaceFrame.score, finalAScore, finalHScore)
            if txt ~= prevText then
              prevText = txt
            end

            local winBases = aWins and allyBases or hordeBases
            local loseBases = aWins and hordeBases or allyBases
            local winScore = aWins and aScore or hScore
            local loseScore = aWins and hScore or aScore

            winTable = {}
            for bases = loseBases + 1, maxObjectives do
              local table = NS.checkWinCondition(
                bases,
                maxObjectives,
                winBases,
                loseBases,
                winTime,
                winScore,
                loseScore,
                curMapInfo.baseResources,
                maxScore,
                0,
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
            NS.getIncomingBaseInfo(allyTimers, allyBases, allyIncBases, curMapInfo.baseResources, currentWinTime)
          local hBaseIncrease, hTimeIncrease, hScoreIncrease =
            NS.getIncomingBaseInfo(hordeTimers, hordeBases, hordeIncBases, curMapInfo.baseResources, currentWinTime)

          local newAllyScore = aScore + aScoreIncrease
          local newHordeScore = hScore + hScoreIncrease

          local newAllyBases = allyBases + aBaseIncrease
          local newHordeBases = hordeBases + hBaseIncrease

          local aFutureScore = newAllyScore
          local hFutureScore = newHordeScore

          if aTimeIncrease ~= 0 or hTimeIncrease ~= 0 then
            if aTimeIncrease > hTimeIncrease then
              local timeDifference = aTimeIncrease - hTimeIncrease
              local scoreDifference = hFutureScore + timeDifference * curMapInfo.baseResources[newHordeBases]
              if scoreDifference < maxScore then
                hFutureScore = scoreDifference
              end
            elseif hTimeIncrease > aTimeIncrease then
              local timeDifference = hTimeIncrease - aTimeIncrease
              local scoreDifference = aFutureScore + timeDifference * curMapInfo.baseResources[newAllyBases]
              if scoreDifference < maxScore then
                aFutureScore = scoreDifference
              end
            end
          end

          local aFutureTicksToWin = NS.getWinTime(maxScore, aFutureScore, curMapInfo.baseResources[newAllyBases])
          local hFutureTicksToWin = NS.getWinTime(maxScore, hFutureScore, curMapInfo.baseResources[newHordeBases])
          local winTicks = mmin(aFutureTicksToWin, hFutureTicksToWin)

          local aWins = aFutureTicksToWin < hFutureTicksToWin
          local afs = aWins and maxScore or aFutureScore + (winTicks * curMapInfo.baseResources[newAllyBases])
          local hfs = aWins and hFutureScore + (winTicks * curMapInfo.baseResources[newHordeBases]) or maxScore
          local finalAScore = (allyBases == 0 and allyIncBases == 0) and aScore or afs
          local finalHScore = (hordeBases == 0 and hordeIncBases == 0) and hScore or hfs

          local winTimeIncrease = aWins and aTimeIncrease or hTimeIncrease
          winTime = winTicks + winTimeIncrease

          if aFutureTicksToWin == hFutureTicksToWin or finalAScore == finalHScore then
            local winText = "TIE"
            local winColor = { r = 0, g = 0, b = 0 }

            NS.Interface:UpdateBanner(NS.InterfaceFrame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevWinTime then
              prevWinTime = winTime
            end

            NS.Interface:StopInfo(NS.InterfaceFrame.info)
            NS.Interface:ClearAllText()

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local currentLoseBases = aWins and hordeBases or allyBases

            local winbases = aWins and newAllyBases or newHordeBases
            local loseBases = aWins and newHordeBases or newAllyBases
            local winScore = aWins and aFutureScore or hFutureScore
            local loseScore = aWins and hFutureScore or aFutureScore

            local winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            local loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            local winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"
            local winColor = winText == "WIN" and { r = 36, g = 126, b = 36 } or { r = 175, g = 34, b = 47 }
            local txt = sformat("Final Score: %d - %d", finalAScore, finalHScore)

            NS.Interface:UpdateBanner(NS.InterfaceFrame.banner, winTime - 0.5, winText, winColor)
            if winTime ~= prevFutWinTime then
              prevFutWinTime = winTime
            end

            NS.Interface:UpdateFinalScore(NS.InterfaceFrame.score, finalAScore, finalHScore)
            if txt ~= prevFutText then
              prevFutText = txt
            end

            winTable = {}
            for bases = currentLoseBases + 1, maxObjectives do
              local table = NS.checkWinCondition(
                bases,
                maxObjectives,
                winbases,
                loseBases,
                winTime,
                winScore,
                loseScore,
                curMapInfo.baseResources,
                maxScore,
                winTimeIncrease,
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
          NS.Interface:UpdateInfo(NS.InterfaceFrame.info, winTime - 0.5, winTable)
        end

        GetFlagValue()
      end
    end

    function Info:ScoreTracker(widgetID)
      -- widgetType == 3
      -- 1687 = SSM
      -- 1689 = TOK
      -- 2074 = DWG
      -- 1671 = AB, TBFG, EOTS
      if widgetID == 1671 or widgetID == 2074 then
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(widgetID)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
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
          -- Always round ticks upwards. 1.2 ticks will always be 2 ticks to end.
          -- If ticks are 0 (no bases) then set to a random huge number (10,000)
          aTicksToWin = NS.getWinTime(maxScore, aScore, curMapInfo.baseResources[allyBases])
          hTicksToWin = NS.getWinTime(maxScore, hScore, curMapInfo.baseResources[hordeBases])
          -- Round to the closest time
          timeBetweenEachTick = elapsed % 1 >= 0.5 and mceil(elapsed) or mfloor(elapsed)
          prevAScore, prevHScore = aScore, hScore
          prevABases, prevHBases = allyBases, hordeBases
          prevAIncBases, prevHIncBases = allyIncBases, hordeIncBases

          Timer(0.5, ScorePredictor)
        else
          -- If elapsed < 0.5 then the event fired twice because both alliance and horde have bases.
          -- 1st update = alliance, 2nd update = horde
          -- If only one faction has bases, the event only fires once.
          -- Unfortunately we need to wait for the 2nd event to fire (the horde update) to know the true horde stats.
          -- In this one where we have 2 updates, we overwrite the horde stats from the 1st update.
          hScore = scoreInfo.rightBarValue -- Horde Bar
          hIncrease = hScore - prevHScore
          -- Always round ticks upwards. 1.2 ticks will always be 2 ticks to end.
          -- If ticks are 0 (no bases) then set to a random huge number (10,000)
          hTicksToWin = NS.getWinTime(maxScore, hScore, curMapInfo.baseResources[hordeBases])
          prevHScore = hScore
          prevHBases = hordeBases
          prevHIncBases = hordeIncBases
        end
      end
    end

    function Info:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        self:ObjectiveTracker(widgetID)
        self:FlagTracker(widgetID)
        self:CaptureBarTracker(widgetID)
        self:ScoreTracker(widgetID)
      end
    end

    function Info:StartInfoTracker(mapID, tickRate, mapResources, maxResources)
      -- local
      prevText, prevFutText = "", ""
      prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
      timeBetweenEachTick, prevTick, prevWinTime, prevFutWinTime = 0, 0, 0, 0
      minScore, maxScore, aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0, 0, 0
      aTicksToWin, hTicksToWin, winTime = 0, 0, 0
      prevABases, prevHBases, prevAIncBases, prevHIncBases = 0, 0, 0, 0
      -- global
      curMapID, curTickRate, curMapInfo = mapID, tickRate, mapResources
      allyBases, allyIncBases, allyFinalBases = 0, 0, 0
      hordeBases, hordeIncBases, hordeFinalBases = 0, 0, 0
      allyCarts, hordeCarts = 0, 0
      allyOrbs, hordeOrbs, allyFlags, hordeFlags = 0, 0, 0, 0
      allyTimers, hordeTimers, winTable = {}, {}, {}
      prevAOrbs, prevHOrbs = 0, 0
      maxObjectives = maxResources

      GetObjectivesByMapID(curMapID)

      InfoFrame:RegisterEvent("UPDATE_UI_WIDGET")
    end
  end

  function Info:StopInfoTracker()
    InfoFrame:UnregisterEvent("UPDATE_UI_WIDGET")
  end
end
