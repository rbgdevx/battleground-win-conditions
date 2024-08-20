local _, NS = ...

local pairs = pairs
local ipairs = ipairs
local CreateFrame = CreateFrame
local GetRealmName = GetRealmName
local UnitName = UnitName
local UnitExists = UnitExists
local select = select

local smatch = string.match

local After = C_Timer.After
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID

local Orbs = NS.Orbs

local OrbPrediction = {}
NS.OrbPrediction = OrbPrediction

local OrbFrame = CreateFrame("Frame", "OrbFrame")
OrbFrame:SetScript("OnEvent", function(_, event, ...)
  if OrbPrediction[event] then
    OrbPrediction[event](OrbPrediction, ...)
  end
end)

local function noOrbCarriers(orbs)
  for _, value in pairs(orbs) do
    if value ~= "" then
      return false
    end
  end
  return true
end

do
  local allyOrbs, hordeOrbs = 0, 0
  local prevAOrbs, prevHOrbs = 0, 0
  local curMap = {
    id = 0,
    maxOrbs = 0,
    tickRate = 0,
    buffTime = 0,
  }
  local pickedOrbs = {
    ["Blue"] = false,
    ["Green"] = false,
    ["Orange"] = false,
    ["Purple"] = false,
  }
  local orbTypes = {
    ["Blue"] = 121164, -- Orb of Power (Blue)
    ["Green"] = 121176, -- Orb of Power (Green)
    ["Orange"] = 121177, -- Orb of Power (Orange)
    ["Purple"] = 121175, -- Orb of Power (Purple)
  }

  do
    local orbCarriers = {
      ["Blue"] = "",
      ["Green"] = "",
      ["Orange"] = "",
      ["Purple"] = "",
    }
    local orbStacks = {
      ["Blue"] = 0,
      ["Green"] = 0,
      ["Orange"] = 0,
      ["Purple"] = 0,
    }

    -- aura.points[1] = Negative Healing Received, ex: -10
    -- aura.points[2] = Damage taken increase, ex: 60
    -- aura.points[3] = Damage done increase, ex: 20
    local function updateOrbStacks(unitTarget, orbKey, spellId, changeType, updateInfo, isRemoved)
      local name, realm = UnitName(unitTarget)
      local nameAndRealm = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())

      if orbCarriers[orbKey] == nameAndRealm then
        if changeType == "update" or changeType == "remove" then
          for _, auraInstanceID in ipairs(updateInfo) do
            local aura = GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID)
            if aura and aura.spellId == spellId then
              orbStacks[orbKey] = isRemoved and 0 or aura.points[2]
              Orbs:StartOrbList(orbStacks)
              break
            end
          end
        elseif changeType == "add" then
          for _, aura in ipairs(updateInfo) do
            if aura and aura.spellId == spellId then
              orbStacks[orbKey] = aura.points[2]
              Orbs:StartOrbList(orbStacks)
              break
            end
          end
        end
      end
    end

    function OrbPrediction:UNIT_AURA(unitTarget, updateInfo)
      if updateInfo.isFullUpdate or noOrbCarriers(orbCarriers) then
        return
      end

      -- added doesnt show up since its added by the time we start tracking
      -- if updateInfo.addedAuras then
      --   for orb, spellId in pairs(orbTypes) do
      --     updateOrbStacks(unitTarget, orb, spellId, "add", updateInfo.addedAuras, false)
      --   end
      -- end

      if updateInfo.updatedAuraInstanceIDs then
        for orb, spellId in pairs(orbTypes) do
          updateOrbStacks(unitTarget, orb, spellId, "update", updateInfo.updatedAuraInstanceIDs, false)
        end
      end

      -- we're tracking orbs being removed elsewhere
      -- if updateInfo.removedAuraInstanceIDs then
      --   for orb, spellId in pairs(orbTypes) do
      --     updateOrbStacks(unitTarget, orb, spellId, "remove", updateInfo.removedAuraInstanceIDs, true)
      --   end
      -- end
    end

    function OrbPrediction:BuffTimer(aOrbs, hOrbs, pAOrbs, pHOrbs)
      if aOrbs ~= pAOrbs or hOrbs ~= pHOrbs then
        prevAOrbs = aOrbs
        prevHOrbs = hOrbs

        if aOrbs == curMap.maxOrbs then
          Orbs:Start(curMap.buffTime, NS.formatTeamName(NS.ALLIANCE_NAME, NS.PLAYER_FACTION))
        end

        if hOrbs == curMap.maxOrbs then
          Orbs:Start(curMap.buffTime, NS.formatTeamName(NS.HORDE_NAME, NS.PLAYER_FACTION))
        end

        if aOrbs ~= curMap.maxOrbs and hOrbs ~= curMap.maxOrbs then
          Orbs:Stop(Orbs, Orbs.timerAnimationGroup, false)
        end

        if aOrbs == 0 and hOrbs == 0 then
          OrbFrame:UnregisterEvent("UNIT_AURA")
        end
      end
    end

    function OrbPrediction:GetObjectivesByMapID(mapID)
      -- mapID == Zone ID in-game
      -- TOK = 417
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
            local str = v.state1Tooltip

            allyOrbs = allyOrbs + 1

            local orb = smatch(str, "the (%a+) orb")
            pickedOrbs[orb] = true
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            hordeOrbs = hordeOrbs + 1

            local orb = smatch(str, "the (%a+) orb")
            pickedOrbs[orb] = true
          end
        end
      end
    end

    function OrbPrediction:ObjectiveTracker(widgetID)
      -- widgetType == 14
      -- 1683 = TOK
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
            local str = v.state1Tooltip

            allyOrbs = allyOrbs + 1

            local orb = smatch(str, "the (%a+) orb")
            pickedOrbs[orb] = true
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            local str = v.state1Tooltip

            hordeOrbs = hordeOrbs + 1

            local orb = smatch(str, "the (%a+) orb")
            pickedOrbs[orb] = true
          end
        end

        self:BuffTimer(allyOrbs, hordeOrbs, prevAOrbs, prevHOrbs)
      end
    end

    local function filterDebuffs(unitID, ...)
      local spellId = select(10, ...)
      if spellId then
        if
          spellId == orbTypes["Blue"]
          or spellId == orbTypes["Green"]
          or spellId == orbTypes["Orange"]
          or spellId == orbTypes["Purple"]
        then
          local name, realm = UnitName(unitID)
          local nameAndRealm = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
          if spellId == orbTypes["Blue"] then
            local debuffPercentage = select(17, ...)
            orbCarriers["Blue"] = nameAndRealm
            pickedOrbs["Blue"] = true
            orbStacks["Blue"] = debuffPercentage
          elseif spellId == orbTypes["Green"] then
            local debuffPercentage = select(17, ...)
            orbCarriers["Green"] = nameAndRealm
            pickedOrbs["Green"] = true
            orbStacks["Green"] = debuffPercentage
          elseif spellId == orbTypes["Orange"] then
            local debuffPercentage = select(17, ...)
            orbCarriers["Orange"] = nameAndRealm
            pickedOrbs["Orange"] = true
            orbStacks["Orange"] = debuffPercentage
          elseif spellId == orbTypes["Purple"] then
            local debuffPercentage = select(17, ...)
            orbCarriers["Purple"] = nameAndRealm
            pickedOrbs["Purple"] = true
            orbStacks["Purple"] = debuffPercentage
          end
          return true
        end
      end
    end

    function OrbPrediction:GetStacksByMapID(mapID)
      -- mapID == Zone ID in-game
      -- TOK = 417
      if mapID == 417 then
        -- Temple of Kotmogu
        if UnitExists("arena1") or UnitExists("arena2") or UnitExists("arena3") or UnitExists("arena4") then
          for i = 1, 4 do
            local unitID = "arena" .. i
            if unitID then
              -- Apply debuff filtering
              -- orbs are only debuffs
              AuraUtil.ForEachAura(unitID, "HARMFUL", nil, function(...)
                return filterDebuffs(unitID, ...)
              end)
            end
          end

          OrbFrame:RegisterEvent("UNIT_AURA")
        end
      end
    end

    function OrbPrediction:CHAT_MSG_BG_SYSTEM_ALLIANCE(message, _)
      local pickedName = smatch(message, "^(.-) has taken the") -- alliance picked orb
      local pickedOrb = smatch(message, "the (|c%x%x%x%x%x%x%x%x%a+|r) orb") -- orb with color
      if pickedOrb then
        if noOrbCarriers(orbCarriers) then
          OrbFrame:RegisterEvent("UNIT_AURA")
        end

        local orbKey = NS.stripColorCode(pickedOrb)
        orbCarriers[orbKey] = pickedName
        orbStacks[orbKey] = 30
        Orbs:StartOrbList(orbStacks)
      end
    end

    function OrbPrediction:CHAT_MSG_BG_SYSTEM_HORDE(message, _)
      local pickedName = smatch(message, "^(.-) has taken the") -- horde picked orb
      local pickedOrb = smatch(message, "the (|c%x%x%x%x%x%x%x%x%a+|r) orb") -- orb with color
      if pickedOrb then
        if noOrbCarriers(orbCarriers) then
          OrbFrame:RegisterEvent("UNIT_AURA")
        end

        local orbKey = NS.stripColorCode(pickedOrb)
        orbCarriers[orbKey] = pickedName
        orbStacks[orbKey] = 30
        Orbs:StartOrbList(orbStacks)
      end
    end

    function OrbPrediction:CHAT_MSG_BG_SYSTEM_NEUTRAL(message)
      local gameOver = string.find(message, "wins") -- someone wins
      if gameOver then
        Orbs:Stop(Orbs, Orbs.timerAnimationGroup, true)

        for k, _ in pairs(orbCarriers) do
          orbCarriers[k] = ""
          pickedOrbs[k] = false
        end
      end
    end

    function OrbPrediction:CHAT_MSG_RAID_BOSS_EMOTE(message)
      -- local droppedName = playerName2 -- name without realm
      local droppedOrb = smatch(message, "The (|c%x%x%x%x%x%x%x%x%a+|r) orb") -- orb with color
      if droppedOrb then
        local orbKey = NS.stripColorCode(droppedOrb)
        orbCarriers[orbKey] = ""
        orbStacks[orbKey] = 0
        pickedOrbs[orbKey] = false
        Orbs:StartOrbList(orbStacks)
      end
    end

    function OrbPrediction:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        OrbPrediction:ObjectiveTracker(widgetID)
      end
    end

    ---[[
    -- Fires after one of:
    -- - Performing a successful corpse run and the player accepts the 'Resurrect Now' box.
    -- - Accepting a resurrect from another player after releasing from a death.
    -- - Zoning into an instance where the player is dead.
    -- - When the player accept a resurrect from a Spirit Healer.
    -- PLAYER_ALIVE
    -- - Fired when the player releases from death to a graveyard; or accepts a resurrect before releasing their spirit.
    --]]
    function OrbPrediction:PLAYER_UNGHOST()
      self:GetStacksByMapID(curMap.id)
      Orbs:StartOrbList(orbStacks)
    end

    function OrbPrediction:StartInfoTracker(mapInfo)
      -- local
      orbCarriers = {
        ["Blue"] = "",
        ["Green"] = "",
        ["Orange"] = "",
        ["Purple"] = "",
      }
      orbStacks = {
        ["Blue"] = 0,
        ["Green"] = 0,
        ["Orange"] = 0,
        ["Purple"] = 0,
      }
      -- global
      pickedOrbs = {
        ["Blue"] = false,
        ["Green"] = false,
        ["Orange"] = false,
        ["Purple"] = false,
      }
      curMap = mapInfo
      allyOrbs, hordeOrbs = 0, 0
      prevAOrbs, prevHOrbs = 0, 0

      self:GetObjectivesByMapID(curMap.id)
      self:GetStacksByMapID(curMap.id)
      Orbs:StartOrbList(orbStacks)

      -- OrbFrame:RegisterEvent("UNIT_AURA")
      OrbFrame:RegisterEvent("UPDATE_UI_WIDGET")
      OrbFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
      OrbFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
      OrbFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
      OrbFrame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
      OrbFrame:RegisterEvent("PLAYER_UNGHOST")
    end
  end
end

function OrbPrediction:StopInfoTracker()
  OrbFrame:UnregisterEvent("UNIT_AURA")
  OrbFrame:UnregisterEvent("UPDATE_UI_WIDGET")
  OrbFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
  OrbFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
  OrbFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
  OrbFrame:UnregisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
  OrbFrame:UnregisterEvent("PLAYER_UNGHOST")
end
