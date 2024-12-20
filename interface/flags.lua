local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub

local LSM = LibStub("LibSharedMedia-3.0")

local Info = NS.Info

local Flags = {}
NS.Flags = Flags

local FlagsFrame = CreateFrame("Frame", AddonName .. "FlagsFrame", Info.frame)
Flags.frame = FlagsFrame

local flagformat = "%s by %d %s"

function Flags:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Flags:SetText(frame, faction, winName, flagsNeeded)
  local label = faction == winName and "Ahead" or "Behind"
  local noun = flagsNeeded == 1 and "flag" or "flags"
  frame:SetFormattedText(flagformat, label, flagsNeeded, noun)
  NS.UpdateSize(FlagsFrame, frame)

  if NS.db.global.general.banner == false and NS.db.global.maps.eyeofthestorm.showflaginfo then
    FlagsFrame:SetAlpha(1)
  else
    FlagsFrame:SetAlpha(0)
  end
end

function Flags:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Flags:SetFont(frame)
  frame:SetFont(
    LSM:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "OUTLINE"
  )
  NS.UpdateSize(FlagsFrame, frame)
end

function Flags:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

function Flags:Stop(frame)
  frame.frame:SetAlpha(0)

  if frame.text then
    frame.text:SetFormattedText("")
  end
end

function Flags:Create(anchor)
  if not Flags.text then
    local Text = FlagsFrame:CreateFontString(nil, "ARTWORK")
    Text:SetAllPoints()
    self:SetFont(Text)
    self:SetTextColor(Text, NS.db.global.general.infogroup.infotextcolor)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    FlagsFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    FlagsFrame:SetAlpha(0)

    Flags.text = Text
  end
end
