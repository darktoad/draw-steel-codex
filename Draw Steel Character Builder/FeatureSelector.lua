--[[
    Selector panels
]]
CBFeatureSelector = RegisterGameType("CBFeatureSelector")

local _characterHasLevelChoice = CharacterBuilder._characterHasLevelChoice
local _fireControllerEvent = CharacterBuilder._fireControllerEvent
local _getHero = CharacterBuilder._getHero

--- Build a feature panel with selections
--- @return Panel|nil
function CBFeatureSelector.Panel(feature)
    -- print("THC:: FEATUREPANEL::", feature)
    -- print("THC:: FEATUREPANEL::", json(feature))

    local typeName = feature.typeName or ""
    if typeName == "CharacterDeityChoice" then
    elseif typeName == "CharacterFeatChoice" then
        return CBFeatureSelector.PerkPanel(feature)
    elseif typeName == "CharacterFeatureChoice" then
        return CBFeatureSelector.FeaturePanel(feature)
    elseif typeName == "CharacterLanguageChoice" then
        return CBFeatureSelector.LanguagePanel(feature)
    elseif typeName == "CharacterSkillChoice" then
        return CBFeatureSelector.SkillPanel(feature)
    elseif typeName == "CharacterSubclassChoice" then
    elseif typeName == "CharacterAncestryInheritanceChoice" then
        return CBFeatureSelector.AncestryInheritancePanel(feature)
    end

    return nil
end

