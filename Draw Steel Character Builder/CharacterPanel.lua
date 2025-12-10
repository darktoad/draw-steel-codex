--[[
    Character Panel
]]

local mod = dmhub.GetModLoading()

local _fireControllerEvent = CharacterBuilder._fireControllerEvent
local _getToken = CharacterBuilder._getToken

local INITIAL_TAB = "builder"

function CharacterBuilder._characterBulderPanel(tabId)
    return gui.Panel {
        width = "96%",
        height = "60%",
        halign = "center",
        valign = "top",
        data = {
            id = tabId,
        },

        _refreshTabs = function(element, tabId)
            element:SetClass("collapsed", tabId ~= element.data.id)
        end,

        gui.Label{
            width = "100%",
            height = "auto",
            valign = "top",
            text = "Builder content here...",
        }
    }
end

function CharacterBuilder._characterDescriptionPanel(tabId)
    return gui.Panel {
        width = "96%",
        height = "60%",
        halign = "center",
        valign = "top",
        data = {
            id = tabId,
        },

        _refreshTabs = function(element, tabId)
            element:SetClass("collapsed", tabId ~= element.data.id)
        end,

        gui.Label{
            width = "100%",
            height = "auto",
            valign = "top",
            text = "Description content here...",
        }
    }
end

function CharacterBuilder._characterExplorationPanel(tabId)
    return gui.Panel {
        width = "96%",
        height = "60%",
        halign = "center",
        valign = "top",
        data = {
            id = tabId,
        },

        _refreshTabs = function(element, tabId)
            element:SetClass("collapsed", tabId ~= element.data.id)
        end,

        gui.Label{
            width = "100%",
            height = "auto",
            valign = "top",
            text = "Exploration content here...",
        }
    }
end

function CharacterBuilder._characterTacticalPanel(tabId)
    return gui.Panel {
        width = "96%",
        height = "60%",
        halign = "center",
        valign = "top",
        data = {
            id = tabId,
        },

        _refreshTabs = function(element, tabId)
            element:SetClass("collapsed", tabId ~= element.data.id)
        end,

        gui.Label{
            width = "100%",
            height = "auto",
            valign = "top",
            text = "Tactical content here...",
        }
    }
end

