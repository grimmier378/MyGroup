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

-- set variables
local animSpell = mq.FindTextureAnimation('A_SpellIcons')
local animItem = mq.FindTextureAnimation('A_DragItem')
local TLO = mq.TLO
local winFlag = bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoScrollbar)
local textureWidth = 26
local textureHeight = 26
local mimic = false
local followMe = false
local ShowGUI = true
local ver = "v0.1.beta"
local tPlayerFlags = bit32.bor(ImGuiTableFlags.NoBorders, ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.NoPadInnerX,
    ImGuiTableFlags.NoPadOuterX, ImGuiTableFlags.Resizable, ImGuiTableFlags.SizingFixedFit)
local manaClass = {[1] = 'WIZ',[2] = 'MAG', [3] = 'NEC',[4] =  'CLR',[5] =  'DRU', [6] = 'SHM', [7] = 'RNG',[8] =  'SHD',[9] =  'PAL',[10] =  'BST',[12] =  'BRD',}
local lastTar = mq.TLO.Target.ID() or 0
---@param type string
---@param txt string
function DrawStatusIcon(iconID, type, txt)
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
		ImGui.SetWindowFontScale(1)
		ImGui.TableSetColumnIndex(0)

		-- local memberName = member.Name()
		local memberName = member.Name()
		ImGui.SetWindowFontScale(0.8)
		ImGui.Text( 'F'..tostring(id))
		ImGui.SetWindowFontScale(1)
		ImGui.SameLine()
		
		ImGui.Text(memberName)
	
		-- Visiblity
		ImGui.TableSetColumnIndex(1)
		-- if not member.OtherZone then
			ImGui.SetWindowFontScale(0.75)
			if member.LineOfSight() then
				ImGui.PushStyleColor(ImGuiCol.Text, 0, 1, 0, .5)
				ImGui.Text(Icons.MD_VISIBILITY_OFF)
				ImGui.PopStyleColor()
			else
				ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0, 0, .5)
				ImGui.Text(Icons.MD_VISIBILITY_OFF)
				ImGui.PopStyleColor()
			end
		-- end
		ImGui.SetWindowFontScale(.91)
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
		ImGui.SetWindowFontScale(.75)
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
		ImGui.SetWindowFontScale(1)
		ImGui.Text(tostring(member.Level() or 0))
		if ImGui.IsItemHovered() then
			ImGui.BeginTooltip()
			ImGui.Text(GetInfoToolTip())
			ImGui.EndTooltip()
		end
	
		ImGui.PopStyleVar()
		ImGui.EndTable()
	end
	ImGui.Separator()
	-- My Health Bar
	ImGui.SetWindowFontScale(0.75)
if not member.OtherZone() then
	if member.PctHPs() <= 0 then
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('purple')))
	elseif member.PctHPs() < 15 then
			ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('pink')))
	else
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('red')))
	end
	ImGui.ProgressBar(((tonumber(member.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 7, '##pctHps'..id)
	ImGui.PopStyleColor()
	if ImGui.IsItemHovered() then
		ImGui.BeginTooltip()
		ImGui.Text(member.DisplayName())
		ImGui.Text(member.PctHPs()..'% Health')
		ImGui.EndTooltip()
	end
	-- ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 15)
	-- ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ((ImGui.GetWindowWidth() / 2) - 8))
	-- ImGui.Text(tostring(member.PctHPs() or 0))
	--My Mana Bar
	for i, v in pairs(manaClass) do
		if string.find(member.Class.ShortName(), v) then
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('blue')))
		ImGui.ProgressBar(((tonumber(member.PctMana() or 0)) / 100), ImGui.GetContentRegionAvail(), 7, '##pctMana'..id)
		ImGui.PopStyleColor()
		if ImGui.IsItemHovered() then
			ImGui.BeginTooltip()
			ImGui.Text(member.DisplayName())
			ImGui.Text(member.PctMana()..'% Mana')
			ImGui.EndTooltip()
		end
		-- ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 15)
		-- ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ((ImGui.GetWindowWidth() / 2) - 8))
		-- ImGui.Text(tostring(member.PctMana() or 0))
		end
	end
	--My Endurance bar
	ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('yellow2')))
	ImGui.ProgressBar(((tonumber(member.PctEndurance() or 0)) / 100), ImGui.GetContentRegionAvail(), 7, '##pctEndurance'..id)
	ImGui.PopStyleColor()
	if ImGui.IsItemHovered() then
		ImGui.BeginTooltip()
		ImGui.Text(member.DisplayName())
		ImGui.Text(member.PctEndurance()..'% Endurance')
		ImGui.EndTooltip()
	end
	-- ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 15)
	-- ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ((ImGui.GetWindowWidth() / 2) - 8))
	-- ImGui.Text(tostring(member.PctEndurance() or 0))
	-- Pet Health
	ImGui.EndGroup()
	if ImGui.IsItemHovered() and ImGui.IsMouseReleased(ImGuiMouseButton.Left) then
		mq.cmdf("/target id %s", member.ID())
	end
	if member.Pet() ~= 'NO PET' then
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram,(COLOR.color('green2')))
		ImGui.ProgressBar(((tonumber(member.Pet.PctHPs() or 0)) / 100), ImGui.GetContentRegionAvail(), 4, '##PetHp'..id)
		ImGui.PopStyleColor()
		if ImGui.IsItemHovered() then
			ImGui.BeginTooltip()
			ImGui.Text(member.Pet.DisplayName())
			ImGui.Text(member.Pet.PctHPs()..'% health')
			ImGui.EndTooltip()
			if ImGui.IsMouseClicked(0) then
				mq.cmdf("/target id %s", member.Pet.ID())
			end
		end
	end
	ImGui.Separator()
