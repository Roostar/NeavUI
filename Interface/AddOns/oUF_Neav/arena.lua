
local _, ns = ...
local config = ns.Config

if (not config.units.arena.show) then
    return
end

SetCVar('showArenaEnemyFrames', 0)

local arenaAnchor = CreateFrame('Frame', 'oUF_Neav_Arena_Anchor', UIParent)
arenaAnchor:SetSize(250, 129)
arenaAnchor:SetPoint(unpack(config.units.boss.position))
arenaAnchor:SetMovable(true)
arenaAnchor:SetUserPlaced(true)
arenaAnchor:SetClampedToScreen(true)
arenaAnchor:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8x8'})
arenaAnchor:SetBackdropColor(0, 1, 0, 0.55)
arenaAnchor:EnableMouse(true)
arenaAnchor:RegisterForDrag('LeftButton')
arenaAnchor:Hide()
arenaAnchor.text = arenaAnchor:CreateFontString(nil, 'OVERLAY')
arenaAnchor.text:SetAllPoints(arenaAnchor)
arenaAnchor.text:SetFont('Fonts\\ARIALN.ttf', 13)
arenaAnchor.text:SetText('oUF_Neav\nArena')

arenaAnchor:SetScript('OnDragStart', function()
    if (IsShiftKeyDown() and IsAltKeyDown()) then
        arenaAnchor:StartMoving()
    end
end)

arenaAnchor:SetScript('OnDragStop', function()
    arenaAnchor:StopMovingOrSizing()
end)

local function ColorNameBackground(self, unit)
    local _, class = UnitClass(unit)
    local classColor = RAID_CLASS_COLORS[class]
    if (classColor ~= nil) then
        self.Name.Bg:SetVertexColor(classColor.r, classColor.g, classColor.b)
    else
        self.Name.Bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