--- Render a feature choice panel
--- @param feature CharacterFeatureChoice
--- @return Panel
function CBFeatureSelector.FeaturePanel(feature)

    local function findOptionByGuid(guid, hero)
        local levelChoices = hero:GetLevelChoices()
        for _,option in ipairs(feature:GetOptions(levelChoices)) do
            if option.guid == guid then
                return option
            end
        end
        return nil
    end

    local function formatOptionName(option)
        local s = option.name
        local pointCost = option:try_get("pointsCost")
        if pointCost then
            s = string.format("%s (%d point%s)", s, pointCost, pointCost ~= 1 and "s" or "")
        end
        return s
    end

    local function createTargetPanel(i)
        return gui.Panel{
            classes = {"builder-base", "panel-base", "feature-target", "empty"},
            data = {
                featureGuid = feature.guid,
                costsPoints = feature:try_get("costsPoints", false),
                itemIndex = i,
                selectedItem = nil,
            },
            click = function(element)
                _fireControllerEvent(element, "removeLevelChoice", {
                    levelChoiceGuid = element.data.featureGuid,
                    selectedId = element.data.selectedItem.guid,
                })
            end,
            linger = function(element)
                if element.data.selectedId then
                    gui.Tooltip("Press to delete")(element)
                end
            end,
            refreshBuilderState = function(element, state)
                local numChoices = element.parent.data.numChoices or 1
                if element.data.itemIndex > numChoices then
                    element:SetClass("collapsed", true)
                    return
                end
                element:SetClass("collapsed", false)

                element.data.selectedItem = nil
                local newText = "Empty Slot"
                local newDesc = ""
                local hero = _getHero(state)
                if hero then
                    local levelChoices = hero:GetLevelChoices()
                    if levelChoices then
                        local selectedItems = levelChoices[element.data.featureGuid]
                        if selectedItems and #selectedItems >= element.data.itemIndex then
                            local selectedId = selectedItems[element.data.itemIndex]
                            if selectedId then
                                local option = findOptionByGuid(selectedId, hero)
                                if option then
                                    element.data.selectedItem = option
                                    newText = formatOptionName(option)
                                    newDesc = option.description
                                end
                            end
                        end
                    end
                end
                element:FireEventTree("updateName", newText)
                element:FireEventTree("updateDesc", newDesc)
                element:SetClass("filled", element.data.selectedItem ~= nil)
                element:FireEvent("setVisibility")
            end,
            setVisibility = function(element)
                local visible = true
                local numChoices = element.parent.data.numChoices or 1
                if element.data.costsPoints and element.data.selectedItem == nil then
                    local container = element.parent
                    if container then
                        local pointsSelected = 0
                        for _,child in ipairs(container.children) do
                            local selectedItem = child.data and child.data.selectedItem
                            if selectedItem then
                                pointsSelected = pointsSelected + selectedItem:try_get("pointsCost", 1)
                            end
                        end
                        visible = pointsSelected < numChoices
                    end
                end
                element:SetClass("collapsed-anim", not visible)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-target"},
                text = "Empty Slot",
                updateName = function(element, text)
                    element.text = text
                end,
            },
            gui.Label{
                classes = {"builder-base", "label", "feature-target", "desc"},
                updateDesc = function(element, text)
                    element.text = text
                end,
            }
        }
    end

    local targetsContainer = gui.Panel{
        classes = {"builder-base", "panel-base", "container"},
        flow = "vertical",
        data = {
            builtTargets = 0,
            numChoices = 1,
        },
        refreshBuilderState = function(element, state)
            local hero = _getHero(state)
            if not hero then return end

            local numChoices = feature:NumChoices(hero)
            element.data.numChoices = numChoices

            for i = element.data.builtTargets + 1, numChoices do
                element:AddChild(createTargetPanel(i))
                element.data.builtTargets = i
            end
        end,
    }

    local function createOptionPanel(option)
        return gui.Panel{
            classes = {"builder-base", "panel-base", "feature-choice"},
            data = {
                id = feature.guid,
                item = option,
            },
            click = function(element)
                local parent = element:FindParentWithClass("featureSelector")
                if parent then
                    parent:FireEvent("selectItem", element.data.item.guid)
                end
            end,
            refreshBuilderState = function(element, state)
                local hero = _getHero(state)
                if hero then
                    element:SetClass("collapsed", _characterHasLevelChoice(hero, element.data.id, element.data.item.guid))
                end
            end,
            refreshSelection = function(element, selectedId)
                element:SetClass("selected", selectedId == element.data.item.guid)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-choice"},
                text = formatOptionName(option)
            },
            gui.Label{
                classes = {"builder-base", "label", "feature-choice", "desc"},
                textAlignment = "left",
                text = option.description
            },
        }
    end

    local optionsContainer = gui.Panel{
        classes = {"builder-base", "panel-base", "container"},
        flow = "vertical",
        data = {
            builtOptions = {},
        },
        refreshBuilderState = function(element, state)
            local hero = _getHero(state)
            if not hero then return end

            local levelChoices = hero:GetLevelChoices()
            local currentOptions = feature:GetOptions(levelChoices)

            -- Mark existing as stale
            for guid, _ in pairs(element.data.builtOptions) do
                element.data.builtOptions[guid] = false
            end

            -- Add new / mark current
            for _, option in ipairs(currentOptions) do
                if element.data.builtOptions[option.guid] == nil then
                    element:AddChild(createOptionPanel(option))
                end
                element.data.builtOptions[option.guid] = true
            end

            -- Remove stale
            for guid, active in pairs(element.data.builtOptions) do
                if active == false then
                    local child = element:FindChildRecursive(function(e)
                        return e.data and e.data.item and e.data.item.guid == guid
                    end)
                    if child then child:DestroySelf() end
                    element.data.builtOptions[guid] = nil
                end
            end
            
            local children = element.children
            table.sort(children, function(a,b) return a.data.item.name < b.data.item.name end)
            element.children = children
        end,
    }

    return CBFeatureSelector._mainPanel(feature, targetsContainer, optionsContainer)
end

