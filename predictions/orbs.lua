local _, NS = ...

local pairs = pairs

local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo

local Buff = NS.Buff

local OrbPrediction = {}
NS.OrbPrediction = OrbPrediction

local OrbFrame = CreateFrame("Frame", "OrbFrame")
OrbFrame:SetScript("OnEvent", function(_, event, ...)
  if OrbPrediction[event] then
    OrbPrediction[event](OrbPrediction, ...)
  end
end)

do
  local allyOrbs, hordeOrbs = 0, 0
  local curMapID = 0
  local prevAOrbs, prevHOrbs = 0, 0
  local maxObjectives = 0

  do
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
            allyOrbs = allyOrbs + 1
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == 1 then
            hordeOrbs = hordeOrbs + 1
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
            Buff:Start(NS.ORB_BUFF_TIME, NS.formatTeamName(NS.ALLIANCE_NAME, NS.PLAYER_FACTION))
          end

          if hordeOrbs == maxObjectives then
            Buff:Start(NS.ORB_BUFF_TIME, NS.formatTeamName(NS.HORDE_NAME, NS.PLAYER_FACTION))
          end

          if allyOrbs ~= maxObjectives and hordeOrbs ~= maxObjectives then
            Buff:Stop(Buff.text, Buff.timerAnimationGroup)
          end
        end
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

    function OrbPrediction:StartInfoTracker(mapID, maxResources)
      -- local
      -- global
      curMapID = mapID
      allyOrbs, hordeOrbs = 0, 0
      prevAOrbs, prevHOrbs = 0, 0
      maxObjectives = maxResources

      self:GetObjectivesByMapID(curMapID)

      OrbFrame:RegisterEvent("UPDATE_UI_WIDGET")
    end
  end
end

function OrbPrediction:StopInfoTracker()
  OrbFrame:UnregisterEvent("UPDATE_UI_WIDGET")
end
