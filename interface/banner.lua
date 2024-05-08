local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime

local mmin = math.min
local mmax = math.max

local LSM = LibStub("LibSharedMedia-3.0")

local Banner = {}
NS.Banner = Banner

local BannerFrame = CreateFrame("Frame", AddonName .. "BannerFrame", UIParent)
Banner.frame = BannerFrame

function Banner:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOP", anchor, "BOTTOM", x, y)
end

function Banner:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
end

function Banner:SetBackgroundColor(frame, color)
  frame:SetColorTexture(color.r, color.g, color.b, color.a)
end

function Banner:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Banner:SetFont(frame)
  frame:SetFont(LSM:Fetch("font", NS.db.global.general.bannergroup.bannerfont), 12, "NORMAL")
end

function Banner:SetScale(frame)
  frame:SetScale(NS.db.global.general.bannergroup.bannerscale)
end

function Banner:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

local function stopAnimation(frame, animationGroup)
  animationGroup:Stop()
  frame.frame:SetAlpha(0)
  frame.text:SetFormattedText("")
end

function Banner:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local bannerformat = "GG YOU %s IN %s"

local function animationUpdate(frame, text, animationGroup)
  local t = GetTime()
  if t >= frame.exp then
    animationGroup:Stop()
  -- frame.text:Hide()
  else
    local time = frame.exp - t
    frame.remaining = time
    Banner:SetText(frame.text, bannerformat, text, NS.formatTime(time))
    -- frame.text:Show()
  end
end

function Banner:Start(duration, text)
  self:Stop(self, self.timerAnimationGroup)

  local BGColor
  local TextColor
  if text == "TIE" then
    BGColor = NS.db.global.general.bannergroup.tiebgcolor
    TextColor = NS.db.global.general.bannergroup.tietextcolor
  elseif text == "WIN" then
    BGColor = NS.db.global.general.bannergroup.winbgcolor
    TextColor = NS.db.global.general.bannergroup.wintextcolor
  else
    BGColor = NS.db.global.general.bannergroup.losebgcolor
    TextColor = NS.db.global.general.bannergroup.losetextcolor
  end

  self:SetBackgroundColor(self.bg, BGColor)
  self:SetTextColor(self.text, TextColor)
  self:SetFont(self.text)
  self:SetScale(BannerFrame)

  self.remaining = mmin(mmax(0, duration), 1500)
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  self:SetText(self.text, bannerformat, text, NS.formatTime(time))

  if NS.db.global.general.info == false then
    self.frame:SetAlpha(1)
  else
    self.frame:SetAlpha(0)
  end

  self.timerAnimationGroup:SetScript("OnLoop", function(updatedGroup)
    if updatedGroup then
      animationUpdate(Banner, text, updatedGroup)
    end
  end)

  self.timerAnimationGroup:Play()
end

function Banner:Create(anchor)
  if not Banner.text then
    local BG = BannerFrame:CreateTexture(nil, "BACKGROUND")
    BG:SetAllPoints()
    self:SetBackgroundColor(BG, NS.db.global.general.bannergroup.tiebgcolor)

    local Text = BannerFrame:CreateFontString(nil, "ARTWORK")
    self:SetTextColor(Text, NS.db.global.general.bannergroup.tietextcolor)
    self:SetFont(Text)
    Text:SetShadowOffset(1, -1)
    Text:SetShadowColor(0, 0, 0, 0.9)
    Text:SetJustifyH("CENTER")
    Text:SetJustifyV("MIDDLE")
    Text:SetPoint("CENTER", BG, "CENTER", 0, 0)

    BannerFrame:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
    BannerFrame:SetWidth(175)
    BannerFrame:SetHeight(25)
    self:SetScale(BannerFrame)

    Banner.bg = BG
    Banner.text = Text
    Banner.timerAnimationGroup = NS.CreateTimerAnimation(BannerFrame)
  end
end
