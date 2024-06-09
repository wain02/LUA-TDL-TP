local Werewolf = require("Werewolf")
local Rifle, rifleTimer =  require("Rifle")
local Shotgun, shotgunTimer =  require("Shotgun")
local Napalm, napalmTimer  =  require("Napalm")
local Player = require("Player")
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
    sprites.powerUps = love.graphics.newImage('sprites/powerup.png')
    sprites.rifle = love.graphics.newImage('sprites/rifle.png')
    sprites.napalm = love.graphics.newImage('sprites/napalm.png')
    sprites.shotgun = love.graphics.newImage('sprites/shotgun.png')
    sprites.playershotgun = love.graphics.newImage('sprites/playershotgun.png')

    wolfSprites = {}
    wolfSprites.defaultWolfLeft = love.graphics.newImage('sprites/wolfs/defaultWolfLeft.png')
    wolfSprites.fastWolfLeft = love.graphics.newImage('sprites/wolfs/fastWolfLeft.png')
    wolfSprites.beefyWolfLeft = love.graphics.newImage('sprites/wolfs/beefyWolfLeft.png')
    wolfSprites.defaultWolfRight = love.graphics.newImage('sprites/wolfs/defaultWolfRight.png')
    wolfSprites.fastWolfRight = love.graphics.newImage('sprites/wolfs/fastWolfRight.png')
    wolfSprites.beefyWolfRight = love.graphics.newImage('sprites/wolfs/beefyWolfRight.png')

    -- Inicializar jugador
    player = Player:new(sprites.player)

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
    offsets.werewolfX = wolfSprites.defaultWolfLeft:getWidth() / 2
    offsets.werewolfY = wolfSprites.defaultWolfLeft:getHeight() / 2
    offsets.bulletX = sprites.bullet:getWidth() / 2
    offsets.bulletY = sprites.bullet:getHeight() / 2

    -- Inicializar variables de juego
    gameFont = love.graphics.newFont(40)
    score = {total = 0}
    gameTimer = 300
    maxWerewolfTime = 2
    werewolfTimer = 2
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
        handle_collisions()
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

        player:refresh_invulnerability(dt)

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
            -- napalmColision depende de explotionTimer, ARREGLAR
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
        love.graphics.print("HP: " .. player:get_hp())
        love.graphics.print("Score: " .. score.total, 225)
        love.graphics.print("Time: " .. math.ceil(gameTimer), 450)

        if not(player:can_take_damage()) then
            love.graphics.setColor(1, 0, 0)
        else
            if napalmColision == 1 then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(r, g, b, a)
            end
        end


        love.graphics.draw(player.sprite, player.x, player.y, player.orientation, nil, nil, offsets.playerX, offsets.playerY)

        for i, w in ipairs(werewolves) do
            love.graphics.draw(w:get_sprite(player), w.x, w.y, werewolfPlayerAngle(w), w:get_scalefactor(player), w:get_scalefactor(player), offsets.werewolfX, offsets.werewolfY)
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
        player:refill_hp()
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
            player:refill_hp()
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

    player:set_orientation(playerMouseAngle())
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

function kill_werewolves()
    for index, aWerewolve in ipairs(werewolves) do
        werewolves[index] = nil
    end
end

function handle_werewolves_collisions()
    for index, aWerewolve in ipairs(werewolves) do
        if distance_between(aWerewolve, player) < 10 then
            player:take_damage(aWerewolve)
            if player:is_dead() then
                gameState = "menu"
                kill_werewolves()
            end
        end

        for j, bullet in ipairs(bullets) do
            if distance_between(aWerewolve, bullet) < 15 then
                handleBulletWound(bullet, aWerewolve)
            end
        end
    end
end

function handle_powerUps_collisions()
    for index, powerUp in ipairs(powerUps) do
        if distance_between(player, powerUp) < 50 then
            handlePowerUp(player, powerUp)
            table.remove(powerUps, index)
        end
    end
end

function handle_collisions()
    handle_werewolves_collisions()
    handle_powerUps_collisions()
end

function handleBulletWound(bullet, werewolf)
    
    if bulletShotgun == true then
        bullet.dead = false --aca la bala desaparece
    else
        bullet.dead = true --aca bala desaparece 
    end
    werewolf:take_damage(bullet.damage, score, bloodParticles)

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
    -- p.sound:play()
    -- player.sprite = p.get_player_sprite()
    -- player.damage = p.get_damage()
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
        player.sprite = sprites.playershotgun
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
    werewolf = Werewolf:new(wolfSprites)
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

function distance_between(firstObject, secondObject)
    local x1 = firstObject.x
    local x2 = secondObject.x
    local y1 = firstObject.y
    local y2 = secondObject.y
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function playHitSound(hitSounds)
    if math.random(0, 1) < 0.5 then
        hitSounds.hit:play()
    else
        hitSounds.hitTwo:play()
    end
end
