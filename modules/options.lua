local _, NS = ...

local Interface = NS.Interface
local InterfaceFrame = NS.InterfaceFrame
local Options = {}
NS.Options = Options

local INTERFACE_CLEARED = false

local next = next
local CreateFrame = CreateFrame

function Options:InitDB()
  BGWCDB = BGWCDB and next(BGWCDB) ~= nil and BGWCDB or {}

  -- Copy any settings from default if they don't exist in current profile
  NS.CopyDefaults(NS.DEFAULT_SETTINGS, BGWCDB)

  -- Reference to active db profile
  -- Always use this directly or reference will be invalid
  NS.db = BGWCDB
  NS.db.version = NS.DEFAULT_SETTINGS.version

  -- Remove table values no longer found in default settings
  NS.CleanupDB(BGWCDB, NS.DEFAULT_SETTINGS)
end

local function updateBanner(value)
  if InterfaceFrame.frame then
    if value then
      Interface:HideWinInfo()
    else
      if INTERFACE_CLEARED then
        if NS.db.test then
          Interface:CreateTestInfo()
          INTERFACE_CLEARED = false
        end
      else
        Interface:ShowWinInfo()
      end
    end
  end
end

local function updateTestInfo(value)
  if InterfaceFrame.frame then
    if value then
      if NS.IN_GAME == false then
        if NS.db.banner then
          Interface:CreateTestBannerInfo()
        else
          Interface:CreateTestInfo()
        end
      end
    else
      if NS.IN_GAME == false then
        INTERFACE_CLEARED = true
        Interface:ClearInterface()
      end
    end
  end
end

local function updateControls(value)
  if InterfaceFrame.frame then
    if value then
      Interface:Lock()
    else
      Interface:Unlock()
    end
  end
end

function Options:CreateCheckbox(option, label, parent, updateFunc)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")

  cb.Text:SetText(label)

  local function UpdateOption(value)
    NS.db[option] = value
    cb:SetChecked(value)

    if updateFunc then
      updateFunc(value)
    end
  end

  UpdateOption(NS.db[option])

  cb:HookScript("OnClick", function()
    UpdateOption(cb:GetChecked())
  end)

  EventRegistry:RegisterCallback("Options.OnReset", function()
    UpdateOption(NS.DEFAULT_SETTINGS[option])
  end, cb)

  return cb
end

function Options:InitializeOptions()
  local panel_main = {}
  panel_main.frame = CreateFrame("Frame", "BGWCOptionsFrame")

  panel_main.frame.name = NS.OPTIONS_LABEL

  local cb_title = panel_main.frame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
  cb_title:SetPoint("TOPLEFT", 10, -15)
  cb_title:SetText(NS.OPTIONS_LABEL)

  local cb_lock = self:CreateCheckbox("lock", "Lock the position", panel_main.frame, updateControls)
  cb_lock:SetPoint("TOPLEFT", cb_title, 0, -30)

  local cb_test = self:CreateCheckbox("test", "Show placeholder info", panel_main.frame, updateTestInfo)
  cb_test:SetPoint("TOPLEFT", cb_lock, 0, -30)

  local cb_banner = self:CreateCheckbox("banner", "Show banner only", panel_main.frame, updateBanner)
  cb_banner:SetPoint("TOPLEFT", cb_test, 0, -30)

  local btn_reset = CreateFrame("Button", nil, panel_main.frame, "UIPanelButtonTemplate")
  btn_reset:SetPoint("TOPLEFT", cb_banner, 0, -40)
  btn_reset:SetText(RESET)
  btn_reset:SetWidth(100)
  btn_reset:SetScript("OnClick", function()
    EventRegistry:TriggerEvent("Options.OnReset")
  end)

  InterfaceOptions_AddCategory(panel_main.frame)

  local function SlashHandler(message)
    if message == "toggle lock" then
      if NS.db["lock"] == false then
        NS.db["lock"] = true
        cb_lock:SetChecked(true)
        updateControls(true)
      else
        NS.db["lock"] = false
        cb_lock:SetChecked(false)
        updateControls(false)
      end
    elseif message == "toggle placeholder" then
      if NS.db["test"] == false then
        NS.db["test"] = true
        cb_test:SetChecked(true)
        updateTestInfo(true)
      else
        NS.db["test"] = false
        cb_test:SetChecked(false)
        updateTestInfo(false)
      end
    elseif message == "toggle banner" then
      if NS.db["banner"] == false then
        NS.db["banner"] = true
        cb_banner:SetChecked(true)
        updateBanner(true)
      else
        NS.db["banner"] = false
        cb_banner:SetChecked(false)
        updateBanner(false)
      end
    else
      InterfaceOptionsFrame_OpenToCategory(NS.OPTIONS_LABEL)
    end
  end

  SLASH_BGWC1 = "/bgwc"
  SlashCmdList.BGWC = SlashHandler
end
