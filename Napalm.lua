local Napalm = {}
Napalm.__index = Napalm

-- Constructor de la clase
function Napalm:new(sprite)
    -- Creamos una nueva tabla que representará la instancia
    local instance = setmetatable({}, Napalm)
    
    -- Inicializamos las propiedades de la instancia
    instance.x = math.random(0, love.graphics.getWidth())
    instance.y = math.random(0, love.graphics.getHeight())
    instance.timer = 5 
    instance.spawned = true 
    instance.type = "Napalm"
    instance.sprite = sprite
    -- Retornamos la instancia
    return instance
end

-- método de la clase
function Napalm:myMethod()
    print("Property1: " .. self.posicionX)
    print("Property2: " .. self.posicionY)
end

function Napalm:restarTiempo(dt)
    self.timer = self.timer - dt
    return self.timer
end

return Napalm