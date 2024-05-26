local Rifle = {}
Rifle.__index = Rifle

-- Constructor de la clase
function Rifle:new()
    -- Creamos una nueva tabla que representará la instancia
    local instance = setmetatable({}, Rifle)
    
    -- Inicializamos las propiedades de la instancia
    instance.x = math.random(0, love.graphics.getWidth())
    instance.y = math.random(0, love.graphics.getHeight())
    instance.timer = 10
    instance.damage = 10
    machineGun.dead = false

    -- Retornamos la instancia
    return instance
end

-- método de la clase
function Rifle:myMethod()
    print("Property1: " .. self.posicionX)
    print("Property2: " .. self.posicionY)
end

return Rifle

