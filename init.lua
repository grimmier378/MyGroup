--[[
    Title: MyGroup
    Author: Grimmier
    Description: Stupid Simple Group Window
]]
---@type Mq
local mq = require('mq')
---@type ImGui
local ImGui = require('ImGui')
local Icons = require('mq.ICONS')
local COLOR = require('colors.colors')
local gIcon = Icons.MD_SETTINGS

-- set variables
local animSpell = mq.FindTextureAnimation('A_SpellIcons')
local animItem = mq.FindTextureAnimation('A_DragItem')
local TLO = mq.TLO
local winFlag = bit32.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.MenuBar)
local textureWidth = 26
local textureHeight = 26
local mimic = false
local followMe = false
local ShowGUI, openGUI, openConfigGUI = true, true, false
local ver = "v0.22"
local theme = {}
local ZoomLvl = 1
local themeFile = mq.configDir .. '/MyThemeZ.lua'
local configFile = mq.configDir .. '/MyUI_Configs.lua'
local ColorCount, ColorCountConf, StyleCount, StyleCountConf = 0, 0, 0, 0
local tPlayerFlags = bit32.bor(ImGuiTableFlags.NoBorders, ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.NoPadInnerX,
ImGuiTableFlags.NoPadOuterX, ImGuiTableFlags.Resizable, ImGuiTableFlags.SizingFixedFit)

local manaClass = {
    [1] = 'WIZ',
    [2] = 'MAG',
    [3] = 'NEC',
    [4] = 'ENC',
    [5] = 'DRU',
    [6] = 'SHM',
    [7] = 'CLR',
    [8] = 'BST',
    [9] = 'BRD',
    [10] = 'PAL',
    [12] = 'RNG',
    [13] = 'SHD',
}

local lastTar = mq.TLO.Target.ID() or 0
local themeName = 'Default'
local locked, showMana, showEnd, showPet = false, true, true, true
local script = 'MyGroup'
local defaults, settings, temp = {}, {}, {}
local useEQBC = false
defaults = {
    [script] = {
        Scale = 1.0,
        LoadTheme = 'Default',
        locked = false,
        UseEQBC = false,
        ShowMana = true,
        ShowEnd = true,
        ShowPet = true,
    },
}
---comment Check to see if the file we want to work on exists.
---@param name string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
local function File_Exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

local function loadTheme()
    if File_Exists(themeFile) then
        theme = dofile(themeFile)
        else
        theme = require('themes')
    end
    themeName = theme.LoadTheme or 'notheme'
end

---comment Writes settings from the settings table passed to the setting file (full path required)
-- Uses mq.pickle to serialize the table and write to file
---@param file string -- File Name and path
---@param settings table -- Table of settings to write
local function writeSettings(file, settings)
    mq.pickle(file, settings)
end

local function loadSettings()
    if not File_Exists(configFile) then
        mq.pickle(configFile, defaults)
        loadSettings()
        else
        
        -- Load settings from the Lua config file
        temp = {}
        settings = dofile(configFile)
        temp = settings[script]
    end
    
    loadTheme()
    
    if settings[script].locked == nil then
        settings[script].locked = false
    end
    
    if settings[script].Scale == nil then
        settings[script].Scale = 1
    end
    
    if settings[script].LoadTheme == nil then
        settings[script].LoadTheme = themeName
    end
    
    if settings[script].UseEQBC == nil then
        settings[script].UseEQBC = useEQBC
    end
    
    if settings[script].ShowMana == nil then
        settings[script].ShowMana = showMana
    end
    
    if settings[script].ShowEnd == nil then
        settings[script].ShowEnd = showEnd
    end
    
    if settings[script].ShowPet == nil then
        settings[script].ShowPet = showPet
    end
    
    showPet = settings[script].ShowPet
    showEnd = settings[script].ShowEnd
    showMana = settings[script].ShowMana
    useEQBC = settings[script].UseEQBC
    locked = settings[script].locked
    ZoomLvl = settings[script].Scale
    themeName = settings[script].LoadTheme
    
    writeSettings(configFile, settings)
    
    temp = settings[script]
end

