local _, NS = ...

local Banner = {}
NS.Banner = Banner
NS.barCache = NS.barCache or {}

local barCache = NS.barCache

local next = next
local GetTime = GetTime
local CreateFrame = CreateFrame

local mmin = math.min
local mmax = math.max

function Banner:SetBackgroundColor(bar, color)
  bar.bg:SetColorTexture(color.r / 255, color.g / 255, color.b / 255, 0.9)
end

function Banner:SetDuration(bar, duration)
  bar.remaining = mmin(mmax(0, duration), 1500)
end

function Banner:Create(label, width, height)
  local bar = next(barCache)

  if not bar then
    local frame = CreateFrame("Frame", "BGWCBannerFrame", UIParent)
    bar = {}

    bar.label = label

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bar.bg = bg

    local text = frame:CreateFontString(nil, "ARTWORK")
    text:SetPoint("CENTER", bg, "CENTER", 0, 0)
    bar.text = text

    local updater = frame:CreateAnimationGroup()
    updater:SetLooping("REPEAT")
    -- updater.parent = bar

    local anim = updater:CreateAnimation()
    anim:SetDuration(0.05)

    bar.updater = updater
    bar.frame = frame
  else
    barCache[bar] = nil
  end

  bar.frame:SetFrameStrata("MEDIUM")
  bar.frame:SetFrameLevel(100)
  bar.frame:ClearAllPoints()
  bar.frame:SetWidth(width)
  bar.frame:SetHeight(height)
  bar.frame:SetMovable(false)
  bar.frame:SetScale(1)
  bar.frame:SetAlpha(1)
  bar.frame:SetClampedToScreen(false)
  bar.frame:EnableMouse(false)

  return bar
end

local function stopBanner(bar)
  bar.updater:Stop()
  bar.frame:Hide()
  bar.frame:SetParent(UIParent)
  barCache[bar] = true
end

function Banner:Stop(bar)
  stopBanner(bar)
  barCache[bar] = true
end

local bannerformat = "GG YOU %s IN %s"

local function bannerUpdate(bar, updater)
  local t = GetTime()
  if t >= bar.exp then
    bar.updater:Stop()
    -- bar.frame:Hide()
    -- bar.frame:SetParent(UIParent)
  else
    local time = bar.exp - t
    bar.remaining = time
    bar.text:SetFormattedText(bannerformat, bar.winName, NS.formatTime(time))
  end
end

function Banner:Start(bar, text)
  bar.running = true
  local time = bar.remaining
  bar.start = GetTime()
  bar.exp = bar.start + time
  bar.winName = text

  bar.text:SetFormattedText(bannerformat, bar.winName, NS.formatTime(time))

  bar.frame:Show()

  bar.updater:SetScript("OnLoop", function(updater)
    bannerUpdate(bar, updater)
  end)

  bar.updater:Play()
end

function Banner:HideBanner(bar)
  if bar.frame then
    bar.frame:SetAlpha(0)
  end
end

function Banner:ShowBanner(bar)
  if bar.frame then
    bar.frame:SetAlpha(1)
  end
end

function Banner:UpdateBanner(bar, remaining, text, color)
  self:Stop(bar)
  self:SetBackgroundColor(bar, color)
  self:SetDuration(bar, remaining)
  self:Start(bar, text)
end

function Banner:StopBanner(bar)
  self:Stop(bar)
end
