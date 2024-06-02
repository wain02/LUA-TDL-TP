local Werewolf = require("Werewolf")
local Rifle, rifleTimer =  require("Rifle")
local Shotgun, shotgunTimer =  require("Shotgun")
local Napalm, napalmTimer  =  require("Napalm")
local napalmColision = 0
local bulletShotgun = false

function love.load()
    math.randomseed(os.time())
    islandImage = love.graphics.newImage('isla.png')
    islandImageScale = 0.5
    gameState = "menu"
    currentLevel = 1

    --Audio
    hitSounds = {}
    hitSounds.hit = love.audio.newSource("sounds/hit1.mp3", "static")
    hitSounds.hitTwo = love.audio.newSource("sounds/hit2.mp3", "static")
    love.audio.setVolume(0.3, hitSounds)
    powerUpSounds = {}
    powerUpSounds.wow = love.audio.newSource("sounds/wow.mp3", "static")
    love.audio.setVolume(0.5, powerUpSounds)

    -- Colores originales
    r, g, b, a = love.graphics.getColor()

    backgroundMenu = love.graphics.newImage("isla.png")

    -- Cargar sprites
    sprites = {}
    sprites.blood = love.graphics.newImage('sprites/blood.png')
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.bullet = love.graphics.newImage('sprites/bullet.png')
    sprites.player = love.graphics.newImage('sprites/player.png')
    sprites.werewolf = love.graphics.newImage('sprites/werewolf.png')
    sprites.powerUps = love.graphics.newImage('sprites/powerup.png')
    sprites.rifle = love.graphics.newImage('sprites/rifle.png')
    sprites.napalm = love.graphics.newImage('sprites/napalm.png')
    sprites.shotgun = love.graphics.newImage('sprites/shotgun.png')

    -- Inicializar jugador
    player = {}
    velocidadOriginal = 500
    player.sprite = sprites.player
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.speed = velocidadOriginal
    player.orientation = 0
    player.hp = 10
    player.damage = 10
    player.canTakeDmg = true

    -- Inicializar listas de objetos
    werewolves = {}
    bullets = {}
    powerUps = {}

    -- Crear el sistema de part�culas de sangre
    bloodParticles = love.graphics.newParticleSystem(sprites.blood, 100)
    bloodParticles:setParticleLifetime(0.5, 1) -- Las part�culas vivir�n entre 0.5 y 1 segundos.
    bloodParticles:setLinearAcceleration(-200, -200, 200, 200) -- Aceleraci�n de las part�culas.
    bloodParticles:setSizes(0.5, 1) -- Tama�os de las part�culas.
    bloodParticles:setColors(1, 0, 0, 1, 1, 0, 0, 0) -- De rojo s�lido a transparente.

    -- Inicializar offsets para centrado de sprites
    offsets = {}
    offsets.playerX = sprites.player:getWidth() / 2
    offsets.playerY = sprites.player:getHeight() / 2
    offsets.werewolfX = sprites.werewolf:getWidth() / 2
    offsets.werewolfY = sprites.werewolf:getHeight() / 2
    offsets.bulletX = sprites.bullet:getWidth() / 2
    offsets.bulletY = sprites.bullet:getHeight() / 2

    -- Inicializar variables de juego
    gameFont = love.graphics.newFont(40)
    score = 0
    gameTimer = 300
    maxWerewolfTime = 2
    werewolfTimer = 2
    playerDamageTimer = 0
    rifleTimer = 5
    napalmTimer = 5
    explotionTimer = 1
    shotgunTimer = 5
end