--- Render a language choice panel
--- @param feature CharacterLanguageChoice
--- @return Panel
function CBFeatureSelector.LanguagePanel(feature)

    local candidateItems = Language.GetDropdownList()

    -- Selection targets
    local targets = {}
    local numChoices = feature:NumChoices(character)
    for i = 1, numChoices do
        targets[#targets+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-target", "empty"},
            data = {
                featureGuid = feature.guid,
                itemIndex = i,
                selectedItem = nil,
            },
            click = function(element)
                _fireControllerEvent(element, "removeLevelChoice", {
                    levelChoiceGuid = element.data.featureGuid,
                    selectedId = element.data.selectedItem.id,
                })
            end,
            linger = function(element)
                if element.data.selectedId then
                    gui.Tooltip("Press to delete")(element)
                end
            end,
            refreshBuilderState = function(element, state)
                element.data.selectedItem = nil
                local newText = "Empty Slot"
                local hero = _getHero(state)
                if hero then
                    local levelChoices = hero:GetLevelChoices()
                    if levelChoices then
                        local selectedItems = levelChoices[element.data.featureGuid]
                        if selectedItems and #selectedItems >= element.data.itemIndex then
                            local selectedId = selectedItems[element.data.itemIndex]
                            if selectedId then
                                local item = dmhub.GetTableVisible(Language.tableName)[selectedId]
                                if item then
                                    element.data.selectedItem = item
                                    newText = item.name
                                end
                            end
                        end
                    end
                end
                element:FireEventTree("updateText", newText)
                element:SetClass("filled", element.data.selectedItem ~= nil)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-target"},
                text = "Empty Slot",
                updateText = function(element, text)
                    element.text = text
                end,
            }
        }
    end

    -- Candidate items
    local options = {}
    for _,item in ipairs(candidateItems) do
        options[#options+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-choice"},
            valign = "top",
            data = {
                id = item.id,
                item = item,
            },
            click = function(element)
                local parent = element:FindParentWithClass("featureSelector")
                if parent then
                    parent:FireEvent("selectItem", element.data.id)
                end
            end,
            refreshBuilderState = function(element, state)
                local hero = _getHero(state)
                if hero then
                    local langsKnown = hero:LanguagesKnown()
                    if langsKnown then
                        element:SetClass("collapsed", langsKnown[element.data.id])
                    end
                end
            end,
            refreshSelection = function(element, selectedId)
                element:SetClass("selected", selectedId == element.data.id)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-choice"},
                text = item.text,
            }
        }
    end

    local targetsContainer = CBFeatureSelector._containerPanel(targets)
    local optionsContainer = CBFeatureSelector._containerPanel(options)
    return CBFeatureSelector._mainPanel(feature, targetsContainer, optionsContainer)
end

