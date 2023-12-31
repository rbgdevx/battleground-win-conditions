local _, NS = ...

local Interface = {}
NS.Interface = Interface

local GetTime = GetTime
local CreateFrame = CreateFrame

local sformat = string.format

local InterfaceFrame = {}
InterfaceFrame.frame = CreateFrame("Frame", "BGWCInterfaceFrame", UIParent)
NS.InterfaceFrame = InterfaceFrame

-- IMPORTANT: don't use this more than once
-- I removed support for creating multiple
function Interface:CreateBanner(label, width, height)
  local banner = NS.Banner:Create(label, width, height)

  banner.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "NORMAL")
  banner.text:SetTextColor(1, 1, 1, 1)
  banner.text:SetShadowOffset(0, 0)
  banner.text:SetShadowColor(0, 0, 0, 1)
  banner.text:SetJustifyH("MIDDLE")
  banner.text:SetJustifyV("MIDDLE")

  banner.frame:SetParent(InterfaceFrame.frame)
  banner.frame:SetPoint("TOPLEFT", InterfaceFrame.frame, "BOTTOMLEFT", 0, 0)

  return banner
end

function Interface:CreateInfo(label, anchor)
  local info = NS.WinInfo:Create(label, anchor)

  info.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE")
  info.text:SetTextColor(1, 1, 1, 1)
  info.text:SetShadowOffset(0, 0)
  info.text:SetShadowColor(0, 0, 0, 1)
  info.text:SetJustifyH("LEFT")
  info.text:SetJustifyV("TOP")

  info.frame:SetParent(InterfaceFrame.frame)
  info.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)

  return info
end

function Interface:CreateBuff(label, anchor)
  local buff = NS.OrbBuffTimer:Create(label, anchor)

  buff.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE")
  buff.text:SetTextColor(1, 1, 1, 1)
  buff.text:SetShadowOffset(0, 0)
  buff.text:SetShadowColor(0, 0, 0, 1)
  buff.text:SetJustifyH("LEFT")
  buff.text:SetJustifyV("TOP")

  buff.frame:SetParent(InterfaceFrame.frame)
  buff.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)

  return buff
end

function Interface:UpdateBanner(bar, remaining, text, color)
  NS.Banner:UpdateBanner(bar, remaining, text, color)
end

function Interface:UpdateInfo(bar, winTime, winCondition)
  NS.WinInfo:UpdateInfo(bar, winTime, winCondition)
end

function Interface:UpdateBuff(bar, time, winTeam)
  NS.OrbBuffTimer:UpdateBuff(bar, time, winTeam)
end

function Interface:StopBanner(bar)
  NS.Banner:StopBanner(bar)
end

function Interface:StopInfo(bar)
  NS.WinInfo:StopInfo(bar)
end

function Interface:StopBuff(bar)
  NS.OrbBuffTimer:StopBuff(bar)
end

function Interface:HideInfo(bar)
  NS.WinInfo:HideInfo(bar)
end

function Interface:HideBuff(bar)
  NS.OrbBuffTimer:HideBuff(bar)
end

function Interface:ShowInfo(bar)
  NS.WinInfo:ShowInfo(bar)
end

function Interface:ShowBuff(bar)
  NS.OrbBuffTimer:ShowBuff(bar)
end

function Interface:UpdateText(bar, txt)
  bar:SetText(txt)
end

function Interface:Hide(bar)
  bar:SetAlpha(0)
end

function Interface:Show(bar)
  bar:SetAlpha(1)
end

function Interface:ClearAllText()
  self:UpdateText(InterfaceFrame.score, "")
  self:UpdateText(InterfaceFrame.flag, "")
end

function Interface:HideAllText()
  self:Hide(InterfaceFrame.score)
  self:Hide(InterfaceFrame.flag)
end

function Interface:ShowAllText()
  self:Show(InterfaceFrame.score)
  self:Show(InterfaceFrame.flag)
end

