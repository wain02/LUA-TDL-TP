local Napalm = {}
Napalm.__index = Napalm
--local napalmTimer = 0
-- Constructor de la clase
function Napalm:new(sprite)
    -- Creamos una nueva tabla que representará la instancia
    local instance = setmetatable({}, Napalm)

    -- Inicializamos las propiedades de la instancia
    instance.x = math.random(0, love.graphics.getWidth())
    instance.y = math.random(0, love.graphics.getHeight())
    instance.spawned = true
    instance.type = "Napalm"
    instance.sprite = sprite
    instance.dead = false

    return instance
end

function Napalm:restarTiempo(dt)
    self.timer = self.timer - dt
    return self.timer
end

return Napalm, napalmTimer
