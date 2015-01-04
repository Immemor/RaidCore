local DemoAddon = {}
function DemoAddon:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function DemoAddon:Init()
  Apollo.RegisterAddon(self, false, "", {"Gemini:GUI-1.0"})
end

function DemoAddon:OnLoad()
  Apollo.RegisterSlashCommand("guidemo", "OnDemo", self)
  Apollo.RegisterSlashCommand("guidemo2", "OnDemo2", self)
  Apollo.RegisterSlashCommand("guidemo3", "OnDemo3", self)
  self.GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage
end

function DemoAddon:OnDependencyError(strDep, strError)
  return false
end

function DemoAddon:OnDemo()
  local tWndDefinition = {
    Name          = "GeminiGUIDemoWindow",
    Template      = "CRB_TooltipSimple",
    UseTemplateBG = true,
    Picture       = true,
    Moveable      = true,
    Border        = true,
    AnchorCenter  = {500, 460},
    Escapable     = true,
    
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
        Text          = "GeminiGUI-1.0 Sample",
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
        AnchorPoints  = "TOPRIGHT", -- will be translated to { 1, 0, 1, 0 }
        AnchorOffsets = { -17, -3, 3, 17 },
        Base          = "CRB_Basekit:kitBtn_Holo_Close",
        NoClip        = true,
        Events = { ButtonSignal = function(_, wndHandler, wndControl) wndControl:GetParent():Close() end, },
      },
      
      { 
        Name          = "DemoWidgetContainer", 
        AnchorPoints  = "FILL", -- will be translated to { 0, 0, 1, 1 }
        AnchorOffsets = {0,40,0,0},
        Children = {
          
          { -- CheckBox
            WidgetType    = "CheckBox",
            Text          = "CheckBox",
            AnchorOffsets = {20,0,220,30},
          },
          
          { -- PushButton
            WidgetType    = "PushButton",
            Text          = "Push Me!",
            AnchorOffsets = {20,40,220,70},
            Events = { ButtonSignal = function() Print("Oh baby! Do it again!@!") end },
          },
          
          { -- Buzzer
            WidgetType      = "Buzzer",
            Text            = "Buzzzzz!",
            BuzzerFrequency = 5,
            AnchorOffsets   = {20,80,220,110},
            Events = { ButtonSignal = function() Print("Harder!") end },
          },
          
          { -- Text Edit
            WidgetType    = "EditBox",
            Text          = "Edit Me!",
            AnchorOffsets = {20, 120, 220, 160},
          },
          
          { -- Grid
            WidgetType    = "Grid",
            AnchorOffsets = {20, 170, 220, 380 },
            Columns = {
              { Name = "Col1", Width = 58 },
              { Name = "Col2", Width = 58, DT_RIGHT  = true, },
              { Name = "Col3", Width = 58, TextColor = "red" },
            },
            Events = {
              WindowLoad = function(self, wndHandler, wndControl)
                -- populate the grid
                local nTotalRows = 10
                local tGridData = {}
                for i = 1, nTotalRows do
                  tGridData[i] = {}
                  for j = 1,3 do 
                    tGridData[i][j] = string.format("R%dC%d", i, j)
                  end
                end
                
                for idx, tRow in ipairs(tGridData) do
                  local iCurrRow =  wndControl:AddRow("")
                  for cIdx, strCol in ipairs(tRow) do
                    wndControl:SetCellText(iCurrRow, cIdx, strCol)
                  end
                end
              end
            },
          },
          
          { -- Progress Bar
            Name          = "GeminiGUIDemoProgressBar",
            WidgetType    = "ProgressBar",
            AnchorPoints  = "TOPRIGHT",
            AnchorOffsets = {-220,0,-20,30},
            Events = {
              WindowLoad = function(self, wndHandler, wndControl)
                wndControl:SetMax(100)
                wndControl:SetProgress(55)
              end
            },
          },
          
          { -- Slider
            WidgetType    = "SliderBar",
            AnchorPoints  = "TOPRIGHT",
            AnchorOffsets = {-220,40,-20,60},
            InitialValue  = 50,
            Events = {
              SliderBarChanged = function(self, wndHandler,wndControl, fValue)
                if wndHandler ~= wndControl then return end
                wndControl:GetParent():FindChild("GeminiGUIDemoProgressBar"):SetProgress(fValue)
              end
            },
          },
          
          { -- Tree Control
            WidgetType    = "TreeControl",
            AnchorPoints  = "TOPRIGHT",
            AnchorOffsets = {-220,70,-20,240},
            VScroll       = true,
            Events = {
              WindowLoad = function(self, wndHandler, wndControl)
                local tData = {
                  ["Node1"] = { ["Node2"] = true, ["AnotherNode1"] = true },
                  ["Node3"] = { ["Node4"] = true, ["AnotherNode2"] = true, ["AnotherNode3"] = true },
                  ["Node5"] = { ["Node6"] = true, ["AnotherNode4"] = true },
                  ["Node7"] = { ["Node8"] = true, ["AnotherNode5"] = true },
                }
                for k,v in pairs(tData) do
                  local hParent = 0
                  hParent = wndControl:AddNode(hParent, k)
                  if type(v) == "table" then
                    for k2 in pairs(v) do
                      wndControl:AddNode(hParent, k2)
                    end
                  end
                end
              end
            },
          },
          
          { -- Combo Box
            WidgetType    = "ComboBox",
            AnchorPoints  = "TOPRIGHT",
            AnchorOffsets = {-220, 250, -20, 290},
            Events = {
              WindowLoad = function(self, wndHandler, wndControl)
                if wndHandler ~= wndControl then return end
                
                wndControl:AddItem("Combobreaker!", nil, 0)
                wndControl:AddItem("Item 1", nil, 1)
                wndControl:AddItem("Item 2", nil, 2)
                wndControl:AddItem("Item 3", nil, 3)
                wndControl:GetGrid():SetSortColumn(1, false) -- sort items descending ;)
                wndControl:SelectItemByData(0)
              end
            },
          },
          
        },
      },
    },
  }
  
  
  local tWnd = self.GeminiGUI:Create(tWndDefinition)
  local wnd = tWnd:GetInstance()
