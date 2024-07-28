--[[
    Title: MyGroup
    Author: Grimmier
    Description: Stupid Simple Group Window
]]

local mq = require('mq')
local ImGui = require('ImGui')
local Icons = require('mq.ICONS')
local COLOR = require('colors.colors')
local gIcon = Icons.MD_SETTINGS
-- set variables
local animSpell = mq.FindTextureAnimation('A_SpellIcons')
local animItem = mq.FindTextureAnimation('A_DragItem')
local TLO = mq.TLO
local winFlag = bit32.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.MenuBar)
local iconWidth, iconHeight = 26, 26
local mimicMe, followMe = false, false
local ShowGUI, openConfigGUI = true, false
local Scale = 1
local themeFile = mq.configDir .. '/MyThemeZ.lua'
local configFileOld = mq.configDir .. '/MyUI_Configs.lua'
local configFileold2 = ''
local configFile = ''
local ColorCount, ColorCountConf, StyleCount, StyleCountConf = 0, 0, 0, 0
local lastTar = TLO.Target.ID() or 0
local themeName = 'Default'
local locked, showMana, showEnd, showPet, mouseHover = false, true, true, true, false
local script = 'MyGroup'
local defaults, settings, theme = {}, {}, {}
local useEQBC = false
local myName = TLO.Me.Name()
local meID = TLO.Me.ID()
local serverName = ''
local hideTitle, showSelf = false, false
local currZone, lastZone

-- Flags
local tPlayerFlags = bit32.bor(ImGuiTableFlags.NoBorders, ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.NoPadInnerX,
ImGuiTableFlags.NoPadOuterX, ImGuiTableFlags.Resizable, ImGuiTableFlags.SizingFixedFit)

-- Tables
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
    [11] = 'RNG',
    [12] = 'SHD',
}

defaults = {
    [script] = {
        Scale = 1.0,
        LoadTheme = 'Default',
        locked = false,
        UseEQBC = false,
        WinTransparency = 1.0,
        MouseOver = false,
        ShowSelf = false,
        ShowMana = true,
        ShowEnd = true,
        ShowDummy = true,
        ShowPet = true,
        DynamicHP = false,
        DynamicMP = false,
        HideTitleBar = false,
    },
}

---comment Check to see if the file we want to work on exists.
---@param fileName string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
local function File_Exists(fileName)
    local f=io.open(fileName,"r")
    if f~=nil then io.close(f) return true else return false end
end

local function loadTheme()
    if File_Exists(themeFile) then
        theme = dofile(themeFile)
        else
        theme = require('themes')
    end
    themeName = theme.LoadTheme or themeName
end

---comment Writes settings from the settings table passed to the setting file (full path required)
-- Uses mq.pickle to serialize the table and write to file
---@param file string -- File Name and path
---@param table table -- Table of settings to write
local function writeSettings(file, table)
    mq.pickle(file, table)
end

local function loadSettings()
    local newSetting = false
    if not File_Exists(configFile) then
        --check for old file and convert to new format
        if File_Exists(configFileold2) then
            settings = dofile(configFileold2)
            writeSettings(configFile, settings)
        else
            if File_Exists(configFileOld) then
                settings = dofile(configFileOld)
                writeSettings(configFile, settings)
                else
                settings = defaults
                writeSettings(configFile, settings)
            end
        end
    else
        -- Load settings from the Lua config file
        settings = dofile(configFile)
        if settings[script] == nil then
            settings[script] = {}
        settings[script] = defaults 
        newSetting = true
        end

    end

    loadTheme()

    for k, v in pairs(defaults[script]) do
        if settings[script][k] == nil then
            settings[script][k] = v
            newSetting = true
        end
    end

    showSelf = settings[script].ShowSelf
    hideTitle = settings[script].HideTitleBar
    showPet = settings[script].ShowPet
    showEnd = settings[script].ShowEnd
    showMana = settings[script].ShowMana
    useEQBC = settings[script].UseEQBC
    locked = settings[script].locked
    Scale = settings[script].Scale
    themeName = settings[script].LoadTheme

    if newSetting then writeSettings(configFile, settings) end

