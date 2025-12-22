local mod = dmhub.GetModLoading()

--- @class ActivatedAbilityCreateObjectBehavior:ActivatedAbilityBehavior
ActivatedAbilityCreateObjectBehavior = RegisterGameType("ActivatedAbilityCreateObjectBehavior", "ActivatedAbilityBehavior")

ActivatedAbilityCreateObjectBehavior.summary = 'Create Object'

ActivatedAbility.RegisterType
{
	id = 'create_object',
	text = 'Create Object',
	createBehavior = function()
		return ActivatedAbilityCreateObjectBehavior.new{
            objectid = false
		}
	end
}

function ActivatedAbilityCreateObjectBehavior:Cast(ability, casterToken, targets, options)
    local targetArea = options.targetArea
    print("CAST:: AREA:", targetArea)
    if targetArea == nil then
        return
    end

    print("CAST:: LOCATIONS:", #targetArea.locations)
    for _,loc in ipairs(targetArea.locations) do
        local targetFloor = game.currentMap:GetFloorFromLoc(loc)
        print("CAST:: TARGET FLOOR:", targetFloor)
        if targetFloor ~= nil then
            local obj = targetFloor:SpawnObjectLocal(self.objectid)
            print("CAST:: SPAWNED::", obj)
            if obj ~= nil then
                obj.x = loc.x
                obj.y = loc.y
                obj:Upload()
            print("CAST:: UPLOAD::", obj)
            else
                print("CAST:: COULD NOT CREATE OBJECT")
            end
        else
            print("CAST:: INVALID FLOOR")
        end
    end
end

function ActivatedAbilityCreateObjectBehavior:EditorItems(parentPanel)
    local panel = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
    }

    local objectOptions = {}
    for _,object in pairs(assets.allObjects) do
        local keywords = nil
        if object.components ~= nil then
            local core = object.components["CORE"]
            if core ~= nil then
                for _,field in ipairs(core.fields) do
                    if field.id == "keywords" then
                        keywords = field.currentValue
                        break
                    end
                end
            end
        end

        if keywords ~= nil and #keywords ~= 0 then
            print("KEYWORDS::", keywords)
        end
        if keywords ~= nil and table.contains(keywords, "summonable") then
            print("KEYWORDS:: SELECT", object, object.description)
            objectOptions[#objectOptions+1] = { id = object.id, text = object.description }
        end
    end

    local Refresh
    Refresh = function()
        local children = {}

    	self:ApplyToEditor(parentPanel, children)

        children[#children+1] = gui.Panel{
            classes = {"formPanel"},
            gui.Label{
                classes = {"formLabel"},
                text = "Object:",
            },
            gui.Dropdown{
                options = objectOptions,
                textDefault = "Choose Object...",
                idChosen = self.objectid,
                change = function(element)
                    self.objectid = element.idChosen
                    Refresh()
                end,
            }
        }

        panel.children = children
    end

    Refresh()

    return {panel}


end