--- Render a language choice panel
--- @param feature CharacterFeatChoice
--- @return Panel
function CBFeatureSelector.PerkPanel(feature)

    local candidateItems = {}
    local includeTags = {}
    for tag in feature.tag:gmatch("[^,]+") do
        tag = tag:match("^%s*(.-)%s*$")
        includeTags[tag:lower()] = true
    end
    local perks = dmhub.GetTableVisible(CharacterFeat.tableName)
    for id,item in pairs(perks) do
        if includeTags[item.tag:lower()] then
            candidateItems[#candidateItems+1] = {
                id = id,
                item = item
            }
        end
    end
    table.sort(candidateItems, function(a,b) return a.item.name < b.item.name end)

    -- Selection targets
    local targets = {}
    local numChoices = feature:NumChoices(character)
    for i = 1, numChoices do
        targets[#targets+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-target", "empty"},
            data = {
                featureGuid = feature.guid,
                itemIndex = i,
                selectedItem = nil,
            },
            click = function(element)
                _fireControllerEvent(element, "removeLevelChoice", {
                    levelChoiceGuid = element.data.featureGuid,
                    selectedId = element.data.selectedItem.id,
                })
            end,
            linger = function(element)
                if element.data.selectedId then
                    gui.Tooltip("Press to delete")(element)
                end
            end,
            refreshBuilderState = function(element, state)
                element.data.selectedItem = nil
                local newText = "Empty Slot"
                local newDesc = ""
                local hero = _getHero(state)
                if hero then
                    local levelChoices = hero:GetLevelChoices()
                    if levelChoices then
                        local selectedItems = levelChoices[element.data.featureGuid]
                        if selectedItems and #selectedItems >= element.data.itemIndex then
                            local selectedId = selectedItems[element.data.itemIndex]
                            if selectedId then
                                local item = dmhub.GetTableVisible(CharacterFeat.tableName)[selectedId]
                                if item then
                                    element.data.selectedItem = item
                                    newText = item.name
                                    newDesc = item.description
                                end
                            end
                        end
                    end
                end
                element:FireEventTree("updateText", newText)
                element:FireEventTree("updateDesc", newDesc)
                element:SetClass("filled", element.data.selectedItem ~= nil)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-target"},
                text = "Empty Slot",
                updateText = function(element, text)
                    element.text = text
                end,
            },
            gui.Label{
                classes = {"builder-base", "label", "feature-target", "desc"},
                updateDesc = function(element, text)
                    element.text = text
                end,
            },
        }
    end

    -- Candidate items
    local options = {}
    for _,item in ipairs(candidateItems) do
        options[#options+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-choice"},
            valign = "top",
            data = {
                id = item.id,
                item = item.item,
            },
            click = function(element)
                local parent = element:FindParentWithClass("featureSelector")
                if parent then
                    parent:FireEvent("selectItem", element.data.id)
                end
            end,
            refreshBuilderState = function(element, state)
                local cachedPerks = state:Get("cachedPerks")
                if cachedPerks then
                    element:SetClass("collapsed", cachedPerks[element.data.id])
                end
            end,
            refreshSelection = function(element, selectedId)
                element:SetClass("selected", selectedId == element.data.id)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-choice"},
                text = item.item.name,
            },
            gui.Label{
                classes = {"builder-base", "label", "feature-choice", "desc"},
                textAlignment = "left",
                text = item.item.description
            },
        }
    end

    local targetsContainer = CBFeatureSelector._containerPanel(targets)
    local optionsContainer = CBFeatureSelector._containerPanel(options)
    return CBFeatureSelector._mainPanel(feature, targetsContainer, optionsContainer)
end

--- Render a skill choice panel
--- @param feature CharacterSkillChoice
--- @return Panel
function CBFeatureSelector.SkillPanel(feature)

    local candidateItems = {}
    local categories = feature:try_get("categories", {})
    local individual = feature:try_get("individual", {})
    if (categories and next(categories)) or (individual and next(individual)) then
        local skills = dmhub.GetTableVisible(Skill.tableName)
        for key,item in pairs(skills) do
            if (individual and individual[key]) or (categories and categories[item.category]) then
                candidateItems[#candidateItems+1] = item
            end
        end
        table.sort(candidateItems, function(a,b) return a.name < b.name end)
    else
        candidateItems = Skill.skillsDropdownOptions
    end

    -- Selection targets
    local targets = {}
    local numChoices = feature:NumChoices(character)
    for i = 1, numChoices do
        targets[#targets+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-target", "empty"},
            data = {
                featureGuid = feature.guid,
                itemIndex = i,
                selectedItem = nil,
            },
            click = function(element)
                _fireControllerEvent(element, "removeLevelChoice", {
                    levelChoiceGuid = element.data.featureGuid,
                    selectedId = element.data.selectedItem.id,
                })
            end,
            linger = function(element)
                if element.data.selectedId then
                    gui.Tooltip("Press to delete")(element)
                end
            end,
            refreshBuilderState = function(element, state)
                element.data.selectedItem = nil
                local newText = "Empty Slot"
                local hero = _getHero(state)
                if hero then
                    local levelChoices = hero:GetLevelChoices()
                    if levelChoices then
                        local selectedItems = levelChoices[element.data.featureGuid]
                        if selectedItems and #selectedItems >= element.data.itemIndex then
                            local selectedId = selectedItems[element.data.itemIndex]
                            if selectedId then
                                local item = dmhub.GetTableVisible(Skill.tableName)[selectedId]
                                if item then
                                    element.data.selectedItem = item
                                    newText = item.name
                                end
                            end
                        end
                    end
                end
                element:FireEventTree("updateText", newText)
                element:SetClass("filled", element.data.selectedItem ~= nil)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-target"},
                text = "Empty Slot",
                updateText = function(element, text)
                    element.text = text
                end,
            }
        }
    end

    -- Candidate items
    local options = {}
    for _,item in ipairs(candidateItems) do
        options[#options+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-choice"},
            valign = "top",
            data = {
                id = item.id,
                item = item,
            },
            click = function(element)
                local parent = element:FindParentWithClass("featureSelector")
                if parent then
                    parent:FireEvent("selectItem", element.data.id)
                end
            end,
            refreshBuilderState = function(element, state)
                local hero = _getHero(state)
                if hero then
                    element:SetClass("collapsed", hero:ProficientInSkill(element.data.item))
                end
            end,
            refreshSelection = function(element, selectedId)
                element:SetClass("selected", selectedId == element.data.id)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-choice"},
                text = item.name,
            }
        }
    end

    local targetsContainer = CBFeatureSelector._containerPanel(targets)
    local optionsContainer = CBFeatureSelector._containerPanel(options)
    return CBFeatureSelector._mainPanel(feature, targetsContainer, optionsContainer)