function CharacterBuilder._characterDetailPanel()

    local detailPanel

    local tabs = {
        builder = {
            icon = "panels/gamescreen/settings.png",
            content = CharacterBuilder._characterBulderPanel,
        },
        description = {
            icon = "icons/icon_app/icon_app_31.png",
            content = CharacterBuilder._characterDescriptionPanel,
        },
        exploration = {
            icon = "game-icons/treasure-map.png",
            content = CharacterBuilder._characterExplorationPanel,
        },
        tactical = {
            icon = "panels/initiative/initiative-icon.png",
            content = CharacterBuilder._characterTacticalPanel,
        }
    }
    local tabOrder = {"builder", "description", "exploration", "tactical"}

    local tabButtons = {}
    for _,tabId in ipairs(tabOrder) do
        local tabInfo = tabs[tabId]
        local btn = gui.Panel{
            classes = {"char-tab-btn"},
            halign = "right",
            hmargin = 8,
            bgimage = tabInfo.icon,

            data = {
                id = tabId,
            },

            linger = function(element)
                gui.Tooltip(element.data.id:sub(1,1):upper() .. element.data.id:sub(2))(element)
            end,

            _refreshTabs = function(element, activeTabId)
                element:SetClass("selected", activeTabId == element.data.id)
            end,

            press = function(element)
                detailPanel:FireEvent("tabClick", tabId)
            end,
        }
        tabButtons[#tabButtons+1] = btn
    end

    local tabPanel = gui.Panel{
        width = "100%",
        height = 24,
        tmargin = 8,
        vpad = 4,
        flow = "horizontal",
        bgimage = true,
        borderColor = CharacterBuilder.COLORS.GOLD03,
        border = { y2 = 0, y1 = 1, x2 = 0, x1 = 0 },

        children = tabButtons,
    }

    local contentPanel = gui.Panel{
        width = "100%",
        height = "auto",
        halign = "center",
        valign = "top",
        vscroll = true,

        data = {
            madeContent = {},
        },

        _refreshTabs = function(element, tabId)
            if element.data.madeContent[tabId] == nil then
                element:AddChild(tabs[tabId].content(tabId))
                element.data.madeContent[tabId] = true
            end
        end
    }

    detailPanel = gui.Panel{
        width = "100%",
        height = "100%-240",
        flow = "vertical",

        create = function(element)
            element:FireEvent("tabClick", INITIAL_TAB)
        end,

        tabClick = function(element, tabId)
            element:FireEventTree("_refreshTabs", tabId)
        end,

        tabPanel,
        contentPanel,
    }

    return detailPanel
end

function CharacterBuilder._characterHeaderPanel()

    local popoutAvatar = gui.Panel {
        classes = { "hidden" },
        interactable = false,
        width = 800,
        height = 800,
        halign = "center",
        valign = "center",
        bgcolor = "white",
    }

    local avatar = gui.IconEditor {
        library = cond(dmhub.GetSettingValue("popoutavatars"), "popoutavatars", "Avatar"),
        restrictImageType = "Avatar",
        allowPaste = true,
        borderColor = Styles.textColor,
        borderWidth = 2,
        cornerRadius = math.floor(0.5 * CharacterBuilder.SIZES.AVATAR_DIAMETER),
        width = CharacterBuilder.SIZES.AVATAR_DIAMETER,
        height = CharacterBuilder.SIZES.AVATAR_DIAMETER,
        autosizeimage = true,
        halign = "center",
        valign = "top",
        tmargin = 20,
        bgcolor = "white",

        children = { popoutAvatar, },

        thinkTime = 0.2,
        think = function(element)
            element:FireEvent("imageLoaded")
        end,

        updatePopout = function(element, ispopout)
            if not ispopout then
                popoutAvatar:SetClass("hidden", true)
            else
                popoutAvatar:SetClass("hidden", false)
                popoutAvatar.bgimage = element.value
                popoutAvatar.selfStyle.scale = .25
                element.bgimage = false --"panels/square.png"
            end

            local parent = element:FindParentWithClass("avatarSelectionParent")
            if parent ~= nil then
                parent:SetClassTree("popout", ispopout)
            end
        end,

        imageLoaded = function(element)
            if element.bgsprite == nil then
                return
            end

            local maxDim = max(element.bgsprite.dimensions.x, element.bgsprite.dimensions.y)
            if maxDim > 0 then
                local yratio = element.bgsprite.dimensions.x / maxDim
                local xratio = element.bgsprite.dimensions.y / maxDim
                element.selfStyle.imageRect = { x1 = 0, y1 = 1 - yratio, x2 = xratio, y2 = 1 }
            end
        end,

        refreshAppearance = function(element, info)
            print("APPEARANCE:: Set avatar", info.token.portrait)
            element.SetValue(element, info.token.portrait, false)
            element:FireEvent("imageLoaded")
            element:FireEvent("updatePopout", info.token.popoutPortrait)
        end,

        change = function(element)
            -- local info = CharacterSheet.instance.data.info
            -- info.token.portrait = element.value
            -- info.token:UploadAppearance()
            -- CharacterSheet.instance:FireEvent("refreshAll")
            -- element:FireEvent("imageLoaded")
        end,
    }

    local characterName = gui.Label {
        classes = {"label", "builder-base"},
        text = "calculating...",
        width = "98%",
        height = "auto",
        halign = "center",
        valign = "top",
        textAlignment = "center",
        tmargin = 12,
        fontSize = 24,
        editable = true,
        data = {
            text = "",
        },
        refreshToken = function(element)
            local t = _getToken(element)
            element.data.text = (t and t.name and #t.name > 0) and t.name or "Unnamed Character"
            element.text = string.upper(element.data.text)
        end,
        change = function(element)
            if element.data.text ~= element.text then
                element.data.text = element.text
                local t = _getToken(element)
                if t then
                    t.name = element.data.text
                    _fireControllerEvent(element, "tokenDataChanged")
                end
            end
        end,
    }

    return gui.Panel{
        classes = {"builder-base", "panel-base"},
        width = "99%",
        height = 240,
        flow = "vertical",
        halign = "center",
        valign = "top",
        avatar,
        characterName,
    }
end

--- Generate the character panel
--- @return Panel
function CharacterBuilder._characterPanel()

    local headerPanel = CharacterBuilder._characterHeaderPanel()
    local detailPanel = CharacterBuilder._characterDetailPanel()

    return gui.Panel{
        id = "characterPanel",
        classes = {"builder-base", "panel-base", "panel-border", "characterPanel"},
        width = CharacterBuilder.SIZES.CHARACTER_PANEL_WIDTH,
        height = "99%",
        valign = "center",
        bgimage = true,
        -- halign = "right",
        flow = "vertical",

        headerPanel,
        detailPanel,
    }
end
