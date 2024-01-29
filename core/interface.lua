local _, NS = ...

local Anchor = NS.Anchor
local Banner = NS.Banner
local Score = NS.Score
local Bases = NS.Bases
local Flag = NS.Flag
local Buff = NS.Buff
local Stacks = NS.Stacks

local Interface = {}
NS.Interface = Interface

function Interface:ShowBanner()
  Banner.frame:SetAlpha(1)
  Banner.bg:SetAlpha(1)
  Banner.text:SetAlpha(1)
end

function Interface:HideBanner()
  Banner.frame:SetAlpha(0)
  Banner.bg:SetAlpha(0)
  Banner.text:SetAlpha(0)
end

function Interface:ShowInfo()
  Bases.frame:SetAlpha(1)
  Bases.text:SetAlpha(1)
  Buff.frame:SetAlpha(1)
  Buff.text:SetAlpha(1)
  Score.frame:SetAlpha(1)
  Score.text:SetAlpha(1)
  Flag.frame:SetAlpha(1)
  Flag.text:SetAlpha(1)
  Stacks.frame:SetAlpha(1)
  Stacks.text:SetAlpha(1)
end

function Interface:HideInfo()
  Bases.frame:SetAlpha(0)
  Bases.text:SetAlpha(0)
  Buff.frame:SetAlpha(0)
  Buff.text:SetAlpha(0)
  Score.frame:SetAlpha(0)
  Score.text:SetAlpha(0)
  Flag.frame:SetAlpha(0)
  Flag.text:SetAlpha(0)
  Stacks.frame:SetAlpha(0)
  Stacks.text:SetAlpha(0)
end

function Interface:Clear()
  Banner:Stop(Banner, Banner.timerAnimationGroup)
  Bases:Stop(Bases.text, Bases.timerAnimationGroup)
  Buff:Stop(Buff.text, Buff.timerAnimationGroup)
  Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
  Score.text:SetFormattedText("")
  Score.text:SetAlpha(0)
  Flag.text:SetFormattedText("")
  Flag.text:SetAlpha(0)
end

function Interface:Refresh()
  Banner:SetTextColor(Banner.text, NS.db.global.general.bannergroup.tietextcolor)
  Banner:SetBackgroundColor(Banner.bg, NS.db.global.general.bannergroup.tiebgcolor)
  Banner:SetScale(Banner.frame)
  Banner:SetFont(Banner.text)
  Bases:SetFont(Bases.text)
  Buff:SetFont(Buff.text)
  Flag:SetFont(Flag.text)
  Score:SetFont(Score.text)
  Stacks:SetFont(Stacks.text)
  Anchor:SetAnchor()
end

function Interface:CreateTestBanner()
  Banner:Start(1500, "TIE")
end

function Interface:CreateTestInfo()
  if NS.db.global.general.info then
    Score:SetAnchor(Anchor.frame, 0, 0)
  else
    Score:SetAnchor(Banner.frame, 0, -5)
  end

  Score:SetText(Score.text, 1500, 1500)
  Bases:Start(1500, {
    [4] = {
      bases = 4,
      ownScore = 1299,
      ownTime = 800 + GetTime(),
      capTime = 800 - NS.ASSAULT_TIME + GetTime(),
      capScore = 1299 - NS.ASSAULT_TIME * 2,
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
      capScore = 1499 - NS.ASSAULT_TIME * 2,
      minBases = 1,
      maxBases = 5,
      winName = NS.PLAYER_FACTION,
      loseName = NS.PLAYER_FACTION == NS.ALLIANCE_NAME and NS.HORDE_NAME or NS.ALLIANCE_NAME,
    },
  })

  Flag:SetAnchor(Bases.frame, 0, -10)
  Flag:SetText(Flag.text, NS.PLAYER_FACTION, NS.PLAYER_FACTION, 20)

  Buff:SetAnchor(Flag.frame, 0, -10)
  Buff:Start(NS.ORB_BUFF_TIME, NS.formatTeamName(NS.PLAYER_FACTION, NS.PLAYER_FACTION))

  Stacks:SetAnchor(Buff.frame, 0, -10)
  Stacks:Start(NS.STACK_TIME, 0)
end

function Interface:Create()
  Anchor:Create()
  if Anchor.frame then
    Banner:Create(Anchor.frame)
  end
  if Banner.frame then
    Score:Create(Banner.frame)
  end
  if Score.frame then
    Bases:Create(Score.frame)
  end
  if Bases.frame then
    Flag:Create(Bases.frame)
  end
  if Flag.frame then
    Buff:Create(Flag.frame)
  end
  if Buff.frame then
    Stacks:Create(Buff.frame)
  end
end
