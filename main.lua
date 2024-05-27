local Werewolf = require("Werewolf")
local Rifle =  require("Rifle")
local Shotgun =  require("Shotgun")
local Napalm =  require("Napalm")

function love.load()
    math.randomseed(os.time())

    --Audio
    hitSounds = {}
    hitSounds.hit=love.audio.newSource("sounds/hit1.mp3", "static")
    hitSounds.hitTwo=love.audio.newSource("sounds/hit2.mp3", "static")
    love.audio.setVolume(0.3, hitSounds)
    powerUpSounds = {}
    powerUpSounds.wow=love.audio.newSource("sounds/wow.mp3", "static")
    love.audio.setVolume(0.5, powerUpSounds)

    -- Colores originales
    r, g, b, a = love.graphics.getColor()

    -- Cargar sprites
    sprites = {}
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.bullet = love.graphics.newImage('sprites/bullet.png')
    sprites.player = love.graphics.newImage('sprites/player.png')
    sprites.werewolf = love.graphics.newImage('sprites/werewolf.png')
    sprites.powerUps = love.graphics.newImage('sprites/powerup.png') 
    sprites.rifle = love.graphics.newImage('sprites/rifle.png') 
    sprites.napalm = love.graphics.newImage('sprites/napalm.png')

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
    -- gameState 1 es partida por comenzar
    -- gameState 2 es partida ya iniciada
    gameState = 1
    maxWerewolfTime = 2
    werewolfTimer = 2
    playerDamageTimer = 0
    score = 0
    gameTimer = 300

    rifleTimer =  5

    rifleTimer =  5
    napalmTimer = 5
    
    
end

function love.update(dt)
    handlePlayerMovement(dt)
    handleWerewolvesMovement(dt)
    handleBulletsMovement(dt)
    handleCollisions()
    despawnBullets()

    if gameState == 2 then
        if gameTimer > 0 then
            gameTimer = gameTimer - dt
        end

        if gameTimer < 0 then
            gameTimer = 0
            gameState = 1
        end

        werewolfTimer = werewolfTimer - dt

        if werewolfTimer <= 0 then
            spawnWerewolf()
            werewolfTimer = math.random(0.8, maxWerewolfTime)
            maxWerewolfTime = maxWerewolfTime * 0.9
        end

        if playerDamageTimer <= 0 and player.canTakeDmg == false then
            player.canTakeDmg = true
            playerDamageTimer = 0.2
            player.speed = velocidadOriginal
        end

        if playerDamageTimer > 0 then
            playerDamageTimer = playerDamageTimer - dt
        end


        if rifleTimer <= 0 then  
            spawnRifle(dt)
            rifleTimer  = 10
        end
        if rifleTimer > 0 then
            rifleTimer = rifleTimer - dt
        end

        if napalmTimer <= 0 then  
            spawnNapalm(dt)
            napalmTimer  = 10
        end
        if napalmTimer > 0 then
            napalmTimer = napalmTimer - dt
        end

    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)

    love.graphics.setFont(gameFont)
    love.graphics.print("HP: " .. player.hp)
    love.graphics.print("Score: ".. score, 225)
    love.graphics.print("Time: " .. math.ceil(gameTimer), 450)

    if gameState == 1 then
        love.graphics.printf("Click anywhere to begin!", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    end

    if player.canTakeDmg == false then
        love.graphics.setColor(1, 0, 0)
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
end


function love.keypressed(key)
    if key == "space" then
        spawnWerewolf()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and gameState == 2 then
        spawnBullet()
    elseif button == 1 and gameState == 1 then
        gameState = 2
        player.hp = 10
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
                player.speed = (player.speed)*1.5
                playHitSound(hitSounds)
            end

            if player.hp == 0 then
                gameState = 1
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
    bullet.dead = true
    werewolf.health = werewolf.health - bullet.damage

    if werewolf.health <= 0 then
        werewolf.dead = true
        score = score + werewolf.score
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
    -- p.sound:play()
    player.sprite = sprites.player
    player.damage = 20
    p.dead = true
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
    local shotgun = Shotgun:new()
    table.insert(powerUps, shotgun)
end

function spawnNapalm()
    local napalm = Napalm:new(sprites.napalm)
    --werewolfs = {}              --si el personaje agarra la napalm mueren los werefolfs
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
    if math.random(0,1)<0.5 then
        hitSounds.hit:play()
    else
        hitSounds.hitTwo:play()
    end
end
