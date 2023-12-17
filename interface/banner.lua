local _, NS = ...

local Banner = {}
NS.Banner = Banner
NS.barCache = NS.barCache or {}

local barPrototype_meta = NS.barPrototype_mt
local barCache = NS.barCache

local next = next
local GetTime = GetTime
local CreateFrame = CreateFrame
local setmetatable = setmetatable

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
    local frame = CreateFrame("Frame", nil, UIParent)
    bar = setmetatable(frame, barPrototype_meta)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bar.bg = bg

    bar.label = label

    local text = bar:CreateFontString(nil, "ARTWORK")
    text:SetPoint("CENTER", bg, "CENTER", 0, 0)
    bar.text = text

    local updater = bar:CreateAnimationGroup()
    updater:SetLooping("REPEAT")
    updater.parent = bar

    local anim = updater:CreateAnimation()
    anim:SetDuration(0.04)

    bar.updater = updater
    bar.repeater = anim
  else
    barCache[bar] = nil
  end

  bar:SetFrameStrata("MEDIUM")
  bar:SetFrameLevel(100)
  bar:ClearAllPoints()
  bar:SetWidth(width)
  bar:SetHeight(height)
  bar:SetMovable(false)
  bar:SetScale(1)
  bar:SetAlpha(1)
  bar:SetClampedToScreen(false)
  bar:EnableMouse(false)

  return bar
end

local function stopBar(bar)
  bar.updater:Stop()
  bar.data = nil
  bar.funcs = nil
  bar.running = nil
  bar.paused = nil
  bar:Hide()
  bar:SetParent(UIParent)
  barCache[bar] = true
end

function Banner:Stop(bar)
  stopBar(bar)
  barCache[bar] = true
end

local bannerformat = "GG YOU %s IN %s"

local function barUpdate(updater)
  local bar = updater.parent
  local t = GetTime()
  if t >= bar.exp then
    bar.updater:Stop()
    bar.running = nil
    bar.paused = nil
    -- bar:Hide()
    -- bar:SetParent(UIParent)
  else
    local time = bar.exp - t
    bar.remaining = time
    bar.text:SetFormattedText(bannerformat, bar.winName, NS.formatTime(time))
  end
end

function Banner:Start(bar, text)
  bar.running = true
  local time = bar.remaining
  bar.gap = 0
  bar.start = GetTime()
  bar.exp = bar.start + time
  bar.winName = text

  bar.text:SetFormattedText(bannerformat, bar.winName, NS.formatTime(time))

  bar.updater:SetScript("OnLoop", barUpdate)
  bar.updater:Play()
  bar:Show()
end

function Banner:UpdateBar(bar, remaining, text, color)
  self:Stop(bar)
  self:SetBackgroundColor(bar, color)
  self:SetDuration(bar, remaining)
  self:Start(bar, text)
end

function Banner:StopBar(bar)
  self:Stop(bar)
end
