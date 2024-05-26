local Shotgun = {}
Shotgun.__index = Shotgun

-- Constructor de la clase
function Shotgun:new()
    -- Creamos una nueva tabla que representará la instancia
    local instance = setmetatable({}, Shotgun)
    
    -- Inicializamos las propiedades de la instancia
    instance.x = math.random(0, love.graphics.getWidth())
    instance.y = math.random(0, love.graphics.getHeight())
    instance.timer = 10
    instance.damage = 5
    instance.dead = false
    


    -- Retornamos la instancia
    return instance
end

-- método de la clase
function Shotgun:myMethod()
    print("Property1: " .. self.posicionX)
    print("Property2: " .. self.posicionY)
end

function SilverBullet()
    


return {}