---comment
---@param themeName string -- name of the theme to load form table
---@return integer, integer -- returns the new counter values 
local function DrawTheme(themeName)
    local StyleCounter = 0
    local ColorCounter = 0
    for tID, tData in pairs(theme.Theme) do
        if tData.Name == themeName then
            for pID, cData in pairs(theme.Theme[tID].Color) do
                ImGui.PushStyleColor(pID, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], cData.Color[4]))
                ColorCounter = ColorCounter + 1
            end
            if tData['Style'] ~= nil then
                if next(tData['Style']) ~= nil then
                    
                    for sID, sData in pairs (theme.Theme[tID].Style) do
                        if sData.Size ~= nil then
                            ImGui.PushStyleVar(sID, sData.Size)
                            StyleCounter = StyleCounter + 1
                            elseif sData.X ~= nil then
                            ImGui.PushStyleVar(sID, sData.X, sData.Y)
                            StyleCounter = StyleCounter + 1
                        end
                    end
                end
            end
        end
    end
    return ColorCounter, StyleCounter
end

---@param type string
---@param txt string
local function DrawStatusIcon(iconID, type, txt)
    animSpell:SetTextureCell(iconID or 0)
    animItem:SetTextureCell(iconID or 3996)
    
    if type == 'item' then
        ImGui.DrawTextureAnimation(animItem, textureWidth - 11, textureHeight - 11)
        elseif type == 'pwcs' then
        local animPWCS = mq.FindTextureAnimation(iconID)
        animPWCS:SetTextureCell(iconID)
        ImGui.DrawTextureAnimation(animPWCS, textureWidth - 11, textureHeight - 11)
        else
        ImGui.DrawTextureAnimation(animSpell, textureWidth - 11, textureHeight - 11)
    end
    
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(txt)
        ImGui.EndTooltip()
    end
end