end

function DemoAddon:OnDemo2()
  -- default addon window
  local oEventHandler = {
    OnOK = function(self)
      self.wnd:Show(false)
    end,
    
    OnCancel = function(self)
      self.wnd:Show(false)
    end
  }
  
  
  local tWnd = {
    Name               = "DemoAddonForm",
    Moveable           = true,
    Escapable          = true,
    Overlapped         = true,
    AnchorCenter       = {595,795},
    Template           = "CRB_NormalFramedThick_StandardHdrFtr",
    SwallowMouseClicks = true,
    
    Children = {
      {
        Name            = "Title",
        TextId          = "CRB_Title",
        AnchorPoints    = { 0, 0, 1, 0 },
        AnchorOffsets   = { 31, 18, -14, 47 },
        TextColor       = "ffc0c0c0",
        Font            = "CRB_InterfaceMedium",
        IgnoreMouse     = true,
        DT_CENTER       = true,
        DT_VCENTER      = true,
        NewControlDepth = 2,
      },
      
      {
        WidgetType            = "PushButton",
        Name                  = "CancelButton",
        TextId                = "CRB_Cancel",
        Base                  = "CRB_UIKitSprites:btn_square_LARGE_Red",
        WindowSoundTemplate   = "TogglePhys03",
        AnchorPoints          = { 1, 1, 1, 1 },
        AnchorOffsets         = { -146, -73, -26, -32 },
        DT_CENTER             = true,
        DT_VCENTER            = true,
        NewControlDepth       = 2,
        TextThemeColor        = "ffffffff", -- sets normal, flyby, pressed, pressedflyby, disabled to a color
        Events = {
          ButtonSignal = "OnCancel"
        },
      },
        
      {
        WidgetType            = "PushButton",
        Name                  = "OkButton",
        TextId                = "CRB_Ok",
        Base                  = "CRB_UIKitSprites:btn_square_LARGE_Green",
        WindowSoundTemplate   = "TogglePhys02",
        AnchorPoints          = { 1, 1, 1, 1 },
        AnchorOffsets         = { -268, -73, -148, -32 },
        DT_CENTER             = true,
        DT_VCENTER            = true,
        NewControlDepth       = 2,
        TextThemeColor        = "ffffffff", -- sets normal, flyby, pressed, pressedflyby, disabled to a color
        Events = {
          ButtonSignal = "OnOK"
        },
      },
      
      {
        WidgetType            = "PushButton",
        Name                  = "CloseButton",
        Base                  = "CRB_UIKitSprites:btn_close",
        WindowSoundTemplate   = "CloseWindowPhys",
        AnchorPoints          = { 1, 0, 1, 0 },
        AnchorOffsets         = { -29, 5, 3, 39 },
        DT_CENTER             = true,
        DT_VCENTER            = true,
        NewControlDepth       = 2,
        TextThemeColor        = "ffffffff", -- sets normal, flyby, pressed, pressedflyby, disabled to a color
        Events = {
          ButtonSignal = "OnCancel"
        },
      },
    },
  }
  
  oEventHandler.wnd = self.GeminiGUI:Create(tWnd):GetInstance(oEventHandler)
end

function DemoAddon:OnDemo3()
  -- set parent for button to another window
  local tWnd1 = {
    Template      = "CRB_TooltipSimple",
    UseTemplateBG = true,
    Picture       = true,
    Border        = true,
    AnchorCenter  = { 500, 300 },
  }
  local wndOne = self.GeminiGUI:Create(tWnd1):GetInstance()
  
  -- doesn't have to be a button, can be any widget
  local tBtnToAttach = {
    WidgetType     = "PushButton",
    Base           = "CRB_UIKitSprites:btn_square_LARGE_Red",
    Text           = "Close Parent",
    TextThemeColor = "ffffffff", -- sets normal, flyby, pressed, pressedflyby, disabled to a color
    AnchorCenter   = { 150, 40 },
    Events = {
      ButtonSignal = function(self, wndHandler, wndControl)
        wndControl:GetParent():Close()
      end
    },
  }
  self.GeminiGUI:Create(tBtnToAttach):GetInstance(nil, wndOne) -- first parameter is the event handler table. second parameter is the window to use as a parent (this is passed directly to Apollo.LoadForm's parent argument)
end


local DemoAddonInst = DemoAddon:new()
DemoAddonInst:Init()
