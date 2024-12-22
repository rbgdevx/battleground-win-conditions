local _, NS = ...

local ipairs = ipairs
local mceil = math.ceil

local Anchor = NS.Anchor
local Banner = NS.Banner
local Info = NS.Info
local Score = NS.Score
local Bases = NS.Bases
local Flags = NS.Flags
local Orbs = NS.Orbs
local Stacks = NS.Stacks

local Interface = {}
NS.Interface = Interface

function Interface:ShowBanner()
  if NS.IN_GAME then
    if Banner.text and Banner.text:GetText() ~= nil then
      Banner.frame:SetAlpha(1)
    end
  else
    Banner.frame:SetAlpha(1)
  end
end

function Interface:HideBanner()
  Banner.frame:SetAlpha(0)
end

function Interface:ShowInfo()
  if NS.IN_GAME then
    local children = { Info.frame:GetChildren() }
    local anyChildVisible = false

    for _, child in ipairs(children) do
      if child and child:IsShown() and child:GetAlpha() > 0 then
        anyChildVisible = true
        break
      end
    end

    if anyChildVisible then
      Info.frame:SetAlpha(1)
    end
  else
    Info.frame:SetAlpha(1)
  end
end

function Interface:HideInfo()
  Info.frame:SetAlpha(0)
end

function Interface:Clear()
  Info.frame:SetSize(1, 1)
  Banner:Stop(Banner, Banner.timerAnimationGroup)
  Bases:Stop(Bases, Bases.timerAnimationGroup)
  Orbs:Stop(Orbs, Orbs.timerAnimationGroup, true)
  Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
  Score:Stop(Score)
  Flags:Stop(Flags)
end

function Interface:Start()
  if NS.db and NS.db.global.general.test then
    if NS.db.global.general.banner then
      Interface:CreateTestBanner()
    else
      if NS.db.global.general.info then
        Interface:CreateTestInfo()
      else
        Interface:CreateTestBanner()
        Interface:CreateTestInfo()
      end
    end
  end
end

function Interface:Refresh()
  Anchor:SetAnchor()
  Banner:SetTextColor(Banner.text, NS.db.global.general.bannergroup.tietextcolor)
  Banner:SetBackgroundColor(Banner.bg, NS.db.global.general.bannergroup.tiebgcolor)
  Banner:SetScale(Banner.frame)
  Banner:SetFont(Banner.text)
  Bases:SetFont(Bases.text)
  Orbs:SetFont(Orbs.orbText)
  Orbs:SetFont(Orbs.buffText)
  Flags:SetFont(Flags.text)
  Score:SetFont(Score.text)
  Stacks:SetFont(Stacks.text)

  if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
    NS.UpdateInfoSize(Info.frame, Banner)
  end
end

function Interface:CreateTestBanner()
  Banner:Start(15, "RESET")
end

function Interface:CreateTestInfo()
  Info:SetAnchor(Banner.frame, 0, 0)
  Info:Start()

  Score:SetText(Score.text, 1500, 1125)
  Bases:Start(434, {
    [3] = {
      bases = 3,
      ownScore = 1081,
      winTime = 434 + GetTime(),
      winTicks = mceil(434 / 2),
      ownTime = 224 + GetTime(),
      ownTicks = mceil(224 / 2),
      capTime = 218 + GetTime(),
      capTicks = mceil(218 / 2),
      capScore = 1069,
      minBases = 3,
      maxBases = 5,
      winName = NS.PLAYER_FACTION,
      loseName = NS.PLAYER_FACTION == NS.ALLIANCE_NAME and NS.HORDE_NAME or NS.ALLIANCE_NAME,
      loseBases = 2,
      tickRate = 2,
    },
    [4] = {
      bases = 4,
      ownScore = 1377,
      winTime = 434 + GetTime(),
      winTicks = mceil(434 / 2),
      ownTime = 372 + GetTime(),
      ownTicks = mceil(372 / 2),
      capTime = 366 + GetTime(),
      capTicks = mceil(366 / 2),
      capScore = 1365,
      minBases = 2,
      maxBases = 5,
      winName = NS.PLAYER_FACTION,
      loseName = NS.PLAYER_FACTION == NS.ALLIANCE_NAME and NS.HORDE_NAME or NS.ALLIANCE_NAME,
      loseBases = 2,
      tickRate = 2,
    },
    [5] = {
      bases = 5,
      ownScore = 1497,
      winTime = 434 + GetTime(),
      winTicks = mceil(434 / 2),
      ownTime = 432 + GetTime(),
      ownTicks = mceil(432 / 2),
      capTime = 426 + GetTime(),
      capTicks = mceil(426 / 2),
      capScore = 1485,
      minBases = 1,
      maxBases = 5,
      winName = NS.PLAYER_FACTION,
      loseName = NS.PLAYER_FACTION == NS.ALLIANCE_NAME and NS.HORDE_NAME or NS.ALLIANCE_NAME,
      loseBases = 2,
      tickRate = 2,
    },
  })

  Flags:SetAnchor(Bases.frame, 0, -5)
  Flags:SetText(Flags.text, NS.PLAYER_FACTION, NS.PLAYER_FACTION, 20)

  if NS.db.global.maps.eyeofthestorm.showflaginfo == false then
    Orbs:SetAnchor(Bases.frame, 0, -10)
  else
    Orbs:SetAnchor(Flags.frame, 0, -10)
  end
  Orbs:StartOrbList()
  Orbs:Start(NS.DEFAULT_ORB_BUFF_TIME, NS.formatTeamName(NS.PLAYER_FACTION, NS.PLAYER_FACTION))

  if
    NS.db.global.maps.templeofkotmogu.showorbinfo == false
    and NS.db.global.maps.templeofkotmogu.showbuffinfo == false
  then
    if NS.db.global.maps.eyeofthestorm.showflaginfo == false then
      Stacks:SetAnchor(Bases.frame, 0, -10)
    else
      Stacks:SetAnchor(Flags.frame, 0, -10)
    end
  else
    Stacks:SetAnchor(Orbs.frame, 0, -10)
  end
  Stacks:Start(NS.DEFAULT_STACK_TIME, 0)

  if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
    NS.UpdateInfoSize(Info.frame, Banner)
  end
end

function Interface:Create()
  Anchor:Create()
  if Anchor.frame then
    Banner:Create(Anchor.frame)
  end
  if Banner.frame then
    if NS.db.global.general.info == false then
      Info:Create(Banner.frame)
    else
      Info:Create(Anchor.frame)
    end
  end
  if Info.frame then
    Score:Create(Info.frame)
  end
  if Score.frame then
    Bases:Create(Score.frame)
  end
  if Bases.frame then
    Flags:Create(Bases.frame)
  end
  if Flags.frame then
    if NS.db.global.maps.eyeofthestorm.showflaginfo == false then
      Orbs:Create(Bases.frame)
    else
      Orbs:Create(Flags.frame)
    end
  end
  if Orbs.frame then
    if
      NS.db.global.maps.templeofkotmogu.showorbinfo == false
      and NS.db.global.maps.templeofkotmogu.showbuffinfo == false
    then
      Stacks:Create(Flags.frame)
    else
      Stacks:Create(Orbs.frame)
    end
  end
end