end

---comment
---@param tName string -- name of the theme to load form table
---@return integer, integer -- returns the new counter values 
local function DrawTheme(tName)
    local StyleCounter = 0
    local ColorCounter = 0
    for tID, tData in pairs(theme.Theme) do
        if tData.Name == tName then
            for pID, cData in pairs(theme.Theme[tID].Color) do
                if cData.PropertyName == 'WindowBg' then
                    if not settings[script].MouseOver then
                        ImGui.PushStyleColor(ImGuiCol.WindowBg, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], settings[script].WinTransparency))
                        ColorCounter = ColorCounter + 1
                    elseif settings[script].MouseOver and mouseHover then
                        ImGui.PushStyleColor(ImGuiCol.WindowBg, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], 1.0))
                        ColorCounter = ColorCounter + 1
                    elseif settings[script].MouseOver and not mouseHover then
                        ImGui.PushStyleColor(ImGuiCol.WindowBg, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], settings[script].WinTransparency))
                        ColorCounter = ColorCounter + 1
                    end
                else
                    ImGui.PushStyleColor(pID, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], cData.Color[4]))
                    ColorCounter = ColorCounter + 1
                end
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

local function giveItem(id, name)
    if not TLO.Cursor() then mq.cmdf("/target id %s", id) return end
    local iconID = TLO.Cursor.Icon() or 0
    if ImGui.IsMouseReleased(ImGuiMouseButton.Left)  then
        mq.cmdf("/target id %s", id)
        if TLO.Cursor() then
            mq.cmdf('/multiline ; /tar id %s; /face; /if (${Cursor.ID}) /click left target',id)
        end
    elseif ImGui.IsMouseReleased(ImGuiMouseButton.Right) and ImGui.IsKeyDown(ImGuiMod.Ctrl) then
        if useEQBC then
            mq.cmdf("/bct %s //foreground", name)
            else
            mq.cmdf("/dex %s /foreground", name)
        end
    end
end

---@param type string
---@param txt string
local function DrawStatusIcon(iconID, type, txt)
    animSpell:SetTextureCell(iconID or 0)
    animItem:SetTextureCell(iconID or 3996)

    if type == 'item' then
        ImGui.DrawTextureAnimation(animItem, iconWidth - 11, iconHeight - 11)
        elseif type == 'pwcs' then
        local animPWCS = mq.FindTextureAnimation(iconID)
        animPWCS:SetTextureCell(iconID)
        ImGui.DrawTextureAnimation(animPWCS, iconWidth - 11, iconHeight - 11)
        else
        ImGui.DrawTextureAnimation(animSpell, iconWidth - 11, iconHeight - 11)
    end

    if ImGui.IsItemHovered() then
        ImGui.SetTooltip(txt)
    end
end

