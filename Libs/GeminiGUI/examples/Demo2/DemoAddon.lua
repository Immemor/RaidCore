local DemoAddon = {}

local GeminiGUI


function DemoAddon:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function DemoAddon:Init()
  Apollo.RegisterAddon(self, false, "", {"Gemini:GUI-1.0"})
end

function DemoAddon:OnDependencyError(strDep, strError)
  return false
end

function DemoAddon:OnLoad()
  GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage
  
  self.wndMain = GeminiGUI:Create(self:CreateMainWindow()):GetInstance(self)
  self.wndMain:Show(false)
  self.wndTree = self.wndMain:FindChild("Tree")
  self.wndPanelContainer = self.wndMain:FindChild("PanelContainer")
  self.wndDatachronToggle = self:CreateDatachronToggleWindow()
end

------------------------------------------------------------------------------------------------------------
-- Toggle Button Functions
------------------------------------------------------------------------------------------------------------
function DemoAddon:CreateDatachronToggleWindow()
  -- create a window and position it above the inventory invoke button
  local tWndDef = {
    WidgetType = "PushButton",
    Base = "CRB_CraftingCircuitSprites:btnCircuit_Glass_GreenOrange",
    AnchorPoints = { "InventoryInvoke_Left", "InventoryInvoke_Top", "InventoryInvoke_Left", "InventoryInvoke_Top" }, -- using the edge anchors from the inventory invoke window
    AnchorOffsets = { 5, -45, 55, -5 },
    Pixies = {
      {
        AnchorPoints = "CENTER",
        AnchorOffsets = {-23,-25,27,25},
        Sprite = "ClientSprites:sprItem_NewQuest",
      },
    },
    Events = {
      ButtonSignal = function(self)
        self.wndMain:Show(true)
      end
    },
  }
  return GeminiGUI:Create(tWndDef):GetInstance(self)  
end


------------------------------------------------------------------------------------------------------------
-- Tree Control Functions
------------------------------------------------------------------------------------------------------------
local tTreeNodeHandles = {}
local function PopulateTreeControl(oAddon, wndHandler, wndControl)
  local tData = {
    ["Panel1"] = "P1",
    ["PanelGroup1"] = { ["Panel2"] = "P2", ["Panel3"] = "P3" },
    ["UnknownPanel"] = "qwerty",
  }
  for k,v in pairs(tData) do
    local hParent = 0
    hParent = wndControl:AddNode(hParent, k, nil, v)
    tTreeNodeHandles[v] = hParent
    if type(v) == "table" then
      for k2, v2 in pairs(v) do
        local hNode = wndControl:AddNode(hParent, k2, nil, v2)
        tTreeNodeHandles[v2] = hNode
      end
    end
  end
end

function DemoAddon:OnTreeSelectionChanged(wndHandler, wndControl, hSelected, hOldSelected)
  if hSelected == hOldSelected then return end
  
  -- clear the panel container
  self.wndPanelContainer:DestroyChildren()
  if self.wndCurrentPanel ~= nil and self.wndCurrentPanel:IsValid() then
    self.wndCurrentPanel:Destroy() -- ensure the current panel is destroyed
  end
  
  local strPanelId = wndControl:GetNodeData(hSelected)
  if type(strPanelId) ~= "string" then return end
  
  if strPanelId == "P1" then
    self:ShowPanel(self.CreatePanel1)
  elseif strPanelId == "P2" then
    self:ShowPanel(self.CreatePanel2)
  elseif strPanelId == "P3" then
    self:ShowPanel(self.CreatePanel3)
  else
    self:ShowPanel(self.CreateUnknownPanel)
  end
end

------------------------------------------------------------------------------------------------------------
-- Panel3 Functions
------------------------------------------------------------------------------------------------------------
local karItemQualityColor = {
	[Item.CodeEnumItemQuality.Inferior]  = "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average]   = "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 		 = "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] = "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb]    = "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] = "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]	 = "ItemQuality_Artifact",
}

local function PopulatePanel3Grid(oAddon, wndHandler, wndControl)
  local tGridData = {}
  local unitPlayer = GameLib.GetPlayerUnit()
  for _, itemEquipped in pairs(unitPlayer:GetEquippedItems()) do
    local nQuality = itemEquipped:GetItemQuality() or 1
    local tItem = {
      Icon      = itemEquipped:GetIcon(),
      Name      = itemEquipped:GetName(),
      Type      = itemEquipped:GetItemTypeName(),
      crQuality = karItemQualityColor[nQuality],
      Quality   = nQuality,
    }
    table.insert(tGridData, tItem)
  end
  for idx, tRow in ipairs(tGridData) do
    local iCurrRow =  wndControl:AddRow("")
    wndControl:SetCellData(iCurrRow,  1, tRow.Quality)
    wndControl:SetCellImage(iCurrRow, 1, "WhiteFill")
    wndControl:SetCellImageColor(iCurrRow, 1, tRow.crQuality)
    wndControl:SetCellImage(iCurrRow, 2, tRow.Icon)
    wndControl:SetCellText(iCurrRow,  3, tRow.Name)
    wndControl:SetCellText(iCurrRow,  4, tRow.Type)
  end