end

--- Render an ancestry inheritance choice panel (e.g., for Revenant's "former ancestry")
--- @param feature CharacterAncestryInheritanceChoice
--- @return Panel
function CBFeatureSelector.AncestryInheritancePanel(feature)

    local candidateItems = feature:Choices(1, {}, nil)

    -- Selection targets
    local targets = {}
    local numChoices = feature:NumChoices(character)
    for i = 1, numChoices do
        targets[#targets+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-target", "empty"},
            data = {
                featureGuid = feature.guid,
                itemIndex = i,
                selectedItem = nil,
            },
            click = function(element)
                _fireControllerEvent(element, "removeLevelChoice", {
                    levelChoiceGuid = element.data.featureGuid,
                    selectedId = element.data.selectedItem.id,
                })
            end,
            linger = function(element)
                if element.data.selectedId then
                    gui.Tooltip("Press to delete")(element)
                end
            end,
            refreshBuilderState = function(element, state)
                element.data.selectedItem = nil
                local newText = "Empty Slot"
                local hero = _getHero(state)
                if hero then
                    local levelChoices = hero:GetLevelChoices()
                    if levelChoices then
                        local selectedItems = levelChoices[element.data.featureGuid]
                        if selectedItems and #selectedItems >= element.data.itemIndex then
                            local selectedId = selectedItems[element.data.itemIndex]
                            if selectedId then
                                local item = dmhub.GetTableVisible(Race.tableName)[selectedId]
                                if item then
                                    element.data.selectedItem = item
                                    newText = item.name
                                end
                            end
                        end
                    end
                end
                element:FireEventTree("updateText", newText)
                element:SetClass("filled", element.data.selectedItem ~= nil)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-target"},
                text = "Empty Slot",
                updateText = function(element, text)
                    element.text = text
                end,
            }
        }
    end

    -- Candidate items
    local options = {}
    for _,item in ipairs(candidateItems) do
        options[#options+1] = gui.Panel{
            classes = {"builder-base", "panel-base", "feature-choice"},
            valign = "top",
            data = {
                id = item.id,
                text = item.text,
            },
            click = function(element)
                local parent = element:FindParentWithClass("featureSelector")
                if parent then
                    parent:FireEvent("selectItem", element.data.id)
                end
            end,
            refreshBuilderState = function(element, state)
                local hero = _getHero(state)
                if hero then
                    local levelChoices = hero:GetLevelChoices()
                    if levelChoices then
                        local selectedItems = levelChoices[feature.guid]
                        local alreadySelected = false
                        if selectedItems then
                            for _, selectedId in ipairs(selectedItems) do
                                if selectedId == element.data.id then
                                    alreadySelected = true
                                    break
                                end
                            end
                        end
                        element:SetClass("collapsed", alreadySelected)
                    end
                end
            end,
            refreshSelection = function(element, selectedId)
                element:SetClass("selected", selectedId == element.data.id)
            end,
            gui.Label{
                classes = {"builder-base", "label", "feature-choice"},
                text = item.text,
            }
        }
    end

    local targetsContainer = CBFeatureSelector._containerPanel(targets)
    local optionsContainer = CBFeatureSelector._containerPanel(options)
    return CBFeatureSelector._mainPanel(feature, targetsContainer, optionsContainer)