local function DrawGroupMember(id)
    local member = mq.TLO.Group.Member(id)
    local memberName = member.Name()
    function GetInfoToolTip()
        if not member.OtherZone() then
            
            local pInfoToolTip = (member.Name() ..
                '\t\tlvl: ' .. tostring(member.Level()) ..
                '\nClass: ' .. member.Class.Name() ..
                '\nHealth: ' .. tostring(member.CurrentHPs()) .. ' of ' .. tostring(member.MaxHPs()) ..
                '\nMana: ' .. tostring(member.CurrentMana()) .. ' of ' .. tostring(member.MaxMana()) ..
                '\nEnd: ' .. tostring(member.CurrentEndurance()) .. ' of ' .. tostring(member.MaxEndurance())
            )
            return pInfoToolTip
            
        end
    end
    
    ImGui.BeginGroup()
    
    if ImGui.BeginTable("##playerInfo", 4, tPlayerFlags) then
        
        ImGui.TableSetupColumn("##tName", ImGuiTableColumnFlags.NoResize, (ImGui.GetContentRegionAvail() * .5))
        ImGui.TableSetupColumn("##tVis", ImGuiTableColumnFlags.NoResize, 16)
        ImGui.TableSetupColumn("##tIcons", ImGuiTableColumnFlags.WidthStretch, 80) --ImGui.GetContentRegionAvail()*.25)
        ImGui.TableSetupColumn("##tLvl", ImGuiTableColumnFlags.NoResize, 30)
        ImGui.TableNextRow()
        -- Name
        ImGui.SetWindowFontScale(ZoomLvl)
        ImGui.TableSetColumnIndex(0)
        
        -- local memberName = member.Name()
        
        ImGui.SetWindowFontScale(ZoomLvl * 0.8)
        ImGui.Text( 'F'..tostring(id+1))
        ImGui.SetWindowFontScale(ZoomLvl)
        ImGui.SameLine()
        
        ImGui.Text(memberName)
        
        -- Visiblity
        
        ImGui.TableSetColumnIndex(1)
        
        ImGui.SetWindowFontScale(ZoomLvl * 0.75)
        if member.LineOfSight() then
            ImGui.PushStyleColor(ImGuiCol.Text, 0, 1, 0, .5)
            ImGui.Text(Icons.MD_VISIBILITY)
            
            else
            ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0, 0, .5)
            ImGui.Text(Icons.MD_VISIBILITY_OFF)
        end
        ImGui.PopStyleColor()
        
        ImGui.SetWindowFontScale(ZoomLvl * 0.91)
        
        -- Icons
        
        ImGui.TableSetColumnIndex(2)
        
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 0, 0)
        ImGui.Text('')
        
        if TLO.Group.MainTank.ID() == member.ID() then
            ImGui.SameLine()
            DrawStatusIcon('A_Tank','pwcs','Main Tank')
        end
        
        if TLO.Group.MainAssist.ID() == member.ID() then
            ImGui.SameLine()
            DrawStatusIcon('A_Assist','pwcs','Main Assist')
        end
        
        if TLO.Group.Puller.ID() == member.ID() then
            ImGui.SameLine()
            DrawStatusIcon('A_Puller','pwcs','Puller')
        end
        
        ImGui.SameLine()
        
        --  ImGui.SameLine()
        ImGui.Text(' ')
        
        ImGui.SameLine()
        
        ImGui.SetWindowFontScale(ZoomLvl * 0.75)
        local dist = member.Distance() or 9999
        local dis = '9999'
        
        if dis then dis = tostring(math.floor(dist)) end
        
        if dist > 200 then
            ImGui.PushStyleColor(ImGuiCol.Text,COLOR.color('red'))
            else
            ImGui.PushStyleColor(ImGuiCol.Text,COLOR.color('green'))
        end
        
        ImGui.Text(dis)
        ImGui.PopStyleColor()
        ImGui.PopStyleVar()
        -- Lvl
        ImGui.TableSetColumnIndex(3)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 0)
        ImGui.SetWindowFontScale(ZoomLvl * 1)
        ImGui.Text(tostring(member.Level() or 0))
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            if not member.OtherZone() then
                ImGui.Text(GetInfoToolTip())
                else
                ImGui.Text('Not in Zone!')
            end
            ImGui.EndTooltip()
        end
        
        ImGui.PopStyleVar()
        ImGui.EndTable()
    end
    ImGui.Separator()
    
    -- Health Bar
    
    ImGui.SetWindowFontScale(ZoomLvl * 0.75)
    if not member.OtherZone() then
        
        if member.PctHPs() <= 0  or member.PctHPs() == nil then
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('purple')))
            elseif member.PctHPs() < 15 then
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('pink')))
            else
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('red')))
        end
        
        ImGui.ProgressBar(((tonumber(member.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * ZoomLvl, '##pctHps'..id)
        ImGui.PopStyleColor()
        
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text(member.DisplayName())
            ImGui.Text(member.PctHPs()..'% Health')
            ImGui.EndTooltip()
        end
        
        --My Mana Bar
        if showMana then
            for i, v in pairs(manaClass) do
                if string.find(member.Class.ShortName(), v) then
                    ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('light blue2')))
                    ImGui.ProgressBar(((tonumber(member.PctMana() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * ZoomLvl, '##pctMana'..id)
                    ImGui.PopStyleColor()
                    
                    if ImGui.IsItemHovered() then
                        ImGui.BeginTooltip()
                        ImGui.Text(member.DisplayName())
                        ImGui.Text(member.PctMana()..'% Mana')
                        ImGui.EndTooltip()
                    end
                end
            end
        end
        if showEnd then
            --My Endurance bar
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('yellow2')))
            ImGui.ProgressBar(((tonumber(member.PctEndurance() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * ZoomLvl, '##pctEndurance'..id)
            ImGui.PopStyleColor()
            
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text(member.DisplayName())
                ImGui.Text(member.PctEndurance()..'% Endurance')
                ImGui.EndTooltip()
            end
        end

            -- Pet Health

        if showPet then
            ImGui.BeginGroup()            
            if member.Pet() ~= 'NO PET' then
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('green2')))
                ImGui.ProgressBar(((tonumber(member.Pet.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 4 * ZoomLvl, '##PetHp'..id)
                ImGui.PopStyleColor()
                if ImGui.IsItemHovered() then
                    ImGui.BeginTooltip()
                    ImGui.Text(member.Pet.DisplayName())
                    ImGui.Text(member.Pet.PctHPs()..'% health')
                    ImGui.EndTooltip()
                    if ImGui.IsMouseClicked(0) then
                        mq.cmdf("/target id %s", member.Pet.ID())
                        if mq.TLO.Cursor() then
                            mq.cmdf('/multiline ; /tar id %s; /face; /if (${Cursor.ID}) /click left target',member.Pet.ID())
                        end
                    end
                end
            end
            ImGui.EndGroup()
        end
        ImGui.Separator()
        else
        ImGui.Dummy(ImGui.GetContentRegionAvail(), 20)
        
    end
    ImGui.EndGroup()
    if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Left) then
        mq.cmdf("/target id %s", member.ID())
        if mq.TLO.Cursor() then
            mq.cmdf('/multiline ; /tar id %s; /face; /if (${Cursor.ID}) /click left target',member.ID())
        end
    end
    if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Right) then
        if useEQBC then
            mq.cmdf("/bct %s //foreground", memberName)
            else
            mq.cmdf("/dex %s /foreground", memberName)
        end
    end
end

local function GUI_Group(open)
    ColorCount = 0
    StyleCount = 0
    if not ShowGUI then return end
    
    if TLO.Me.Zoning() then return end
    local flags = winFlag
    if locked then
        flags = bit32.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.MenuBar)
    end
    -- Default window size
    ImGui.SetNextWindowSize(216, 239, ImGuiCond.FirstUseEver)
    local show = false
    ColorCount, StyleCount = DrawTheme(themeName)
    open, show = ImGui.Begin("My Group##MyGroup"..mq.TLO.Me.DisplayName(), open, flags)
    
    if not show then
        if StyleCount > 0 then ImGui.PopStyleVar(StyleCount) end
        if ColorCount > 0 then ImGui.PopStyleColor(ColorCount) end
        ImGui.SetWindowFontScale(1)
        ImGui.End()
        return open
    end
    ImGui.SetWindowFontScale(1)
    ImGui.BeginGroup()
    if ImGui.BeginMenuBar() then
        local lockedIcon = locked and Icons.FA_LOCK .. '##lockTabButton_MyChat' or
        Icons.FA_UNLOCK .. '##lockTablButton_MyChat'
        if ImGui.Button(lockedIcon) then
            --ImGuiWindowFlags.NoMove
            locked = not locked
            settings = dofile(configFile)
            settings[script].locked = locked
            writeSettings(configFile, settings)
        end
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text("Lock Window")
            ImGui.EndTooltip()
        end
        if ImGui.Button(gIcon..'##PlayerTarg') then
            openConfigGUI = not openConfigGUI
        end
        ImGui.EndMenuBar()
    end
    local member = nil
    
    -- Player Information
    
    if mq.TLO.Me.GroupSize() > 0 then
        
        for i = 1, mq.TLO.Me.GroupSize() -1 do
            member = mq.TLO.Group.Member(i)
            ImGui.BeginGroup()
            DrawGroupMember(i)
            ImGui.EndGroup()
            ImGui.SetWindowFontScale(ZoomLvl)
        end
        
    end
    
    ImGui.SeparatorText('Commands')
    
    local invited = mq.TLO.Me.Invited() or false
    local lbl = 'Invite'
    
    if invited then
        lbl = 'Follow'
    end
    
    if ImGui.Button(lbl) then
        mq.cmdf("/invite %s", mq.TLO.Target.Name())
    end
    
    if mq.TLO.Me.GroupSize() > 0 then
        ImGui.SameLine()
    end
    
    if mq.TLO.Me.GroupSize() > 0 then
        
        if ImGui.Button('Disband') then
            mq.cmdf("/disband")
        end
        
    end
    
    ImGui.Separator()
    
    local meID = mq.TLO.Me.ID()
    
    if ImGui.Button('Come\nTo Me') then
        if useEQBC then
            mq.cmdf("/bcaa //nav spawn id %s", meID)
            else
            mq.cmdf("/dgge /nav spawn id %s", meID)
        end
    end
    
    ImGui.SameLine()
    
    
    local tmpFollow = followMe
    if followMe then ImGui.PushStyleColor(ImGuiCol.Button, COLOR.color('pink')) end
    if ImGui.Button('Follow\n\tMe') then
        if not followMe then
            if useEQBC then
                mq.cmdf("/multiline ; /dcaa //nav stop; /dcaa //afollow spawn %s", meID)
                else
                mq.cmdf("/multiline ; /dgge /nav stop; /dgge /afollow spawn %s", meID)
            end
            else
            if useEQBC then
                mq.cmd("/bcaa //nav stop")
                else
                mq.cmd("/dgge /nav stop")
            end
        end
        tmpFollow = not tmpFollow
    end
    if followMe then ImGui.PopStyleColor(1) end
    followMe = tmpFollow
    
    ImGui.SameLine()
    local tmpMimic = mimic
    if mimic then ImGui.PushStyleColor(ImGuiCol.Button, COLOR.color('pink')) end
    if ImGui.Button('Mimic\n   Me') then
        if mimic then
            mq.cmd("/groupinfo mimicme off")
            else
            mq.cmd("/groupinfo mimicme on")
        end
        tmpMimic = not tmpMimic
    end
    if mimic then ImGui.PopStyleColor(1) end
    mimic = tmpMimic
    ImGui.EndGroup()
    if ImGui.IsItemHovered() then
        ImGui.SetWindowFocus("My Group##MyGroup"..mq.TLO.Me.DisplayName())
    end

    if StyleCount > 0 then ImGui.PopStyleVar(StyleCount) end
    ImGui.Spacing()
    if ColorCount > 0 then ImGui.PopStyleColor(ColorCount) end

    ImGui.SetWindowFontScale(1)
    ImGui.End()

    return open
end


local function MyGroupConf_GUI(open)
    if not openConfigGUI then return end
    ColorCountConf = 0
    StyleCountConf = 0
    ColorCountConf, StyleCountConf = DrawTheme(themeName)
    open, openConfigGUI = ImGui.Begin("MyGroup Conf", open, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.AlwaysAutoResize))
    if not openConfigGUI then
        openConfigGUI = false
        open = false
        if StyleCountConf > 0 then ImGui.PopStyleVar(StyleCountConf) end
        if ColorCountConf > 0 then ImGui.PopStyleColor(ColorCountConf) end
        ImGui.SetWindowFontScale(1)
        ImGui.End()
        return open
    end
    
    ImGui.SeparatorText("Theme##"..script)
    ImGui.Text("Cur Theme: %s", themeName)
    -- Combo Box Load Theme
    if ImGui.BeginCombo("Load Theme##MyGroup", themeName) then
        ImGui.SetWindowFontScale(ZoomLvl)
        for k, data in pairs(theme.Theme) do
            local isSelected = data.Name == themeName
            if ImGui.Selectable(data.Name, isSelected) then
                theme.LoadTheme = data.Name
                themeName = theme.LoadTheme
                settings[script].LoadTheme = themeName
                -- useThemeName = themeName
            end
        end
        ImGui.EndCombo()
        
    end

    if ImGui.Button('Reload Theme File') then
        loadTheme()
    end

    ImGui.SeparatorText("Scaling##"..script)
    -- Slider for adjusting zoom level
    local tmpZoom = ZoomLvl
    if ZoomLvl then
        tmpZoom = ImGui.SliderFloat("Zoom Level##MyGroup", tmpZoom, 0.5, 2.0)
    end
    if ZoomLvl ~= tmpZoom then
        ZoomLvl = tmpZoom
        settings[script].Scale = ZoomLvl
    end
    ImGui.SeparatorText("Toggles##"..script)
    local tmpComms = useEQBC
    tmpComms = ImGui.Checkbox('Use EQBC##'..script, tmpComms)
    if tmpComms ~= useEQBC then
        useEQBC = tmpComms
    end
    
    local tmpMana = showMana
    tmpMana = ImGui.Checkbox('Mana##'..script, tmpMana)
    if tmpMana ~= showMana then
        showMana = tmpMana
    end
    
    ImGui.SameLine()
    
    local tmpEnd = showEnd
    tmpEnd = ImGui.Checkbox('Endurance##'..script, tmpEnd)
    if tmpEnd ~= showEnd then
        showEnd = tmpEnd
    end
    
    ImGui.SameLine()
    
    local tmpPet = showPet
    tmpPet = ImGui.Checkbox('Show Pet##'..script, tmpPet)
    if tmpPet ~= showPet then
        showPet = tmpPet
    end
    ImGui.SeparatorText("Save and Close##"..script)
    if ImGui.Button('Save and Close##'..script) then
        openConfigGUI = false
        settings = dofile(configFile)
        settings[script].ShowMana = showMana
        settings[script].ShowEnd = showEnd
        settings[script].ShowPet = showPet
        settings[script].UseEQBC = useEQBC
        settings[script].Scale = ZoomLvl
        settings[script].LoadTheme = themeName
        settings[script].locked = locked
        writeSettings(configFile,settings)
    end
    
    if StyleCountConf > 0 then ImGui.PopStyleVar(StyleCountConf) end
    if ColorCountConf > 0 then ImGui.PopStyleColor(ColorCountConf) end
    ImGui.SetWindowFontScale(1)
    ImGui.End()
    
end

local function init()
    loadSettings()
    mq.imgui.init('GUI_MyGroup', GUI_Group)
    mq.imgui.init('GUI_ConfMyGroup', MyGroupConf_GUI)
end

local function MainLoop()
    
    while true do
        if TLO.Window('CharacterListWnd').Open() then return false end
        
        mq.delay(1)
        
        if mq.TLO.Me.Zoning() then
            ShowGUI = false
            mimic = false
            followMe = false
            else
            ShowGUI = true
        end
        
        if not openGUI then
            openGUI = ShowGUI
            GUI_Group(openGUI)
        end
        
        if mimic and lastTar ~= mq.TLO.Target.ID() then
            lastTar = mq.TLO.Target.ID()
            mq.cmdf("/dgge /target id %s", mq.TLO.Target.ID())
        end
        
    end
end

init()
printf("\ag %s \aw[\ayMy Group\aw] ::\a-t Version \aw::\ay %s \at Loaded",TLO.Time(), ver)
MainLoop()