end

function DemoAddon:CreatePanel3()
  return {
    AnchorFill = true,
    Sprite = "CRB_Basekit:kitBase_HoloBlue_InsetSimple",
    Children = {
      {
        WidgetType = "Grid",
        AnchorFill = true,
        RowHeight  = 32,
        Columns = {
          { Name = "Qual", Width = 32,  DT_VCENTER = true },
          { Name = "Icon", Width = 32,  DT_VCENTER = true, SimpleSort = false, },
          { Name = "Name", Width = 260, DT_VCENTER = true },
          { Name = "Type", Width = 275, DT_VCENTER = true },
        },
        Events = {
          WindowLoad = PopulatePanel3Grid
        },
      },
    },
  }
end

------------------------------------------------------------------------------------------------------------
-- Panel2 Functions
------------------------------------------------------------------------------------------------------------
local function ShowMessageBox(strMessage)
  local tWndDef = {
    AnchorFill = true,
    Sprite = "BlackFill",
    BGOpacity = 0.8,
    SwallowMouseClicks = true,
    NewWindowDepth = true,
    Overlapped = true,
    
    Children = {
      {
        Name = "MessageContainer",
        AnchorCenter = {400, 160},
        Template = "CRB_NormalFramedThin",
        Border = true,
        UseTemplateBG = true,
        Picture = true,
        Moveable = true,
        Overlapped = true,
        IgnoreMouse = true,
        
        Children = {
          {
            Name = "Message",
            Text = strMessage,
            Anchor = "FILL",
            AnchorOffsets = {10,10,-10,-50},
            Template = "CRB_InnerWindow",
            Border = true,
            UseTemplateBG = true,
            IgnoreMouse = true,
            DT_CENTER = true,
            DT_VCENTER = true,
            DT_WORDBREAK = true,
          },
          {
            WidgetType = "PushButton",
            Base = "CRB_Basekit:kitBtn_List_MetalNoEdge",
            AnchorPoints = {0.5,1,0.5,1},
            AnchorOffsets = {-70,-50,70,-10},
            Text = "Ok",
            Font = "Thick",
            DT_CENTER = true,
            DT_VCENTER = true,
            TextThemeColor = "white",
            
            Events = {
              ButtonSignal = function(self, wndHandler, wndControl)
                local wnd = wndControl:GetParent():GetParent()
                wnd:Destroy()
              end
            },
          },
        },
      },
    },
  }
  GeminiGUI:Create(tWndDef):GetInstance()
end

function DemoAddon:CreatePanel2()
  return {
    AnchorFill = true,
    Sprite = "CRB_Basekit:kitBase_HoloBlue_InsetSimple",
    Children = {
      {
        WidgetType = "PushButton",
        Text = "Ooooo... Click Me!",
        Anchor = "CENTER",
        AnchorOffsets = {-150,40,150,70},
        Events = {
          ButtonSignal = function()
            ShowMessageBox("Hai there! I'm a modal message box.")
          end,
        },
      },
    },
    Pixies = {
      {
        Text       = "Panel 2",
        Font       = "CRB_Pixel",
        TextColor  = "white",
        AnchorPoints = "TOPRIGHT",
        AnchorOffsets = {-100,10,-10,30},
        DT_RIGHT  = true,
      },
    },
  }
end

------------------------------------------------------------------------------------------------------------
-- Panel1 Functions
------------------------------------------------------------------------------------------------------------
function DemoAddon:CreatePanel1()
  return {
    AnchorFill = true,
    Sprite = "CRB_Basekit:kitBase_HoloBlue_InsetSimple",
    Children = {
      {
        WidgetType = "PushButton",
        Text = "Click Me To Go To Panel 3",
        Anchor = "CENTER",
        AnchorOffsets = {-150,40,150,70},
        Events = {
          ButtonSignal = function(self)
            if tTreeNodeHandles["P3"] ~= nil then
              local nOldNode = self.wndTree:GetSelectedNode()
              self.wndTree:SelectNode(tTreeNodeHandles["P3"])
              self:OnTreeSelectionChanged(self.wndTree, self.wndTree, tTreeNodeHandles["P3"], nOldNode)
            end
          end,
        },
      },
    },
    Pixies = {
      {
        Text       = "Look at Panel 3",
        Font       = "CRB_FloaterGigantic_O",
        TextColor  = "white",
        AnchorFill = true,
        DT_VCENTER = true,
        DT_CENTER  = true,
      },
      {
        Text       = "Panel 1",
        Font       = "CRB_Pixel",
        TextColor  = "white",
        AnchorPoints = "TOPRIGHT",
        AnchorOffsets = {-100,10,-10,30},
        DT_RIGHT  = true,
      },
    },
  }