local function DrawGroupMember(id)

    local member = TLO.Group.Member(id)
    local memberName = member.Name()
    local r,g,b,a = 1,1,1,1
    if member == 'NULL' then return end

    function GetInfoToolTip()
        if member.Present() then
            local pInfoToolTip = (member.Name() ..
                '\t\tlvl: ' .. tostring(member.Level()) ..
                '\nClass: ' .. member.Class.Name() ..
                '\nHealth: ' .. tostring(member.CurrentHPs()) .. ' of ' .. tostring(member.MaxHPs()) ..
                '\nMana: ' .. tostring(member.CurrentMana()) .. ' of ' .. tostring(member.MaxMana()) ..
                '\nEnd: ' .. tostring(member.CurrentEndurance()) .. ' of ' .. tostring(member.MaxEndurance()) ..
                '\nSitting: ' .. tostring(member.Sitting())
            )
            return pInfoToolTip
        end
    end

    ImGui.BeginGroup()

    if ImGui.BeginTable("##playerInfo" .. tostring(id), 4, tPlayerFlags) then

        ImGui.TableSetupColumn("##tName", ImGuiTableColumnFlags.NoResize, (ImGui.GetContentRegionAvail() * .5))
        ImGui.TableSetupColumn("##tVis", ImGuiTableColumnFlags.NoResize, 16)
        ImGui.TableSetupColumn("##tIcons", ImGuiTableColumnFlags.WidthStretch, 80) --ImGui.GetContentRegionAvail()*.25)
        ImGui.TableSetupColumn("##tLvl", ImGuiTableColumnFlags.NoResize, 30)
        ImGui.TableNextRow()
        -- Name
        ImGui.TableSetColumnIndex(0)

        if TLO.Group.Leader.ID() == member.ID() then
            ImGui.TextColored(0,1,1,1,'F%d',id+1 )
            ImGui.SameLine()
            ImGui.TextColored(0,1,1,1,memberName)
        else
            ImGui.Text( 'F%d',id+1)
            ImGui.SameLine()
            ImGui.Text(memberName)
        end

        -- Visiblity

        ImGui.TableSetColumnIndex(1)
        if member.LineOfSight() then
            ImGui.TextColored( 0, 1, 0, .5,Icons.MD_VISIBILITY)
            else
            ImGui.TextColored(0.9, 0, 0, .5,Icons.MD_VISIBILITY_OFF)
        end

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
        ImGui.Text(' ')
        ImGui.SameLine()

        local dist = member.Distance() or 9999

        if dist > 200 then
            ImGui.TextColored(COLOR.color('red'),"%d",math.floor(dist))
            else
            ImGui.TextColored(COLOR.color('green'),"%d",math.floor(dist))
        end

        ImGui.PopStyleVar()
        -- Lvl
        ImGui.TableSetColumnIndex(3)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 0)
        if member.Sitting() then
            ImGui.TextColored(0.911, 0.351, 0.008, 1,"%d",member.Level() or 0)
        else
            ImGui.Text("%s",member.Level() or 0)
        end
        if ImGui.IsItemHovered() then
            if member.Present() then
                ImGui.SetTooltip(GetInfoToolTip())
            else
                ImGui.SetTooltip('Not in Zone!')
            end
        end
        ImGui.PopStyleVar()
        ImGui.EndTable()
    end

    if ImGui.BeginPopupContextItem("##groupContext" .. tostring(id)) then -- Context menu for the group Roles
        
        if ImGui.Selectable('Switch To') then
            if useEQBC then
                mq.cmdf("/bct %s //foreground", memberName)
                else
                mq.cmdf("/dex %s /foreground", memberName)
            end
        end
        if ImGui.Selectable('Come to Me') then
            if useEQBC then
                mq.cmdf("/bct %s //nav spawn %s", memberName,myName)
                else
                mq.cmdf("/dex %s /nav spawn %s", memberName,myName)
            end
        end
        if ImGui.Selectable('Go To '..memberName) then
            mq.cmdf("/nav spawn %s", memberName)
        end
        ImGui.Separator()
        if ImGui.BeginMenu('Roles') then
            if ImGui.Selectable('Main Assist') then
                mq.cmdf("/grouproles set %s 2", memberName)
            end
            if ImGui.Selectable('Main Tank') then
                mq.cmdf("/grouproles set %s 1", memberName)
            end
            if ImGui.Selectable('Puller') then
                mq.cmdf("/grouproles set %s 3", memberName)
            end
            if TLO.Me.GroupLeader() and ImGui.Selectable('Make Leader') then
                mq.cmdf("/makeleader %s", memberName)
            end
            if TLO.Group.Leader.ID() == member.ID() and ImGui.Selectable('Make Me Leader') then
                mq.cmdf("/dex %s /makeleader %s",member.Name(), myName)
            end
        ImGui.EndMenu()
        end
    ImGui.EndPopup()
    end
    ImGui.Separator()

    -- Health Bar
    if member.Present() then

        if settings[script].DynamicHP then
            r = 1
            b = b * (100 - member.PctHPs()) / 150
            g = 0.1
            a = 0.9
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram, ImVec4(r, g, b, a))
        else
            if member.PctHPs() <= 0  or member.PctHPs() == nil then
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('purple')))
            elseif member.PctHPs() < 15 then
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('pink')))
            else
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('red')))
            end
        end
        ImGui.ProgressBar(((tonumber(member.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * Scale, '##pctHps'..id)
        ImGui.PopStyleColor()

        if ImGui.IsItemHovered() then
            ImGui.SetTooltip("%s\n%d%% Health", member.DisplayName(),member.PctHPs())
        end

        --My Mana Bar
        if showMana then
            for i, v in pairs(manaClass) do
                if string.find(member.Class.ShortName(), v) then
                    if settings[script].DynamicMP then
                        b = 0.9
                        r = 1 * (100 - member.PctMana()) / 200
                        g = 0.9 * member.PctMana() / 100  > 0.1 and 0.9 * member.PctMana() / 100 or 0.1
                        a = 0.5
                        ImGui.PushStyleColor(ImGuiCol.PlotHistogram, ImVec4(r, g, b, a))
                    else
                    ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('light blue2')))
                    end
                    ImGui.ProgressBar(((tonumber(member.PctMana() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * Scale, '##pctMana'..id)
                    ImGui.PopStyleColor()
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip("%s\n%d%% Mana",member.DisplayName(), member.PctMana())
                    end
                end
            end
        end
        if showEnd then
            --My Endurance bar
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('yellow2')))
            ImGui.ProgressBar(((tonumber(member.PctEndurance() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * Scale, '##pctEndurance'..id)
            ImGui.PopStyleColor()
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip("%s\n%d%% Endurance", member.DisplayName(), member.PctEndurance())
            end
        end

    else
        ImGui.Dummy(ImGui.GetContentRegionAvail(), 20)
    end

    ImGui.EndGroup()
    if ImGui.IsItemHovered() and member.Present() then
        giveItem(member.ID() or 0, memberName)
    end
    -- Pet Health

    if showPet then
        ImGui.BeginGroup()            
        if member.Pet() ~= 'NO PET' then
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('green2')))
            ImGui.ProgressBar(((tonumber(member.Pet.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 4 * Scale, '##PetHp'..id)
            ImGui.PopStyleColor()
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip('%s\n%d%% health',member.Pet.DisplayName(), member.Pet.PctHPs())
                giveItem(member.Pet.ID() or 0, member.Pet.DisplayName())
            end
        end
        ImGui.EndGroup()
    end
    ImGui.Separator()

end

local function DrawSelf()
    local mySelf = TLO.Me
    local memberName = mySelf.Name()
    local r,g,b,a = 1,1,1,1
    if mySelf == 'NULL' then return end

    function GetInfoToolTip()
        local pInfoToolTip = (mySelf.Name() ..
            '\t\tlvl: ' .. tostring(mySelf.Level()) ..
            '\nClass: ' .. mySelf.Class.Name() ..
            '\nHealth: ' .. tostring(mySelf.CurrentHPs()) .. ' of ' .. tostring(mySelf.MaxHPs()) ..
            '\nMana: ' .. tostring(mySelf.CurrentMana()) .. ' of ' .. tostring(mySelf.MaxMana()) ..
            '\nEnd: ' .. tostring(mySelf.CurrentEndurance()) .. ' of ' .. tostring(mySelf.MaxEndurance())
        )
        return pInfoToolTip
    end

    ImGui.BeginGroup()
    if ImGui.BeginTable("##playerInfoSelf", 4, tPlayerFlags) then

        ImGui.TableSetupColumn("##tName", ImGuiTableColumnFlags.NoResize, (ImGui.GetContentRegionAvail() * .5))
        ImGui.TableSetupColumn("##tVis", ImGuiTableColumnFlags.NoResize, 16)
        ImGui.TableSetupColumn("##tIcons", ImGuiTableColumnFlags.WidthStretch, 80) --ImGui.GetContentRegionAvail()*.25)
        ImGui.TableSetupColumn("##tLvl", ImGuiTableColumnFlags.NoResize, 30)
        ImGui.TableNextRow()
        -- Name
        ImGui.TableSetColumnIndex(0)

        -- local memberName = member.Name()

        ImGui.Text( 'F1')
        ImGui.SameLine()
        ImGui.Text(memberName)

        -- Visiblity

        ImGui.TableSetColumnIndex(1)
        if TLO.Group.MainTank.ID() == mySelf.ID() then
            ImGui.SameLine()
            DrawStatusIcon('A_Tank','pwcs','Main Tank')
        end

        -- Icons

        ImGui.TableSetColumnIndex(2)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 0, 0)
        ImGui.Text('')

        if TLO.Group.MainAssist.ID() == mySelf.ID() then
            ImGui.SameLine()
            DrawStatusIcon('A_Assist','pwcs','Main Assist')
        end

        if TLO.Group.Puller.ID() == mySelf.ID() then
            ImGui.SameLine()
            DrawStatusIcon('A_Puller','pwcs','Puller')
        end

        ImGui.SameLine()
        ImGui.Text(' ')
        ImGui.SameLine()

        local dist = mySelf.Distance() or 9999

        if dist > 200 then
            ImGui.TextColored(COLOR.color('red'),"%d",math.floor(dist))
            else
            ImGui.TextColored(COLOR.color('green'),"%d",math.floor(dist))
        end

        ImGui.PopStyleVar()
        -- Lvl
        ImGui.TableSetColumnIndex(3)
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 0)
        ImGui.Text("%s",(mySelf.Level() or 0))
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip(GetInfoToolTip())
        end
        ImGui.PopStyleVar()
        ImGui.EndTable()
    end

    if ImGui.BeginPopupContextItem("##groupContextSelf") then -- Context menu for the group Roles

        if ImGui.BeginMenu('Roles') then
            if ImGui.Selectable('Main Assist') then
                mq.cmdf("/grouproles set %s 2", memberName)
            end
            if ImGui.Selectable('Main Tank') then
                mq.cmdf("/grouproles set %s 1", memberName)
            end
            if ImGui.Selectable('Puller') then
                mq.cmdf("/grouproles set %s 3", memberName)
            end
            if TLO.Me.GroupLeader() and ImGui.Selectable('Group Leader') then
                mq.cmdf("/makeleader %s", memberName)
            end
        ImGui.EndMenu()
        end
    ImGui.EndPopup()
    end
    ImGui.Separator()

    -- Health Bar
        if settings[script].DynamicHP then
            r = 1
            b = b * (100 - mySelf.PctHPs()) / 150
            g = 0.1
            a = 0.9
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram, ImVec4(r, g, b, a))
        else
            if mySelf.PctHPs() <= 0  or mySelf.PctHPs() == nil then
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('purple')))
            elseif mySelf.PctHPs() < 15 then
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('pink')))
            else
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('red')))
            end
        end
        ImGui.ProgressBar(((tonumber(mySelf.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * Scale, '##pctHpsSelf')
        ImGui.PopStyleColor()

        if ImGui.IsItemHovered() then
            ImGui.SetTooltip('%s\n%d%% Health',mySelf.DisplayName(), mySelf.PctHPs())
        end

        --My Mana Bar
        if showMana then
            for i, v in pairs(manaClass) do
                if string.find(mySelf.Class.ShortName(), v) then
                    if settings[script].DynamicMP then
                        b = 0.9
                        r = 1 * (100 - mySelf.PctMana()) / 200
                        g = 0.9 * mySelf.PctMana() / 100  > 0.1 and 0.9 * mySelf.PctMana() / 100 or 0.1
                        a = 0.5
                        ImGui.PushStyleColor(ImGuiCol.PlotHistogram, ImVec4(r, g, b, a))
                    else
                    ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('light blue2')))
                    end
                    ImGui.ProgressBar(((tonumber(mySelf.PctMana() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * Scale, '##pctManaSelf')
                    ImGui.PopStyleColor()
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip('%s\n%d%% Mana',mySelf.DisplayName(), mySelf.PctMana())
                    end
                end
            end
        end
        if showEnd then
            --My Endurance bar
            ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('yellow2')))
            ImGui.ProgressBar(((tonumber(mySelf.PctEndurance() or 0)) / 100), ImGui.GetContentRegionAvail(), 7 * Scale, '##pctEnduranceSelf')
            ImGui.PopStyleColor()
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip('%s\n%d%% Endurance',mySelf.DisplayName(), mySelf.PctEndurance())
            end
        end

            -- Pet Health

        if showPet then
            ImGui.BeginGroup()            
            if mySelf.Pet() ~= 'NO PET' then
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('green2')))
                ImGui.ProgressBar(((tonumber(mySelf.Pet.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 4 * Scale, '##PetHpSelf')
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('%s\n%d%% health',mySelf.Pet.DisplayName(), mySelf.Pet.PctHPs())
                    if ImGui.IsMouseClicked(0) then
                        mq.cmdf("/target id %s", mySelf.Pet.ID())
                        if TLO.Cursor() then
                            mq.cmdf('/multiline ; /tar id %s; /face; /if (${Cursor.ID}) /click left target',mySelf.Pet.ID())
                        end
                    end
                end
            end
            ImGui.EndGroup()
        end
        ImGui.Separator()

    ImGui.EndGroup()
    if ImGui.IsItemHovered() then
        local iconID = TLO.Cursor.Icon() or 0
        if iconID > 0 then
            local itemIcon = mq.FindTextureAnimation('A_DragItem')
            itemIcon:SetTextureCell(iconID-500)
            ImGui.BeginTooltip()
            ImGui.DrawTextureAnimation(itemIcon, 40, 40)
            ImGui.EndTooltip()
        end
    end
end

local function GUI_Group()
    ------- Main Window --------
    if ShowGUI then
        ColorCount = 0
        StyleCount = 0

        if currZone ~= lastZone then return end
        local flags = winFlag
        if locked then
            flags = bit32.bor(flags, ImGuiWindowFlags.NoMove)
        end
        -- Default window size
        ImGui.SetNextWindowSize(216, 239, ImGuiCond.FirstUseEver)
        ColorCount, StyleCount = DrawTheme(themeName)
        local openGUI, showMain = ImGui.Begin("My Group##MyGroup"..TLO.Me.DisplayName(), true, flags)
        if not openGUI then ShowGUI = false end
        if showMain then
            mouseHover = ImGui.IsWindowHovered(ImGuiHoveredFlags.ChildWindows)
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
                    ImGui.SetTooltip("Lock Window")
                end
                if ImGui.Button(gIcon..'##PlayerTarg') then
                    openConfigGUI = not openConfigGUI
                end
                ImGui.EndMenuBar()
            end
            ImGui.SetWindowFontScale(Scale)
            -- Player Information
            if showSelf then
                DrawSelf()
            end

            if TLO.Me.GroupSize() > 0 then
                for i = 1, TLO.Me.GroupSize() -1 do
                    local member = TLO.Group.Member(i)
                    if member ~= 'NULL' then
                        ImGui.BeginGroup()
                        DrawGroupMember(i)
                        ImGui.EndGroup()
                    end
                end
            end

            if settings[script].ShowDummy then
                if TLO.Me.GroupSize() < 6 then
                    local dummyCount = 6 - TLO.Me.GroupSize()
                    if TLO.Me.GroupSize() == 0 then dummyCount = 5 end
                    for i = 1, dummyCount do
                        ImGui.BeginChild("Dummy##"..i,-1, 62, bit32.bor(ImGuiChildFlags.Border),ImGuiWindowFlags.NoScrollbar)
                        ImGui.Dummy(ImGui.GetContentRegionAvail(), 75)
                        ImGui.EndChild()
                    end
                end
            end

            ImGui.SeparatorText('Commands')

            local lbl = TLO.Me.Invited() and 'Follow' or 'Invite'

            if ImGui.SmallButton(lbl) then
                mq.cmdf("/invite %s", TLO.Target.Name())
            end

            if TLO.Me.GroupSize() > 0 then
                ImGui.SameLine()
            end

            if TLO.Me.GroupSize() > 0 then
                if ImGui.SmallButton('Disband') then
                    mq.cmdf("/disband")
                end
            end

            ImGui.Separator()

            if ImGui.SmallButton('Come') then
                if useEQBC then
                    mq.cmdf("/bcaa //nav spawn %s", myName)
                    else
                    mq.cmdf("/dgge /nav spawn %s", myName)
                end
            end

            ImGui.SameLine()

            local tmpFollow = followMe
            if followMe then ImGui.PushStyleColor(ImGuiCol.Button, COLOR.color('pink')) end
            if ImGui.SmallButton('Follow') then
                if not followMe then
                    if useEQBC then
                        mq.cmdf("/multiline ; /dcaa //nav stop; /dcaa //afollow spawn %d", meID)
                        else
                        mq.cmdf("/multiline ; /dgge /nav stop; /dgge /afollow spawn %d", meID)
                    end
                else
                    if useEQBC then
                        mq.cmd("/bcaa //afollow off")
                        else
                        mq.cmd("/dgge /afollow off")
                    end
                end
                tmpFollow = not tmpFollow
            end
            if followMe then ImGui.PopStyleColor(1) end
            followMe = tmpFollow

            ImGui.SameLine()
            local tmpMimic = mimicMe
            if mimicMe then ImGui.PushStyleColor(ImGuiCol.Button, COLOR.color('pink')) end
            if ImGui.SmallButton('Mimic') then
                if mimicMe then
                    mq.cmd("/groupinfo mimicme off")
                    else
                    mq.cmd("/groupinfo mimicme on")
                end
                tmpMimic = not tmpMimic
            end
            if mimicMe then ImGui.PopStyleColor(1) end
            mimicMe = tmpMimic

        end
        if StyleCount > 0 then ImGui.PopStyleVar(StyleCount) end
        if ColorCount > 0 then ImGui.PopStyleColor(ColorCount) end

        ImGui.SetWindowFontScale(1)
        ImGui.End()

    end

-- Config Window
    if openConfigGUI then
        ColorCountConf = 0
        StyleCountConf = 0
        ColorCountConf, StyleCountConf = DrawTheme(themeName)
        local open, configShow = ImGui.Begin("MyGroup Conf", true, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.AlwaysAutoResize))
        if not open then openConfigGUI = false end
        if configShow then
            ImGui.SetWindowFontScale(Scale)
            ImGui.SeparatorText("Theme##"..script)
            ImGui.Text("Cur Theme: %s", themeName)
            -- Combo Box Load Theme
            if ImGui.BeginCombo("Load Theme##MyGroup", themeName) then
                for k, data in pairs(theme.Theme) do
                    local isSelected = data.Name == themeName
                    if ImGui.Selectable(data.Name, isSelected) then
                        theme.LoadTheme = data.Name
                        themeName = theme.LoadTheme
                        settings[script].LoadTheme = themeName
                    end
                end
                ImGui.EndCombo()

            end

            if ImGui.Button('Reload Theme File') then
                loadTheme()
            end
            settings[script].MouseOver = ImGui.Checkbox('Mouse Over', settings[script].MouseOver)
            settings[script].WinTransparency = ImGui.SliderFloat('Window Transparency##'..script, settings[script].WinTransparency, 0.1, 1.0)
            ImGui.SeparatorText("Scaling##"..script)
            -- Slider for adjusting zoom level
            local tmpZoom = Scale
            if Scale then
                tmpZoom = ImGui.SliderFloat("Zoom Level##MyGroup", tmpZoom, 0.5, 2.0)
            end
            if Scale ~= tmpZoom then
                Scale = tmpZoom
                settings[script].Scale = Scale
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
            settings[script].ShowDummy = ImGui.Checkbox('Show Dummy##'..script, settings[script].ShowDummy)
            settings[script].DynamicHP = ImGui.Checkbox('Dynamic HP##'..script, settings[script].DynamicHP)
            settings[script].DynamicMP = ImGui.Checkbox('Dynamic MP##'..script, settings[script].DynamicMP)
            hideTitle = ImGui.Checkbox('Hide Title Bar##'..script, hideTitle)
            ImGui.SameLine()
            showSelf = ImGui.Checkbox('Show Self##'..script, showSelf)

            ImGui.SeparatorText("Save and Close##"..script)
            if ImGui.Button('Save and Close##'..script) then
                openConfigGUI = false
                settings[script].ShowSelf = showSelf
                settings[script].HideTitleBar = hideTitle
                settings[script].ShowMana = showMana
                settings[script].ShowEnd = showEnd
                settings[script].ShowPet = showPet
                settings[script].UseEQBC = useEQBC
                settings[script].Scale = Scale
                settings[script].LoadTheme = themeName
                settings[script].locked = locked
                writeSettings(configFile,settings)
            end
        end
        if StyleCountConf > 0 then ImGui.PopStyleVar(StyleCountConf) end
        if ColorCountConf > 0 then ImGui.PopStyleColor(ColorCountConf) end
        ImGui.SetWindowFontScale(1)
        ImGui.End()
    end
end

local function init()
    myName = mq.TLO.Me.Name()
    serverName = TLO.EverQuest.Server()
    serverName = serverName:gsub(" ", "_")
    configFileold2 = string.format("%s/MyUI/MyGroup/%s_%s_Config.lua",mq.configDir, serverName, myName)
    configFile = string.format("%s/MyUI/MyGroup/%s/%s.lua",mq.configDir, serverName, myName)
    loadSettings()
    currZone = TLO.Zone.ID()
    lastZone = currZone
    mq.imgui.init('GUI_MyGroup', GUI_Group)
end

local function MainLoop()
    while ShowGUI do
        meID = TLO.Me.ID()
        if TLO.Window('CharacterListWnd').Open() then return false end
        currZone = mq.TLO.Zone.ID()
        if not mq.TLO.MacroQuest.GameState() == "INGAME"then mq.exit() end
        mq.delay(33)

        if currZone ~= lastZone then
            mimicMe = false
            followMe = false
            mq.delay(100)
            lastZone = currZone
        end

        if hideTitle then
            winFlag = bit32.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.MenuBar)
            else
            winFlag = bit32.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.MenuBar)
        end

        if mimicMe and lastTar ~= TLO.Target.ID() then
            lastTar = TLO.Target.ID()
            mq.cmdf("/dgge /target id %s", TLO.Target.ID())
        end
    end
end
if mq.TLO.EverQuest.GameState() ~= "INGAME" then print("\aw[\atMySpells\ax] \arNot in game, \ayTry again later...") mq.exit() end
init()
printf("\ag %s \aw[\ayMy Group\aw] ::\at Loaded",TLO.Time())
MainLoop()