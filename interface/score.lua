local AddonName, NS = ...

local CreateFrame = CreateFrame

local LSM = LibStub("LibSharedMedia-3.0")

local Score = {}
NS.Score = Score

local ScoreFrame = CreateFrame("Frame", AddonName .. "ScoreFrame", UIParent)

local scoreformat = "Final Score: %s - %s"

function Score:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Score:SetText(frame, aScore, hScore)
  local aScoreFormatted = NS.formatScore(NS.ALLIANCE_NAME, aScore)
  local hScoreFormatted = NS.formatScore(NS.HORDE_NAME, hScore)
  frame:SetFormattedText(scoreformat, aScoreFormatted, hScoreFormatted)
  NS.UpdateSize(ScoreFrame, frame)

  if NS.db.global.general.banner == false then
    ScoreFrame:SetAlpha(1)
    frame:SetAlpha(1)
  else
    ScoreFrame:SetAlpha(0)
    frame:SetAlpha(0)
  end
end

function Score:SetFont(frame)
  frame:SetFont(
    LSM:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "THINOUTLINE"
  )
  NS.UpdateSize(ScoreFrame, frame)
end

function Score:ToggleAlpha()
  local curAlpha = ScoreFrame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  ScoreFrame:SetAlpha(newAlpha)
end

function Score:Create(anchor)
  if not Score.frame then
    local Text = ScoreFrame:CreateFontString(nil, "ARTWORK")
    self:SetFont(Text)
    Text:SetAllPoints()
    Text:SetTextColor(1, 1, 1, 1)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    ScoreFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -5)

    Score.frame = ScoreFrame
    Score.text = Text
  end
end
