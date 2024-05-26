local Werewolf = {}
Werewolf.__index = Werewolf

-- Constructor de la clase
function Werewolf:new()
    -- Creamos una nueva tabla que representará la instancia
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
    
    -- Retornamos la instancia
    return instance
end

-- método de la clase
function Werewolf:myMethod()
    print("Property1: " .. self.posicionX)
    print("Property2: " .. self.posicionY)
end

return Werewolf