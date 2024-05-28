local Rifle = {}
Rifle.__index = Rifle
local rifleTimer = 0
-- Constructor de la clase
function Rifle:new(sprite)
    -- Creamos una nueva tabla que representará la instancia
    local instance = setmetatable({}, Rifle)

    -- Inicializamos las propiedades de la instancia
    instance.x = math.random(0, love.graphics.getWidth())
    instance.y = math.random(0, love.graphics.getHeight())
    instance.damage = 10
    instance.dead = false
    instance.spawned = true
    instance.type = "Rifle"
    instance.sprite = sprite


    -- Retornamos la instancia
    return instance
end

-- método de la clase
function Rifle:myMethod()
    print("Property1: " .. self.posicionX)
    print("Property2: " .. self.posicionY)
end


function Rifle:restarTiempo(dt)
    self.timer = self.timer - dt
    return self.timer
end


return Rifle, rifleTimer