else
	ImGui.Dummy(ImGui.GetContentRegionAvail(), 20)
end
end

function GUI_Group(open)
    if not ShowGUI then return end
    if TLO.Me.Zoning() then return end
    --Rounded corners
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 10)
    -- Default window size
    ImGui.SetNextWindowSize(216, 239, ImGuiCond.FirstUseEver)
    local show = false
    open, show = ImGui.Begin("My Group##MyGroup"..mq.TLO.Me.DisplayName(), open, winFlag)
    if not show then
        ImGui.PopStyleVar()
        ImGui.End()
        return open
    end
        ImGui.SameLine()
        ImGui.SetCursorPosX(5)
        --ImGui.SetCursorPosY(10)
		local member = nil
        -- Player Information
		if mq.TLO.Me.GroupSize() > 0 then
		for i = 1, mq.TLO.Me.GroupSize() -1 do
			member = mq.TLO.Group.Member(i)
			ImGui.BeginGroup()
			DrawGroupMember(i)
			ImGui.EndGroup()
		end
		local meID = mq.TLO.Me.ID()
		if ImGui.Button('Come\nToMe') then
			mq.cmdf("/dgge /nav spawn id %s", meID)
		end
		ImGui.SameLine()
		if followMe then
			ImGui.PushStyleColor(ImGuiCol.Button, COLOR.color('pink'))
		if ImGui.Button('Follow\nMe') then
			followMe = not followMe
			if followMe then
				mq.cmdf("/multiline ; /dgge /nav stop; /dgge /afollow spawn %s", meID)
			else
				mq.cmd("/dgge /nav stop")
			end
		end
		ImGui.PopStyleColor(1)
		else

			if ImGui.Button('Follow\nMe') then
				followMe = not followMe
				if followMe then
					mq.cmdf("/multiline ; /dgge /nav stop; /dgge /afollow spawn %s", meID)
				else
					mq.cmd("/dgge /nav stop")
				end
			end
		end
		ImGui.SameLine()
		if mimic then
			ImGui.PushStyleColor(ImGuiCol.Button, COLOR.color('pink'))
			if ImGui.Button('Mimic\nTarget') then
				mq.cmdf("/dgge /target id %s", mq.TLO.Target.ID())
				mimic = not mimic
			end
			ImGui.PopStyleColor(1)
		else
			if ImGui.Button('Mimic\nTarget') then
				mq.cmdf("/dgge /target id %s", mq.TLO.Target.ID())
				mimic = not mimic
			end
		end

	end
        ImGui.PopStyleVar()
        ImGui.Spacing()
        ImGui.End()
    return open
end

local openGUI = true
mq.imgui.init('GUI_MyGroup', GUI_Group)

local function MainLoop()
    while true do
        if TLO.Window('CharacterListWnd').Open() then return false end
        mq.delay(100)
        if mq.TLO.Me.Zoning() then
            ShowGUI = false
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

printf("\ag %s \aw[\ayMy Group\aw] ::\a-t Version \aw::\ay %s \at Loaded",TLO.Time(), ver)
MainLoop()