local function UpdateHealth(Health, unit, cur, max)
    if (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
        Health:SetStatusBarColor(0.5, 0.5, 0.5)
    else
        Health:SetStatusBarColor(0, 1, 0)
    end

    if (Health.Value) then
        Health.Value:SetText(ns.GetHealthText(unit, cur, max))
    end

    local self = Health:GetParent()
    if (self.Name.Bg) then
        ColorNameBackground(self, unit)
    end
end

local function UpdatePower(Power, unit, cur, min, max)
    if (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
        Power:SetValue(0)
    end

    Power.Value:SetText(ns.GetPowerText(unit, cur, max))
end

local function FilterArenaBuffs(...)

    local icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster = ...
    local buffList = config.units.arena.buffList

    if (buffList[name]) then
        return true
    end
    return false
end

local function CreateArenaLayout(self, unit)
    self:RegisterForClicks('AnyUp')
    self:EnableMouse(true)

    self:SetScript('OnEnter', UnitFrame_OnEnter)
    self:SetScript('OnLeave', UnitFrame_OnLeave)

    self:SetFrameStrata('LOW')

    if (unit:match('arena%dtarget')) then
        self.targetUnit = true
    else
        self.arenaUnit = true
    end

        -- healthbar

    self.Health = CreateFrame('StatusBar', nil, self)

        -- texture

    self.Texture = self.Health:CreateTexture(nil, 'ARTWORK')
    self.Texture:SetTexture('Interface\\AddOns\\oUF_Neav\\media\\arenaFrameTexture')
    self.Texture:SetSize(250, 129)
    self.Texture:SetPoint('CENTER', self, 31, -24)

        -- healthbar

    self.Health = CreateFrame('StatusBar', nil, self)
    self.Health:SetStatusBarTexture(config.media.statusbar, 'BORDER')
    self.Health:SetSize(115, 8)
    self.Health:SetPoint('TOPRIGHT', self.Texture, -105, -43)

    self.Health:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8x8'})
    self.Health:SetBackdropColor(0, 0, 0, 0.55)

    self.Health.frequentUpdates = true
    self.Health.Smooth = true

    self.Health.PostUpdate = UpdateHealth

        -- powerbar

    if (self.arenaUnit) then
        self.Power = CreateFrame('StatusBar', nil, self)
        self.Power:SetStatusBarTexture(config.media.statusbar, 'BORDER')
        self.Power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -3)
        self.Power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -3)
        self.Power:SetHeight(self.Health:GetHeight())

        self.Power:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8x8'})
        self.Power:SetBackdropColor(0, 0, 0, 0.55)

        self.Power.PostUpdate = UpdatePower
        self.Power.frequentUpdates = true
        self.Power.Smooth = true

        self.Power.colorPower = true
    end

        -- name

    self.Name = self.Health:CreateFontString(nil, 'ARTWORK')
    self.Name:SetFont(config.font.normalBig, config.font.normalBigSize)
    self.Name:SetShadowOffset(1, -1)
    self.Name:SetJustifyH('CENTER')
    self.Name:SetSize(110, 10)
    self.Name:SetPoint('BOTTOM', self.Health, 'TOP', 0, 6)

    self:Tag(self.Name, '[name]')
    self.UNIT_NAME_UPDATE = UpdateFrame

    if (self.arenaUnit) then

            -- health text

        self.Health.Value = self.Health:CreateFontString(nil, 'ARTWORK')
        self.Health.Value:SetFont('Fonts\\ARIALN.ttf', config.font.normalSize, nil)
        self.Health.Value:SetShadowOffset(1, -1)
        self.Health.Value:SetPoint('CENTER', self.Health)

            -- power text

        self.Power.Value = self.Health:CreateFontString(nil, 'ARTWORK')
        self.Power.Value:SetFont('Fonts\\ARIALN.ttf', config.font.normalSize, nil)
        self.Power.Value:SetShadowOffset(1, -1)
        self.Power.Value:SetPoint('CENTER', self.Power)

            -- colored name background

        self.Name.Bg = self.Health:CreateTexture(nil, 'BACKGROUND')
        self.Name.Bg:SetHeight(18)
        self.Name.Bg:SetTexCoord(0.2, 0.8, 0.3, 0.85)
        self.Name.Bg:SetPoint('BOTTOMRIGHT', self.Health, 'TOPRIGHT')
        self.Name.Bg:SetPoint('BOTTOMLEFT', self.Health, 'TOPLEFT')
        self.Name.Bg:SetTexture('Interface\\AddOns\\oUF_Neav\\media\\nameBackground')

            -- Raid target indicator

        self.RaidTargetIndicator = self.Health:CreateTexture(nil, 'OVERLAY', self)
        self.RaidTargetIndicator:SetPoint('CENTER', self, 'TOPRIGHT', -9, -5)
        self.RaidTargetIndicator:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
        self.RaidTargetIndicator:SetSize(26, 26)

        self.Buffs = CreateFrame('Frame', nil, self)
        self.Buffs.size = 22
        self.Buffs:SetHeight(self.Buffs.size * 3)
        self.Buffs:SetWidth(self.Buffs.size * 4)
        self.Buffs:SetPoint('TOPRIGHT', self.Power, 'BOTTOMRIGHT', 2, -6)
        self.Buffs.initialAnchor = 'TOPRIGHT'
        self.Buffs['growth-x'] = 'LEFT'
        self.Buffs['growth-y'] = 'DOWN'
        self.Buffs.num = 8
        self.Buffs.spacing = 4.5

        if (config.units.arena.filterBuffs) then
            self.Buffs.CustomFilter = FilterArenaBuffs
        end

        self.Buffs.PostCreateIcon = ns.UpdateAuraIcons
        self.Buffs.PostUpdateIcon = ns.PostUpdateIcon

        self.Debuffs = CreateFrame('Frame', nil, self)
        self.Debuffs.size = 22
        self.Debuffs:SetHeight(self.Debuffs.size * 3)
        self.Debuffs:SetWidth(self.Debuffs.size * 4)
        self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 6, -6)
        self.Debuffs.initialAnchor = 'TOPLEFT'
        self.Debuffs['growth-x'] = 'RIGHT'
        self.Debuffs['growth-y'] = 'DOWN'
        self.Debuffs.num = 8
        self.Debuffs.spacing = 4.5

        self.Debuffs.PostCreateIcon = ns.UpdateAuraIcons
        self.Debuffs.PostUpdateIcon = ns.PostUpdateIcon

        self.Castbar = CreateFrame('StatusBar', self:GetName()..'Castbar', self)
        self.Castbar:SetStatusBarTexture(config.media.statusbar)
        self.Castbar:SetParent(self)
        self.Castbar:SetHeight(21)
        self.Castbar:SetWidth(200)
        self.Castbar:SetStatusBarColor(unpack(config.units.arena.castbar.color))
        self.Castbar:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -16, 4)

        self.Castbar.Bg = self.Castbar:CreateTexture(nil, 'BACKGROUND')
        self.Castbar.Bg:SetTexture('Interface\\Buttons\\WHITE8x8')
        self.Castbar.Bg:SetAllPoints(self.Castbar)
        self.Castbar.Bg:SetVertexColor(config.units.arena.castbar.color[1]*0.3, config.units.arena.castbar.color[2]*0.3, config.units.arena.castbar.color[3]*0.3, 0.8)

        self.Castbar:CreateBeautyBorder(11)
        self.Castbar:SetBeautyBorderPadding(3)

        self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'BACKGROUND')
        self.Castbar.Icon:SetSize(config.units.arena.castbar.icon.size, config.units.arena.castbar.icon.size)
        self.Castbar.Icon:SetPoint('TOPRIGHT', self.Castbar, 'TOPLEFT', -10, 0.45)
        self.Castbar.Icon:SetColorTexture(1, 1, 1)

        self.Castbar.Icon.Overlay = self.Castbar:CreateTexture(nil, 'ARTWORK')
        self.Castbar.Icon.Overlay:SetPoint('TOPRIGHT', self.Castbar.Icon, 3, 3)
        self.Castbar.Icon.Overlay:SetPoint('BOTTOMLEFT', self.Castbar.Icon, -3, -3)
        self.Castbar.Icon.Overlay:SetTexture(config.media.border)
        self.Castbar.Icon.Overlay:SetVertexColor(1, 0, 0)

        self.Castbar.Icon.Shadow = self.Castbar:CreateTexture(nil, 'BACKGROUND')
        self.Castbar.Icon.Shadow:SetPoint('TOPRIGHT', self.Castbar.Icon, 6, 6)
        self.Castbar.Icon.Shadow:SetPoint('BOTTOMLEFT', self.Castbar.Icon, -6, -6)
        self.Castbar.Icon.Shadow:SetTexture('Interface\\AddOns\\oUF_Neav\\media\\borderBackground')
        self.Castbar.Icon.Shadow:SetVertexColor(0, 0, 0, 1)

        ns.CreateCastbarStrings(self, true)

        self.Castbar.CustomDelayText = ns.CustomDelayText
        self.Castbar.CustomTimeText = ns.CustomTimeText

            -- oUF_Trinket support

        self.Trinket = CreateFrame('Frame', nil, self)
        self.Trinket:SetSize(30, 30)
        self.Trinket:SetPoint('RIGHT', self, 'LEFT', -10, 1)
        self.Trinket.trinketUseAnnounce = true
        self.Trinket.trinketUpAnnounce = true

            -- oUF_Talents support
        --[[
        self.Talents = self.Health:CreateFontString(nil, 'OVERLAY')
        self.Talents:SetFont(config.font.normal, 16)
        self.Talents:SetTextColor(1, 0, 0)
        self.Talents:SetPoint('BOTTOM', self.Health, 'TOP', 0, 12)
        --]]

        self:SetSize(132, 46)
    end

    if (self.targetUnit) then
        self:SetSize(110, 20)

        self.Portrait = self:CreateTexture(nil, 'BACKGROUND')
        self.Portrait:SetSize(37, 37)
        self.Portrait:SetPoint('TOPLEFT', self.Texture, 7, -6)

        self.Texture:SetTexture('Interface\\AddOns\\oUF_Neav\\media\\customTargetTargetTexture')
        self.Texture:SetPoint('CENTER', self, 0, -2)
        self.Texture:SetSize(128, 64)

        self.Name:SetPoint('TOPLEFT', self.Portrait, 'BOTTOMRIGHT', 2, -7)
        self.Name:SetJustifyH('LEFT')
        self.Name:SetJustifyV('BOTTOM')
        self.Name:SetSize(75, 10)

        self.Health:SetSize(50, 5)
        self.Health:ClearAllPoints()
        self.Health:SetPoint('CENTER', self.Texture, 5, 8)
    end

    self:SetScale(config.units.arena.scale)

    return self
end

oUF:RegisterStyle('oUF_Neav_Arena', CreateArenaLayout)
oUF:Factory(function(self)
    oUF:SetActiveStyle('oUF_Neav_Arena')

    local arena = {}
    local arenaTarget = {}
    for i = 1, 5 do
        arena[i] = self:Spawn('arena'..i, 'oUF_Neav_ArenaFrame'..i)
        arena[i]:SetFrameStrata('LOW')

        if (i == 1) then
            arena[i]:SetPoint('TOPRIGHT', arenaAnchor, 'TOPRIGHT',0,0)
        else
            arena[i]:SetPoint('TOPLEFT', arena[i-1], 'BOTTOMLEFT', 0, -80)
        end

        arenaTarget[i] = self:Spawn('arena'..i..'target', 'oUF_Neav_ArenaFrame'..i..'Target')
        arenaTarget[i]:SetPoint('TOPRIGHT', arena[i], 'BOTTOMLEFT', 71, -7)
    end
end)