end

------------------------------------------------------------------------------------------------------------
-- UnknownPanel Functions
------------------------------------------------------------------------------------------------------------
function DemoAddon:CreateUnknownPanel()
  return {
    AnchorFill = true,
    Sprite = "WhiteFill",
    BGColor = "xkcdAzure",
    Border = true,
    Pixies = {
      {
        Text       = "Unknown Panel Selected",
        Font       = "CRB_FloaterGigantic_O",
        TextColor  = "white",
        Rotation   = -45,
        AnchorFill = true,
        DT_VCENTER = true,
        DT_CENTER  = true,
      },
      {
        Text       = "Unknown Panel",
        Font       = "CRB_Pixel",
        TextColor  = "white",
        AnchorPoints = "TOPRIGHT",
        AnchorOffsets = {-100,10,-10,30},
        DT_RIGHT  = true,
      },
    },
  }
end

------------------------------------------------------------------------------------------------------------
-- Panel Setup Functions
------------------------------------------------------------------------------------------------------------
function DemoAddon:ShowPanel(fnCreatePanel)
  if type(fnCreatePanel) ~= "function" then
    return
  end
  
  
  -- create the panel definition table
  local tPanelDef = fnCreatePanel(self)
  if tPanelDef ~= nil then
    -- create the panel and add it to the panel container
    self.wndCurrentPanel = GeminiGUI:Create(tPanelDef):GetInstance(self, self.wndPanelContainer)
    self.wndCurrentPanel:Show(true)
  end
end


------------------------------------------------------------------------------------------------------------
-- Main Window Functions
------------------------------------------------------------------------------------------------------------
function DemoAddon:CreateMainWindow()
  local tWndDefinition = {
    Name          = "DemoAddonMainWindow",
    Template      = "CRB_TooltipSimple",
    UseTemplateBG = true,
    Picture       = true,
    Moveable      = true,
    Border        = true,
    AnchorCenter  = {900, 660},
    
    Pixies = {
      {
        Line          = true,
        AnchorPoints  = "HFILL", -- will be translated to {0,0,1,0},
        AnchorOffsets = {0,30,0,30},
        Color         = "white",
      },
      {
        Sprite        = "Collections_TEMP:sprCollections_TEMP_DatacubeOn",
        AnchorPoints  = "BOTTOMRIGHT", -- will be translated to {1,1,1,1},   
        AnchorOffsets = {-220, -110, -25, -10 },
      },
      {
        Text          = "GeminiGUI-1.0 Example Addon",
        Font          = "CRB_HeaderHuge",
        TextColor     = "xkcdYellow",
        AnchorPoints  = "HFILL",
        DT_CENTER     = true,
        DT_VCENTER    = true,
        AnchorOffsets = {0,0,0,20},
      },
    },
    
    Children = {
      {
        WidgetType    = "PushButton",
        AnchorPoints  = "TOPRIGHT",                          -- will be translated to { 1, 0, 1, 0 }
        AnchorOffsets = { -17, -3, 3, 17 },
        Base          = "CRB_Basekit:kitBtn_Holo_Close",
        NoClip        = true,
        Events = { 
          ButtonSignal = function(_, wndHandler, wndControl) -- anonymous function for an event handler
            wndControl:GetParent():Close() 
          end, 
        },
      },
      
      { -- Tree Control
        Name           = "Tree",                             -- Set a name for the widget so we can find it with FindChild() (see OnLoad)
        WidgetType     = "TreeControl",
        AnchorPoints   = {0,0,0,1},                          -- If AnchorPoints is not provided, defaults to "TOPLEFT" or {0,0,0,0}
        AnchorOffsets  = {20,50,220,-20},
        VScroll        = true,
        AutoHideScroll = true,
        Events = {
          WindowLoad = PopulateTreeControl,                  -- Use a local function
          TreeSelectionChanged = "OnTreeSelectionChanged",   -- Use a function on the addon (since addon is the event handler host for this window)
        },
      },
      
      { 
        Name          = "PanelContainer", 
        AnchorPoints  = "FILL",                              -- will be translated to { 0, 0, 1, 1 }
        AnchorOffsets = {230,50,-20,-20},
      },
    },
  }
  
  return tWndDefinition
end

------------------------------------------------------------------------------------------------------------
-- Addon Instantiation
------------------------------------------------------------------------------------------------------------
local DemoAddonInst = DemoAddon:new()
DemoAddonInst:Init()