function love.update(dt)
    if gameState == "playing" then
        handlePlayerMovement(dt)
        handleWerewolvesMovement(dt)
        handleBulletsMovement(dt)
        handleCollisions()
        despawnBullets()
        bloodParticles:update(dt)

        if gameTimer > 0 then
            gameTimer = gameTimer - dt
        end

        if gameTimer <= 0 then
            gameTimer = 0
            gameState = "menu"
        end

        werewolfTimer = werewolfTimer - dt

        if werewolfTimer <= 0 then
            spawnWerewolf()
            werewolfTimer = math.random(0.8, maxWerewolfTime)
            maxWerewolfTime = maxWerewolfTime * 0.9
        end

        if playerDamageTimer <= 0 and not player.canTakeDmg then
            player.canTakeDmg = true
            playerDamageTimer = 0.2
            player.speed = velocidadOriginal
        end

        if playerDamageTimer > 0 then
            playerDamageTimer = playerDamageTimer - dt
        end

        if currentLevel < 3 then
            if rifleTimer <= 0 then
                spawnRifle(dt)
                rifleTimer = 10
            end
            if rifleTimer > 0 then
                rifleTimer = rifleTimer - dt
            end
        end

        if currentLevel < 3 then
            if shotgunTimer <= 0 then
                spawnShotgun(dt)
                shotgunTimer = 5
            end
            if shotgunTimer > 0 then
                shotgunTimer = shotgunTimer - dt
            end
        end

        if currentLevel == 1 then
            if napalmTimer <= 0 then
                spawnNapalm()
                napalmTimer = 5
            end
            if napalmTimer > 0 then
                napalmTimer = napalmTimer - dt
            end
            if explotionTimer > 0 then
                explotionTimer = explotionTimer - dt
            end
        end
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.4)
    if gameState == "menu" then
        drawMenu()
    elseif gameState == "playing" then
        love.graphics.draw(sprites.background, 0, 0)

        love.graphics.setFont(gameFont)
        love.graphics.print("HP: " .. player.hp)
        love.graphics.print("Score: " .. score, 225)
        love.graphics.print("Time: " .. math.ceil(gameTimer), 450)

        if player.canTakeDmg == false then
            love.graphics.setColor(1, 0, 0)
        else
            love.graphics.setColor(r, g, b, a)
        end

        if napalmColision == 1 then
            love.graphics.setColor(1, 1, 0)
            if explotionTimer == 0 then
                love.graphics.setColor(r, g, b, a)
            end
        else
            love.graphics.setColor(r, g, b, a)
        end

        love.graphics.draw(player.sprite, player.x, player.y, player.orientation, nil, nil, offsets.playerX, offsets.playerY)

        for i, w in ipairs(werewolves) do
            love.graphics.draw(sprites.werewolf, w.x, w.y, werewolfPlayerAngle(w), w.scaleFactor, w.scaleFactor, offsets.werewolfX, offsets.werewolfY)
        end

        for i, b in ipairs(bullets) do
            love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.2, 0.2, offsets.bulletX, offsets.bulletY)
        end

        for i, p in ipairs(powerUps) do
            love.graphics.draw(p.sprite, p.x, p.y)
        end

        love.graphics.draw(bloodParticles, 0, 0) -- Dibujar las part�culas de sangre
    end
end

function drawMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(islandImage, love.graphics.getWidth() / 2 - (islandImage:getWidth() * islandImageScale) / 2, love.graphics.getHeight() / 4, 0, islandImageScale, islandImageScale)
    love.graphics.setFont(gameFont)
    love.graphics.printf("La Isla de los Lobos", 0, love.graphics.getHeight() / 4, love.graphics.getWidth(), "center")
    love.graphics.printf("Selecciona un nivel", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")

    local levelPositions = {
        {x = love.graphics.getWidth() / 2 - 150, y = love.graphics.getHeight() / 2 + 50},
        {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2 + 100},
        {x = love.graphics.getWidth() / 2 + 150, y = love.graphics.getHeight() / 2 + 200}
    }

    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Nvl 1", levelPositions[1].x - 50, levelPositions[1].y - 20, 100, "center")
    love.graphics.printf("Nvl 2", levelPositions[2].x - 50, levelPositions[2].y - 20, 100, "center")
    love.graphics.printf("Nvl 3", levelPositions[3].x - 50, levelPositions[3].y - 20, 100, "center")
end

function love.keypressed(key)
    if gameState == "menu" and key == "return" then
        gameState = "playing"
        player.hp = 10
        gameTimer = 300
    elseif gameState == "playing" then
        if key == "space" then
            spawnWerewolf()
        elseif key == "f" then
            spawnBullet()
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if gameState == "menu" then

            local levelPositions = {
                {x = love.graphics.getWidth() / 2 - 150, y = love.graphics.getHeight() / 2 + 50},
                {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2 + 100},
                {x = love.graphics.getWidth() / 2 + 150, y = love.graphics.getHeight() / 2 + 200}
            }

            if x > levelPositions[1].x - 50 and x < levelPositions[1].x + 50 and y > levelPositions[1].y - 50 and y < levelPositions[1].y + 50 then
                currentLevel = 1
            elseif x > levelPositions[2].x - 50 and x < levelPositions[2].x + 50 and y > levelPositions[2].y - 50 and y < levelPositions[2].y + 50 then
                currentLevel = 2
            elseif x > levelPositions[3].x - 50 and x < levelPositions[3].x + 50 and y > levelPositions[3].y - 50 and y < levelPositions[3].y + 50 then
                currentLevel = 3
            end
            gameState = "playing"
            player.hp = 10
        elseif gameState == "playing" then
            spawnBullet()
        end
    end
end

function handlePlayerMovement(dt)
    if (love.keyboard.isDown("d") or love.keyboard.isDown("right")) and player.x < love.graphics.getWidth() then
        player.x = player.x + player.speed * dt
    end

    if (love.keyboard.isDown("a") or love.keyboard.isDown("left")) and player.x > 0 then
        player.x = player.x - player.speed * dt
    end

    if (love.keyboard.isDown("w") or love.keyboard.isDown("up")) and player.y > 0 then
        player.y = player.y - player.speed * dt
    end

    if (love.keyboard.isDown("s") or love.keyboard.isDown("down")) and player.y < love.graphics.getHeight() then
        player.y = player.y + player.speed * dt
    end

    player.orientation = playerMouseAngle()
end

function handleWerewolvesMovement(dt)
    for i, w in ipairs(werewolves) do
        w.x = w.x + (math.cos(werewolfPlayerAngle(w)) * w.speed * dt)
        w.y = w.y + (math.sin(werewolfPlayerAngle(w)) * w.speed * dt)
    end
end

function handleBulletsMovement(dt)
    for i, b in ipairs(bullets) do
        b.x = b.x + (math.cos(b.direction) * b.speed * dt)
        b.y = b.y + (math.sin(b.direction) * b.speed * dt)
    end
end

function handleCollisions()
    for i, w in ipairs(werewolves) do
        if distanceBetween(w.x, w.y, player.x, player.y) < 10 then
            if player.canTakeDmg == true then
                player.hp = player.hp - 1
                playerDamageTimer = 0.4
                player.canTakeDmg = false
                player.speed = (player.speed) * 1.5
                playHitSound(hitSounds)
            end

            if player.hp == 0 then
                gameState = "menu"
                for i, w in ipairs(werewolves) do
                    werewolves[i] = nil
                end
            end
        end

        for j, b in ipairs(bullets) do
            if distanceBetween(w.x, w.y, b.x, b.y) < 10 then
                handleBulletWound(b, w)
            end
        end
    end

    for i, p in ipairs(powerUps) do
        if distanceBetween(player.x, player.y, p.x, p.y) < 50 then
            handlePowerUp(player, p)
            table.remove(powerUps, i)
        end
    end
end

function handleBulletWound(bullet, werewolf)
    
    if bulletShotgun == true then
        bullet.dead = false --aca la bala desaparece
    else
        bullet.dead = true --aca bala desaparece 
    end
    werewolf.health = werewolf.health - bullet.damage

    if werewolf.health <= 0 then
        werewolf.dead = true
        score = score + werewolf.score
        bloodParticles:setPosition(werewolf.x, werewolf.y)
        bloodParticles:emit(32)
    end

    for i = #werewolves, 1, -1 do
        local w = werewolves[i]
        if w.dead then
            table.remove(werewolves, i)
        end
    end

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b.dead then
            table.remove(bullets, i)
        end
    end
end

function handlePowerUp(player, p)
    if p.type == "Napalm" then
        player.sprite = sprites.player
        for i = #werewolves, 1, -1 do
            local w = werewolves[i]
            table.remove(werewolves, i)
        end
        p.dead = true
        powerUpSounds.wow:play()
        napalmColision = 1
    end

    if p.type == "Rifle" then
        player.sprite = sprites.player
        player.damage = 20
        p.dead = true
    end

    if p.type == "Shotgun" then
        player.sprite = sprites.player
        player.damage = 10
        p.dead = true
        bulletShotgun = true
    end
end

function playerMouseAngle()
    return math.atan2(love.mouse.getY() - player.y, love.mouse.getX() - player.x)
end

function werewolfPlayerAngle(werewolf)
    return math.atan2(player.y - werewolf.y, player.x - werewolf.x)
end

function spawnWerewolf()
    local werewolf = Werewolf:new()
    table.insert(werewolves, werewolf)
end

function spawnRifle()
    local rifle = Rifle:new(sprites.rifle)
    table.insert(powerUps, rifle)
end

function spawnShotgun()
    local shotgun = Shotgun:new(sprites.shotgun)
    table.insert(powerUps, shotgun)
end

function spawnNapalm()
    local napalm = Napalm:new(sprites.napalm)
    table.insert(powerUps, napalm)
end

function spawnBullet()
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.speed = 500
    bullet.direction = playerMouseAngle()
    bullet.damage = player.damage
    bullet.dead = false
    bullet.shotgun = false
    table.insert(bullets, bullet)
end

function despawnBullets()
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function playHitSound(hitSounds)
    if math.random(0, 1) < 0.5 then
        hitSounds.hit:play()
    else
        hitSounds.hitTwo:play()
    end
end
