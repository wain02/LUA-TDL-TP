local Player = {}
local INITIAL_VELOCITY = 500
local INITIAL_HP = 10
local INVULNERABILITY_TIME = 0.4
local INITIAL_DAMAGE = 10
Player.__index = Player

function Player:new(sprite)
    local instance = setmetatable({}, Player)

    instance.sprite = sprite
    instance.x = love.graphics.getWidth() / 2
    instance.y = love.graphics.getHeight() / 2
    instance.speed = INITIAL_VELOCITY
    instance.invulnerabilityTime = 0
    instance.hp = INITIAL_HP
    instance.damage = INITIAL_DAMAGE
    instance.orientation = 0
    instance.canTakeDamage = true

    return instance
end

function Player:take_damage(aWolf)
    if (self.canTakeDamage) then
        self.invulnerabilityTime = INVULNERABILITY_TIME
        self.hp = (self.hp) - aWolf:get_damage()
        self.canTakeDamage = false
        self.speed = (INITIAL_VELOCITY)*1.5
        playHitSound(hitSounds)
    end
end

function Player:refresh_invulnerability(tiempo)
    if self.invulnerabilityTime > 0 then
        self.invulnerabilityTime = self.invulnerabilityTime - tiempo
    else
        if not self.canTakeDamage then
            self.canTakeDamage = true
            self.invulnerabilityTime = 0
            self.speed = INITIAL_VELOCITY
        end
    end
end

function Player:set_orientation(newOrientation)
    self.orientation = newOrientation
end

function Player:can_take_damage()
    return self.canTakeDamage
end

function Player:get_hp()
    return self.hp
end

function Player:is_dead()
    return ( (self.get_hp(self)) <= 0)
end

function Player:refill_hp()
    self.hp = INITIAL_HP
end

return Player