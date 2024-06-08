local Werewolf = {}
local BEEFY_WOLF_PROBABILITY = 0.5
local FAST_WOLF_PROBABILITY = 0.3

Werewolf.__index = Werewolf

-- Constructor de la clase
function Werewolf:new(sprites)
    -- Creamos una nueva tabla que representara la instancia
    local instance = setmetatable({}, Werewolf)
    
    -- Inicializamos las propiedades de la instancia
    instance.x = math.random(0, love.graphics.getWidth())
    instance.y = math.random(0, love.graphics.getHeight())
    instance.speed = 120
    instance.health = 10
    instance.scaleFactor=0.11
    instance.score = 20
    instance.dead = false
    instance.damage = 1
    instance.sprite = sprites.defaultWolf
    

    if is_fast_wolf() then
        instance.speed = 200
        instance.score = 40
        instance.damage = 3
        instance.sprite = sprites.fastWolf
    end

    if is_beefy_wolf() then
        instance.health = 50
        instance.scaleFactor = 0.1
        instance.speed = 100
        instance.score = 60
        instance.damage = 4
        instance.sprite = sprites.beefyWolf
    end
    
    -- Retornamos la instancia
    return instance
end

function is_beefy_wolf()
    return math.random() < BEEFY_WOLF_PROBABILITY
end

function is_fast_wolf()
    return math.random() < FAST_WOLF_PROBABILITY
end

function Werewolf:get_damage()
    return self.damage
end

function Werewolf:take_damage(aDamage, score, bloodParticles)
    self.health = self.health - aDamage
    if (self.health <= 0) then
        self.dead = true
        score.total = score.total + self.score
        bloodParticles:setPosition(self.x, self.y)
        bloodParticles:emit(32)
    end
end

return Werewolf