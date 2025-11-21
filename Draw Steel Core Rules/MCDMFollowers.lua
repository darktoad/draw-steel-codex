local mod = dmhub.GetModLoading()

function character:GetFollowers()
    return self:try_get("followers") or {}
end

function monster:GetFollowers()
    return {}
end

function creature:IsRetainer()
    return false
end

function monster:IsRetainer()
    return self:try_get("retainer", false)
end

function creature:GetMentor()
    return
end

function monster:GetMentor()
    local token = dmhub.LookupToken(self)
    local partyMembers = dmhub.GetCharacterIdsInParty(token.partyid) or {}

    for _, charid in pairs(partyMembers) do
        local charToken = dmhub.GetTokenById(charid)
        if charToken ~= nil then
            local followers = charToken.properties:GetFollowers()
            for _, follower in ipairs(followers) do
                if follower.retainerToken == token.charid then
                    return charToken.properties
                end
            end
        end
    end

    return
end

creature.RegisterSymbol {
    symbol = "retainer",
    lookup = function(c)
        return c:IsRetainer()
    end,
    help = {
        name = "Retainer",
        type = "boolean",
        desc = "If this creature is a retainer, this will be true.",
        seealso = {},
    },
}

creature.RegisterSymbol {
    symbol = "mentor",
    lookup = function(c)
        return c:GetMentor()
    end,
    help = {
        name = "Mentor",
        type = "creature",
        desc = "The mentor of this Retainer. Only valid if Retainer is true.",
        seealso = {},
    },
}