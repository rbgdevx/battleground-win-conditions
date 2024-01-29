local AddonName, NS = ...

local CreateFrame = CreateFrame
local GetTime = GetTime

local LSM = LibStub("LibSharedMedia-3.0")

local Buff = {}
NS.Buff = Buff

local BuffFrame = CreateFrame("Frame", AddonName .. "BuffFrame", UIParent)

function Buff:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Buff:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
  NS.UpdateSize(BuffFrame, frame)
end

function Buff:SetFont(frame)
  frame:SetFont(
    LSM:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "THINOUTLINE"
  )
  NS.UpdateSize(BuffFrame, frame)
end

function Buff:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

local function stopAnimation(frame, animationGroup)
  animationGroup:Stop()
  frame:SetAlpha(0)
  frame:SetFormattedText("")
end

function Buff:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local buffformat1 = "%s get 4x points in %s"
local buffformat2 = "%s are earning 4x points"

local function animationUpdate(frame, text, animationGroup)
  local t = GetTime()
  if t >= frame.exp then
    animationGroup:Stop()
    Buff:SetText(frame.text, buffformat2, text)
  -- frame.text:Hide()
  else
    local time = frame.exp - t
    frame.remaining = time
    Buff:SetText(frame.text, buffformat1, text, NS.formatTime(time))
    -- frame.text:Show()
  end
end

function Buff:Start(duration, text)
  self:Stop(self.text, self.timerAnimationGroup)

  self.remaining = duration
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  self:SetText(self.text, buffformat1, text, NS.formatTime(time))
  self:SetFont(self.text)

  self.frame:SetAlpha(1)
  self.text:SetAlpha(1)

  self.timerAnimationGroup:SetScript("OnLoop", function(updatedGroup)
    if updatedGroup then
      animationUpdate(Buff, text, updatedGroup)
    end
  end)

  self.timerAnimationGroup:Play()
end

function Buff:Create(anchor)
  if not Buff.frame then
    local Text = BuffFrame:CreateFontString(nil, "ARTWORK")
    self:SetFont(Text)
    Text:SetAllPoints()
    Text:SetTextColor(1, 1, 1, 1)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    BuffFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)

    Buff.frame = BuffFrame
    Buff.text = Text
    Buff.timerAnimationGroup = NS.CreateTimerAnimation(BuffFrame)
  end
end
