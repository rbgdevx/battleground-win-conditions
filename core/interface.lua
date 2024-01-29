local _, NS = ...

local After = C_Timer.After

local Anchor = NS.Anchor
local Banner = NS.Banner
local Score = NS.Score
local Bases = NS.Bases
local Flag = NS.Flag
local Buff = NS.Buff
local Stacks = NS.Stacks

local Interface = {}
NS.Interface = Interface

function Interface:ToggleInfoAlpha()
  Bases:ToggleAlpha()
  Buff:ToggleAlpha()
  Score:ToggleAlpha()
  Flag:ToggleAlpha()
  Stacks:ToggleAlpha()
end

function Interface:Clear()
  Banner:Stop(Banner, Banner.timerAnimationGroup)
  Bases:Stop(Bases.text, Bases.timerAnimationGroup)
  Buff:Stop(Buff.text, Buff.timerAnimationGroup)
  Stacks:Stop(Stacks.text, Stacks.timerAnimationGroup)
  Score.text:SetFormattedText("")
  Score.text:Hide()
  Flag.text:SetFormattedText("")
  Flag.text:Hide()
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

  After(0.5, function()
    Flag:SetAnchor(Bases.frame, 0, -10)
    Flag:SetText(Flag.text, NS.PLAYER_FACTION, NS.PLAYER_FACTION, 20)

    After(0.5, function()
      Buff:SetAnchor(Flag.frame, 0, -10)
      Buff:Start(NS.ORB_BUFF_TIME, NS.formatTeamName(NS.PLAYER_FACTION, NS.PLAYER_FACTION))

      After(0.5, function()
        Stacks:SetAnchor(Buff.frame, 0, -10)
        Stacks:Start(NS.STACK_TIME, 0)
      end)
    end)
  end)
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
