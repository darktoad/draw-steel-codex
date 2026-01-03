--[[
    Kit detail / selectors
    mcdmkitbuilder.lua
]]
CBKitDetail = RegisterGameType("CBKitDetail")

local mod = dmhub.GetModLoading()

local SELECTOR = CharacterBuilder.SELECTOR.KIT

local _fireControllerEvent = CharacterBuilder._fireControllerEvent
local _getHero = CharacterBuilder._getHero

function CBKitDetail._navPanel()
    -- TODO: Maybe put inside another panel to shrink vertically.
    return gui.Panel{
        classes = {"categoryNavPanel", "builder-base", "panel-base", "detail-nav-panel"},
        vscroll = true,

        data = {
            classId = nil,
        },

        refreshBuilderState = function(element, state)
            local classId = state:Get(CharacterBuilder.SELECTOR.CLASS .. ".selectedId")
            if classId ~= element.data.classId then
                for i = #element.children, 1, -1 do
                    element.children[i]:DestroySelf()
                end
            end

            if #element.children == 0 then
                if classId ~= nil then
                    local featureCache = state:Get(SELECTOR .. ".featureCache")
                    if featureCache ~= nil then
                        local feature = featureCache:GetFeature(classId)
                        if feature ~= nil then
                            element:AddChild(CBFeatureSelector.SelectionPanel(SELECTOR, feature))
                        end
                    end
                end
            end
        end,
    }
end

--- The panel for showing information about kits or the selected kit
--- @return Panel
function CBKitDetail._overviewPanel()

    local nameLabel = gui.Label{
        classes = {"builder-base", "label", "info", "overview", "header"},
        text = "KIT",

        updateSelectedKit = function(element, kitItem)
            element.text = kitItem and kitItem.name or "KIT"
        end,
    }

    local kitTypeLabel = gui.Label{
        classes = {"builder-base", "label", "info", "overview", "collapsed"},
        updateSelectedKit = function(element, kitItem)
            local text = ""
            if kitItem then
                for _,t in ipairs(Kit.kitTypes) do
                    if t.id == kitItem.type then
                        text = string.format("%s Kit", t.text)
                        break
                    end
                end
            end
            element.text = text
            element:SetClass("collapsed", #text == 0)
        end,
    }

    local introLabel = gui.Label{
        classes = {"builder-base", "label", "info", "overview"},
        vpad = 6,
        bmargin = 12,
        markdown = true,
        text = CharacterBuilder.STRINGS.KIT.INTRO,

        updateSelectedKit = function(element, kitItem)
            local text = CharacterBuilder.STRINGS.KIT.INTRO
            text = kitItem and kitItem.description or text
            element.text = text
        end,
    }

    local equipmentPanel = gui.Panel{
        classes = {"builder-base", "panel-base", "container"},
        updateSelectedKit = function(element, kitItem)
            local visible = kitItem ~= nil
            element:SetClass("collapsed", not visible)
            if not visible then 
                element:HaltEventPropagation()
                return
            end
        end,
        gui.Label{
            classes = {"builder-base", "label", "info", "overview", "detail-header"},
            text = "Equipment",
        },
        gui.Label{
            classes = {"builder-base", "label", "info", "overview"},
            updateSelectedKit = function(element, kitItem)
                element.text = kitItem and kitItem.description or "No equipment description found."
            end,
        }
    }

    local detailLabel = gui.Label{
        classes = {"builder-base", "label", "info", "overview"},
        vpad = 6,
        tmargin = 12,
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

        updateSelectedKit = function(element, kitItem)
            local bgImage = mod.images.kitHome
            if kitItem and kitItem:try_get("portraitid") and #kitItem.portraitid > 0 then
                bgImage = kitItem.portraitid
            end
            if element.bgimage ~= bgImage then
                element.bgimage = bgImage
            end
            -- TODO: Overlay a dimmer color when kit selected
        end,

        gui.Panel{
            classes = {"builder-base", "panel-base", "detail-overview-labels"},
            nameLabel,
            kitTypeLabel,
            introLabel,
            equipmentPanel,
            detailLabel,
        }
    }
end

--- The right side panel for the kit editor
--- @return Panel
function CBKitDetail._detailPanel()

    local overviewPanel = CBKitDetail._overviewPanel()

    return gui.Panel{
        id = "classDetailPanel",
        classes = {"builder-base", "panel-base", "inner-detail-panel", "wide", "classDetailpanel"},

        refreshBuilderState = function(element, state)
        end,

        overviewPanel,
    }
end

--- The main panel for working with kits
--- @return Panel
function CBKitDetail.CreatePanel()

    local navPanel = CBKitDetail._navPanel()

    local detailPanel = CBKitDetail._detailPanel()

    return gui.Panel{
        id = "kitPanel",
        classes = {"builder-base", "panel-base", "detail-panel", "kitPanel"},
        data = {
            selector = SELECTOR,
            features = {},
        },

        refreshBuilderState = function(element, state)
            local visible = state:Get("activeSelector") == element.data.selector
            element:SetClass("collapsed-anim", not visible)
            if not visible then
                element:HaltEventPropagation()
                return
            end
        end,

        navPanel,
        detailPanel,
    }
end

--- CharacterKitChoice injects this into FeatureSelector. It listens
--- for the FeatureSelector's refreshBuilderState event and fires
--- a custom event back into the parent panel so we can update the
--- overview panel. We do not want to re-fire refreshBuilderState
--- because that would duplicate effort inside the child panel.
--- @return Panel
function CBKitDetail.Listener()
    return gui.Panel{
        classes = {"listener", "collapsed"},
        refreshBuilderState = function (element, state)
            local featureCache = state:Get(SELECTOR .. ".featureCache")
            if featureCache then
                local feature = featureCache:GetFeature(featureCache:GetSelectedId())
                local kitId = feature and feature:GetSelectedOptionId()
                local kitPanel = element:FindParentWithClass("kitPanel")
                local kitItem = dmhub.GetTableVisible(Kit.tableName)[kitId]
                print("THC:: KIT::", json(kitItem))
                if kitPanel then kitPanel:FireEventTree("updateSelectedKit", kitItem) end
            end
        end,
    }
end