function Interface:ClearWinInfo()
  self:StopInfo(InterfaceFrame.info)
  self:StopBuff(InterfaceFrame.buff)
  self:ClearAllText()
end

function Interface:HideWinInfo()
  self:HideInfo(InterfaceFrame.info)
  if NS.IN_GAME == false then
    self:HideInfo(InterfaceFrame.buff)
  end
  self:HideAllText()
end

function Interface:ClearInterface()
  self:StopBanner(InterfaceFrame.banner)
  self:ClearWinInfo()
end

function Interface:ShowWinInfo()
  if NS.IS_TEMPLE == false then
    self:ShowInfo(InterfaceFrame.info)
  end
  if NS.IN_GAME == false then
    self:ShowInfo(InterfaceFrame.buff)
  end
  self:ShowAllText()
end

function Interface:UpdateFinalScore(bar, aScore, hScore)
  local finalAScore = NS.formatScore(NS.ALLIANCE_NAME, aScore)
  local finalHScore = NS.formatScore(NS.HORDE_NAME, hScore)
  local txt = sformat("Final Score: %s - %s", finalAScore, finalHScore)
  self:UpdateText(bar, txt)
end

function Interface:UpdateFlagValue(bar, value)
  local txt = sformat("Flag Value: %s", value)
  self:UpdateText(bar, txt)
end

function Interface:StopMovement()
  InterfaceFrame.frame:SetMovable(false)
end

function Interface:StopHover()
  InterfaceFrame.frame:SetScript("OnEnter", function(f)
    f:SetAlpha(1)
  end)
  InterfaceFrame.frame:SetScript("OnLeave", function(f)
    f:SetAlpha(1)
  end)
end

function Interface:MakeHoverable()
  InterfaceFrame.frame:SetScript("OnEnter", function(f)
    f:SetAlpha(1)
  end)
  InterfaceFrame.frame:SetScript("OnLeave", function(f)
    f:SetAlpha(0)
  end)
end

function Interface:MakeMoveable()
  InterfaceFrame.frame:SetMovable(true)
  InterfaceFrame.frame:RegisterForDrag("LeftButton")
  InterfaceFrame.frame:SetScript("OnDragStart", function(f)
    f:StartMoving()
  end)
  InterfaceFrame.frame:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing()
    local a, _, b, c, d = f:GetPoint()
    NS.db.position[1] = a
    NS.db.position[2] = b
    NS.db.position[3] = c
    NS.db.position[4] = d
  end)
end

function Interface:ToggleShow(show)
  if show then
    InterfaceFrame.frame:Show()
  else
    InterfaceFrame.frame:Hide()
  end
end

function Interface:Lock()
  self:StopMovement()
  self:ToggleShow(false)
end

function Interface:Unlock()
  self:MakeMoveable()
  self:ToggleShow(true)
end

function Interface:AddControls()
  InterfaceFrame.frame:SetPoint(NS.db.position[1], UIParent, NS.db.position[2], NS.db.position[3], NS.db.position[4])
  InterfaceFrame.frame:SetWidth(175)
  InterfaceFrame.frame:SetHeight(15)
  InterfaceFrame.frame:SetClampedToScreen(true)
  InterfaceFrame.frame:EnableMouse(true)
  InterfaceFrame.frame:SetScript("OnMouseUp", function(_, btn)
    if btn == "RightButton" then
      InterfaceOptionsFrame_OpenToCategory(NS.OPTIONS_LABEL)
    end
  end)

  if NS.db.lock then
    self:StopMovement()
    self:ToggleShow(false)
  else
    self:MakeMoveable()
    self:ToggleShow(true)
  end
end