end

--- Build a consistent list of targets and children
--- @param feature table
--- @param targetsContainer Panel The container panel for targets
--- @param optionsContainer Panel The container panel for options
--- @return table children
function CBFeatureSelector._buildChildren(feature, targetsContainer, optionsContainer)
    local children = {}

    children[#children+1] = gui.Label {
        classes = {"builder-base", "label", "feature-header", "name"},
        text = feature.name,
    }

    children[#children+1] = gui.Label {
        classes = {"builder-base", "label", "feature-header", "desc"},
        text = feature:GetDescription(),
    }

    children[#children+1] = targetsContainer

    children[#children+1] = gui.MCDMDivider{
        classes = {"builder-divider"},
        layout = "v",
        width = "96%",
        vpad = 4,
        bgcolor = CBStyles.COLORS.GOLD,
    }

    children[#children+1] = optionsContainer

    return children
end

--- Build a consistent main panel
--- @param feature table
--- @param targetsContainer Panel The container panel for targets
--- @param optionsContainer Panel The container panel for options
--- @return Panel
function CBFeatureSelector._mainPanel(feature, targetsContainer, optionsContainer)

    local children = CBFeatureSelector._buildChildren(feature, targetsContainer, optionsContainer)

    local scrollPanel = CBFeatureSelector._scrollPanel(children)

    local selectButton = CharacterBuilder._makeSelectButton{
        click = function(element)
            local parent = element:FindParentWithClass("featureSelector")
            if parent then
                parent:FireEvent("applyCurrentItem")
            end
        end,
        refreshBuilderState = function(element, state)
            -- TODO:
        end,
    }

    return gui.Panel{
        classes = {"featureSelector", "builder-base", "panel"},
        width = "100%",
        height = "100%",
        halign = "left",
        flow = "vertical",

        data = {
            feature = feature,
            selectedId = nil,   -- The item currently selected in the options list
        },

        applyCurrentItem = function(element)
            if element.data.selectedId then
                _fireControllerEvent(element, "applyLevelChoice", {
                    feature = feature,
                    selectedId = element.data.selectedId
                })
            end
        end,

        selectItem = function(element, itemId)
            element.data.selectedId = itemId
            element:FireEventTree("refreshSelection", itemId)
        end,

        scrollPanel,
        gui.MCDMDivider{
            classes = {"builder-divider"},
            layout = "line",
            width = "96%",
            vpad = 4,
            bgcolor = "white"
        },
        selectButton,
    }
end

--- Build a container panel for the list of targets or options
--- @param children table The list of child elements
--- @return Panel
function CBFeatureSelector._containerPanel(children)
    return gui.Panel{
        classes = {"builder-base", "panel-base", "container"},
        flow = "vertical",
        children = children,
    }
end

--- Build a consistent scrollable panel for choices
--- @param children table The list of child elements to scroll
--- @return Panel
function CBFeatureSelector._scrollPanel(children)
    return gui.Panel {
        classes = {"builder-base", "panel-base"},
        width = "100%",
        height = "100%-60",
        halign = "left",
        valign = "top",
        flow = "vertical",
        vscroll = true,
        gui.Panel{
            classes = {"builder-base", "panel-base", "container"},
            flow = "vertical",
            children = children,
        },
    }
end