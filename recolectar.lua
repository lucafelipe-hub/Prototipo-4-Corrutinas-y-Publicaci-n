local Recolectar = {}

local jugador, enemigo, coleccionable, balas
local puntuacion, objetivoPuntos, estadoJuego
local imagenAvion, imagenEnemigo
local sonidoCoin, sonidoDisparo, sonidoVictoria, sonidoDerrota

Recolectar.volverMenu = false

function Recolectar.load()
    imagenAvion = love.graphics.newImage("avion.png")
    imagenEnemigo = love.graphics.newImage("enemigo.png")
    
    sonidoCoin = love.audio.newSource("moneda.mp3", "static")
    sonidoDisparo = love.audio.newSource("disparo.mp3", "static")
    sonidoVictoria = love.audio.newSource("victoria.mp3", "static")
    sonidoDerrota = love.audio.newSource("derrota.mp3", "static")
end

function Recolectar.enter()
    jugador = { x = 400, y = 300, ancho = 32, alto = 32, velocidad = 250 }
    enemigo = { x = 100, y = 100, ancho = 30, alto = 30, velocidad = 90 }
    coleccionable = { x = math.random(100, 700), y = math.random(100, 500), radio = 10 }
    balas = {}
    puntuacion = 0
    objetivoPuntos = 5
    estadoJuego = "jugando"
    Recolectar.volverMenu = false
end

function Recolectar.update(dt)
    if estadoJuego ~= "jugando" then return end

    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then jugador.x = jugador.x + (jugador.velocidad * dt) end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then jugador.x = jugador.x - (jugador.velocidad * dt) end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then jugador.y = jugador.y + (jugador.velocidad * dt) end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then jugador.y = jugador.y - (jugador.velocidad * dt) end

    jugador.x = math.max(0, math.min(800 - jugador.ancho, jugador.x))
    jugador.y = math.max(0, math.min(600 - jugador.alto, jugador.y))

    if enemigo.x < jugador.x then enemigo.x = enemigo.x + (enemigo.velocidad * dt)
    elseif enemigo.x > jugador.x then enemigo.x = enemigo.x - (enemigo.velocidad * dt) end
    if enemigo.y < jugador.y then enemigo.y = enemigo.y + (enemigo.velocidad * dt)
    elseif enemigo.y > jugador.y then enemigo.y = enemigo.y - (enemigo.velocidad * dt) end

    for i = #balas, 1, -1 do
        local b = balas[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.x < 0 or b.x > 800 or b.y < 0 or b.y > 600 then
            table.remove(balas, i)
        else
            if b.x < enemigo.x + enemigo.ancho and b.x + b.radio > enemigo.x and
               b.y < enemigo.y + enemigo.alto and b.y + b.radio > enemigo.y then
                table.remove(balas, i)
                enemigo.x = math.random(50, 750)
                enemigo.y = math.random(50, 550)
            end
        end
    end

    -- Colisión
    if jugador.x < coleccionable.x + coleccionable.radio and
       jugador.x + jugador.ancho > coleccionable.x - coleccionable.radio and
       jugador.y < coleccionable.y + coleccionable.radio and
       jugador.y + jugador.alto > coleccionable.y - coleccionable.radio then
        puntuacion = puntuacion + 1
        if sonidoCoin then sonidoCoin:clone():play() end
        if puntuacion >= objetivoPuntos then
            estadoJuego = "ganado"
            if sonidoVictoria then sonidoVictoria:clone():play() end
        else
            coleccionable.x = math.random(50, 750)
            coleccionable.y = math.random(50, 550)
        end
    end

    -- Colisión con enemigo
    if jugador.x < enemigo.x + enemigo.ancho and
       jugador.x + jugador.ancho > enemigo.x and
       jugador.y < enemigo.y + enemigo.alto and
       jugador.y + jugador.alto > enemigo.y then
        estadoJuego = "perdido"
        if sonidoDerrota then sonidoDerrota:clone():play() end
    end
end

function Recolectar.mousepressed(x, y, button)
    if estadoJuego == "jugando" and button == 1 then
        if sonidoDisparo then sonidoDisparo:clone():play() end
        local cx = jugador.x + jugador.ancho / 2
        local cy = jugador.y + jugador.alto / 2
        local ang = math.atan2(y - cy, x - cx)
        table.insert(balas, { x = cx, y = cy, vx = math.cos(ang) * 500, vy = math.sin(ang) * 500, radio = 4 })
    elseif (estadoJuego == "ganado" or estadoJuego == "perdido") and button == 1 then
        -- 1. Botón REINICIAR
        if x >= 300 and x <= 500 and y >= 320 and y <= 370 then
            Recolectar.enter()
        -- 2. Botón VOLVER
        elseif x >= 300 and x <= 500 and y >= 390 and y <= 440 then
            Recolectar.volverMenu = true
        -- 3. Botón SALIR
        elseif x >= 300 and x <= 500 and y >= 460 and y <= 510 then
            love.event.quit()
        end
    end
end

function Recolectar.keypressed(key)
    if estadoJuego ~= "jugando" then
        if key == "r" then
            Recolectar.enter()
        elseif key == "escape" then
            Recolectar.volverMenu = true
        end
    end
end

function Recolectar.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    if estadoJuego == "jugando" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Puntuación: " .. puntuacion .. " / " .. objetivoPuntos, 20, 20)

        local scX = jugador.ancho / imagenAvion:getWidth()
        local scY = jugador.alto / imagenAvion:getHeight()
        love.graphics.draw(imagenAvion, jugador.x, jugador.y, 0, scX, scY)

        local scEnX = enemigo.ancho / imagenEnemigo:getWidth()
        local scEnY = enemigo.alto / imagenEnemigo:getHeight()
        love.graphics.draw(imagenEnemigo, enemigo.x, enemigo.y, 0, scEnX, scEnY)

        love.graphics.setColor(1, 0, 0)
        for _, b in ipairs(balas) do
            love.graphics.circle("fill", b.x, b.y, b.radio)
        end

        love.graphics.setColor(0.2, 0.9, 0.3)
        love.graphics.circle("fill", coleccionable.x, coleccionable.y, coleccionable.radio)
        love.graphics.setColor(1, 1, 1)

    elseif estadoJuego == "ganado" or estadoJuego == "perdido" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 800, 600)

        if estadoJuego == "ganado" then
            love.graphics.setColor(0, 1, 0)
            love.graphics.printf("¡HAS GANADO!", 0, 160, 800, "center")
        else
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("¡GAME OVER (DERROTA)!", 0, 160, 800, "center")
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Puntuación Final: " .. puntuacion .. " / " .. objetivoPuntos, 0, 220, 800, "center")

        -- 1. Botón REINICIAR
        love.graphics.setColor(0.1, 0.7, 0.2)
        love.graphics.rectangle("fill", 300, 320, 200, 45, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("REINICIAR", 300, 333, 200, "center")

        -- 2. Botón VOLVER
        love.graphics.setColor(0.1, 0.5, 0.8)
        love.graphics.rectangle("fill", 300, 390, 200, 45, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("VOLVER", 300, 403, 200, "center")

        -- 3. Botón SALIR
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", 300, 460, 200, 45, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SALIR", 300, 473, 200, "center")
    end
end

return Recolectar