function Interface:InitializeInterface()
  self:AddControls()

  local bg = InterfaceFrame.frame:CreateTexture()
  bg:SetAllPoints(InterfaceFrame.frame)
  bg:SetColorTexture(0, 1, 0, 0.3)
  InterfaceFrame.bg = bg

  local header = InterfaceFrame.frame:CreateFontString(nil, "OVERLAY")
  header:SetFont("Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE")
  header:SetAllPoints(InterfaceFrame.frame)
  header:SetText("anchor")
  InterfaceFrame.header = header

  local GGBar = self:CreateBanner("GG BANNER", 175, 25)
  InterfaceFrame.banner = GGBar

  local GGScoreFrame = CreateFrame("Frame", "BGWCScoreFrame", UIParent)
  local GGScore = GGScoreFrame:CreateFontString(nil, "OVERLAY")
  GGScore:SetFont("Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE")
  GGScore:SetTextColor(1, 1, 1, 1)
  GGScore:SetShadowOffset(0, 0)
  GGScore:SetShadowColor(0, 0, 0, 1)
  GGScore:SetJustifyH("LEFT")
  GGScore:SetJustifyV("TOP")
  GGScore:SetPoint("TOPLEFT", InterfaceFrame.banner.frame, "BOTTOMLEFT", 0, -10)
  InterfaceFrame.score = GGScore

  local GGInfo = self:CreateInfo("GG INFO", InterfaceFrame.score)
  InterfaceFrame.info = GGInfo

  local GGFlagFrame = CreateFrame("Frame", "BGWCFlagFrame", UIParent)
  local GGFlag = GGFlagFrame:CreateFontString(nil, "ARTWORK")
  GGFlag:SetFont("Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE")
  GGFlag:SetTextColor(1, 1, 1, 1)
  GGFlag:SetShadowOffset(0, 0)
  GGFlag:SetShadowColor(0, 0, 0, 1)
  GGFlag:SetJustifyH("LEFT")
  GGFlag:SetJustifyV("TOP")
  GGFlag:SetPoint("TOPLEFT", InterfaceFrame.info.text, "BOTTOMLEFT", 0, 0)
  InterfaceFrame.flag = GGFlag

  local GGBuff = self:CreateBuff("GG BUFF", InterfaceFrame.flag)
  InterfaceFrame.buff = GGBuff
end

function Interface:CreateTestBannerInfo()
  self:UpdateBanner(InterfaceFrame.banner, 1500, "WIN", { r = 0, g = 0, b = 0 })
end

function Interface:CreateTestWinInfo()
  self:UpdateFinalScore(
    InterfaceFrame.score,
    NS.PLAYER_FACTION == NS.ALLIANCE_NAME and 1500 or 800,
    NS.PLAYER_FACTION == NS.ALLIANCE_NAME and 800 or 1500
  )
  self:UpdateInfo(InterfaceFrame.info, 1500, {
    [4] = {
      bases = 4,
      ownScore = 1299,
      ownTime = 800 + GetTime(),
      capTime = 800 - NS.ASSAULT_TIME + GetTime(),
      capScore = 1299 - (NS.ASSAULT_TIME * 2),
      minBases = 2,
      maxBases = 5,
      winName = NS.PLAYER_FACTION,
      loseName = NS.PLAYER_FACTION == NS.ALLIANCE_NAME and NS.HORDE_NAME or NS.ALLIANCE_NAME,
    },
    [5] = {
      bases = 5,
      ownScore = 1499,
      ownTime = 400 + GetTime(),
      capTime = 400 - NS.ASSAULT_TIME + GetTime(),
      capScore = 1499 - (NS.ASSAULT_TIME * 2),
      minBases = 1,
      maxBases = 5,
      winName = NS.PLAYER_FACTION,
      loseName = NS.PLAYER_FACTION == NS.ALLIANCE_NAME and NS.HORDE_NAME or NS.ALLIANCE_NAME,
    },
  })
  self:UpdateBuff(InterfaceFrame.buff, NS.ORB_BUFF_TIME, NS.formatTeamName(NS.PLAYER_FACTION, NS.PLAYER_FACTION))
  self:UpdateFlagValue(InterfaceFrame.flag, NS.formatScore(NS.PLAYER_FACTION, 85))
  self:ShowWinInfo()
end

function Interface:CreateTestInfo()
  self:CreateTestBannerInfo()
  self:CreateTestWinInfo()
end
