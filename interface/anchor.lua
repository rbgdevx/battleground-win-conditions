local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub

local Anchor = {}
NS.Anchor = Anchor

local AnchorFrame = CreateFrame("Frame", AddonName .. "AnchorFrame", UIParent)
Anchor.frame = AnchorFrame

function Anchor:SetAnchor()
  AnchorFrame:SetPoint(
    NS.db.global.position[1],
    UIParent,
    NS.db.global.position[2],
    NS.db.global.position[3],
    NS.db.global.position[4]
  )
end

function Anchor:StopMovement()
  AnchorFrame:SetMovable(false)
end

function Anchor:StopHover()
  AnchorFrame:SetScript("OnEnter", function(f)
    f:SetAlpha(1)
  end)
  AnchorFrame:SetScript("OnLeave", function(f)
    f:SetAlpha(1)
  end)
end

function Anchor:MakeHoverable()
  AnchorFrame:SetScript("OnEnter", function(f)
    f:SetAlpha(1)
  end)
  AnchorFrame:SetScript("OnLeave", function(f)
    f:SetAlpha(0)
  end)
end

function Anchor:MakeMoveable()
  AnchorFrame:SetMovable(true)
  AnchorFrame:RegisterForDrag("LeftButton")
  AnchorFrame:SetScript("OnDragStart", function(f)
    if NS.db.global.general.lock == false then
      f:StartMoving()
    end
  end)
  AnchorFrame:SetScript("OnDragStop", function(f)
    if NS.db.global.general.lock == false then
      f:StopMovingOrSizing()
      local a, _, b, c, d = f:GetPoint()
      NS.db.global.position[1] = a
      NS.db.global.position[2] = b
      NS.db.global.position[3] = c
      NS.db.global.position[4] = d
    end
  end)
end

function Anchor:ToggleShow(show)
  if show then
    AnchorFrame:Show()
  else
    AnchorFrame:Hide()
  end
end

function Anchor:Lock()
  self:StopMovement()
  self:ToggleShow(false)
end

function Anchor:Unlock()
  self:MakeMoveable()
  self:ToggleShow(true)
end

function Anchor:AddControls()
  AnchorFrame:EnableMouse(true)
  AnchorFrame:SetScript("OnMouseUp", function(_, btn)
    if btn == "RightButton" then
      LibStub("AceConfigDialog-3.0"):Open(AddonName)
    end
  end)

  if NS.db.global.general.lock then
    self:StopMovement()
    self:ToggleShow(false)
  else
    self:MakeMoveable()
    self:ToggleShow(true)
  end
end

function Anchor:Create()
  if not Anchor.header then
    local bg = AnchorFrame:CreateTexture()
    bg:SetAllPoints(AnchorFrame)
    bg:SetColorTexture(0, 1, 0, 0.2)

    local header = AnchorFrame:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE")
    header:SetAllPoints(AnchorFrame)
    header:SetFormattedText("anchor")
    header:SetJustifyH("CENTER")
    header:SetJustifyV("MIDDLE")
    header:SetPoint("CENTER", bg, "CENTER", 0, 0)

    Anchor:SetAnchor()
    AnchorFrame:SetWidth(175)
    AnchorFrame:SetHeight(15)
    AnchorFrame:SetClampedToScreen(true)

    self:AddControls()

    Anchor.header = header
  end
end
