local AddonName, NS = ...

local CreateFrame = CreateFrame

local LSM = LibStub("LibSharedMedia-3.0")

local Flag = {}
NS.Flag = Flag

local FlagFrame = CreateFrame("Frame", AddonName .. "FlagFrame", UIParent)

local flagformat = "%s by %d %s"

function Flag:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Flag:SetText(frame, faction, winName, flagsNeeded)
  local label = faction == winName and "Ahead" or "Behind"
  local noun = flagsNeeded == 1 and "flag" or "flags"
  frame:SetFormattedText(flagformat, label, flagsNeeded, noun)
  NS.UpdateSize(FlagFrame, frame)

  if NS.db.global.general.banner == false then
    FlagFrame:SetAlpha(1)
    frame:SetAlpha(1)
  else
    FlagFrame:SetAlpha(0)
    frame:SetAlpha(0)
  end
end

function Flag:SetFont(frame)
  frame:SetFont(
    LSM:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "THINOUTLINE"
  )
  NS.UpdateSize(FlagFrame, frame)
end

function Flag:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

function Flag:Create(anchor)
  if not Flag.frame then
    local Text = FlagFrame:CreateFontString(nil, "ARTWORK")
    self:SetFont(Text)
    Text:SetAllPoints()
    Text:SetTextColor(1, 1, 1, 1)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    FlagFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)

    Flag.frame = FlagFrame
    Flag.text = Text
  end
end
