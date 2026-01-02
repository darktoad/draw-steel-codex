--[[
    Kit detail / selectors
]]
CBKitDetail = RegisterGameType("CBKitDetail")

local mod = dmhub.GetModLoading()

local SELECTOR = CharacterBuilder.SELECTOR.KIT

local _fireControllerEvent = CharacterBuilder._fireControllerEvent
local _getHero = CharacterBuilder._getHero

function CBKitDetail._navPanel()
    return gui.Panel{
        classes = {"categoryNavPanel", "builder-base", "panel-base", "detail-nav-panel"},
        vscroll = true,

        refreshBuilderState = function(element, state)
        end,

        gui.Label{
            width = "auto",
            height= "auto",
            fontSize = 60,
            floating = true,
            valign = "center",
            halign = "center",
            rotate = 90,
            color = "red",
            textAlignment = "center",
            text = "NAV PANEL",
        }
    }
end

--- The panel for showing information about kits or the selected kit
--- @return Panel
function CBKitDetail._overviewPanel()

    local nameLabel = gui.Label{
        classes = {"builder-base", "label", "info", "header"},
        width = "100%",
        height = "auto",
        hpad = 12,
        text = "KIT",
        textAlignment = "left",

        refreshBuilderState = function(element, state)
            -- TODO: Selected kit name
        end
    }

    local introLabel = gui.Label{
        classes = {"builder-base", "label", "info"},
        width = "100%",
        height = "auto",
        vpad = 6,
        hpad = 12,
        bmargin = 12,
        textAlignment = "left",
        markdown = true,
        text = CharacterBuilder.STRINGS.KIT.INTRO,

        refreshBuilderState = function(element, state)
            local text = CharacterBuilder.STRINGS.KIT.INTRO
            -- TODO: Selected kit description
            element.text = text
        end,
    }

    local detailLabel = gui.Label{
        classes = {"builder-base", "label", "info"},
        width = "100%",
        height = "auto",
        vpad = 6,
        hpad = 12,
        tmargin = 12,
        textAlignment = "left",
        bold = false,
        markdown = true,
        text = CharacterBuilder.STRINGS.KIT.OVERVIEW,

        refreshBuilderState = function(element, state)
            local text = CharacterBuilder.STRINGS.KIT.OVERVIEW
            -- TODO: Selected kit detail
            element.text = text
        end
    }

    return gui.Panel{
        id = "kitOverviewPanel",
        classes = {"kitOverviewPanel", "builder-base", "panel-base", "detail-overview-panel", "border"},
        bgimage = mod.images.kitHome,

        refreshBuilderState = function(element, state)
        end,

        gui.Panel{
            width = "100%-2",
            height = "auto",
            valign = "bottom",
            vmargin = 32,
            flow = "vertical",
            bgimage = true,
            vpad = 8,
            nameLabel,
            introLabel,
            detailLabel,
        }
    }
end

--- @return PrettyButton|Panel
function CBKitDetail._selectButton()
    return CharacterBuilder._makeSelectButton{
        classes = {"selectButton"},
        press = function(element)
        end,
        refreshBuilderState = function(element, state)
        end,
    }
end

--- The right side panel for the kit editor
--- @return Panel
function CBKitDetail._detailPanel()

    local overviewPanel = CBKitDetail._overviewPanel()

    local selectButton = CBKitDetail._selectButton()

    return gui.Panel{
        id = "classDetailPanel",
        classes = {"builder-base", "panel-base", "inner-detail-panel", "wide", "classDetailpanel"},

        refreshBuilderState = function(element, state)
        end,

        overviewPanel,
        selectButton,
    }
end

--- The main panel for working with kits
--- @return Panel
function CBKitDetail.CreatePanel()

    local navPanel = CBKitDetail._navPanel()

    local detailPanel = CBKitDetail._detailPanel()

    return gui.Panel{
        id = "classPanel",
        classes = {"builder-base", "panel-base", "detail-panel", "classPanel"},
        data = {
            selector = SELECTOR,
            features = {},
        },

        refreshBuilderState = function(element, state)
        end,

        navPanel,
        detailPanel,
    }
end