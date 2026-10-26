local Eventos = require("eventos")

local Destruir = {}

local avion = { x = 370, y = 500, anchoVisual = 60, altoVisual = 60, velocidad = 300, vida = 100 }
local enemigos = {}
local disparos = {}
local imgAvion, imgEnemigo
local sndDisparo, sndMoneda, sndDerrota, sndVictoria
local puntos = 0
local estadoJuego = "JUGANDO"
local tiempoFlashDano = 0
local textoFeedback = "¡Usa FLECHAS para moverte y ESPACIO para disparar!"
local colorFeedback = {1, 1, 1}
local miCorrutina = nil
local temporizadorCorrutina = 0


Destruir.volverMenu = false

function Destruir.load()
    imgAvion = love.graphics.newImage("avion.png")
    imgEnemigo = love.graphics.newImage("enemigo.png")
    
    sndDisparo = love.audio.newSource("disparo.mp3", "static")
    sndMoneda = love.audio.newSource("moneda.mp3", "static")
    sndDerrota = love.audio.newSource("derrota.mp3", "static")
    sndVictoria = love.audio.newSource("victoria.mp3", "static")

    Eventos.suscribir("jugador_disparo", function()
        if sndDisparo then sndDisparo:clone():play() end
    end)

    
    Eventos.suscribir("enemigo_destruido", function(pts)
        puntos = puntos + pts
        if sndMoneda then sndMoneda:clone():play() end
        textoFeedback = "¡Enemigo destruido! +" .. pts .. " pts"
        colorFeedback = {0.2, 1, 0.2}
        if puntos >= 1000 and estadoJuego == "JUGANDO" then
            Eventos.disparar("juego_victoria")
        end
    end)

    Eventos.suscribir("jugador_dano", function(dano)
        avion.vida = math.max(0, avion.vida - dano)
        tiempoFlashDano = 0.2
        textoFeedback = "¡Impacto recibido! -" .. dano .. " HP"
        colorFeedback = {1, 0.2, 0.2}
        if avion.vida <= 0 and estadoJuego == "JUGANDO" then
            Eventos.disparar("juego_derrota")
        end
    end)

    Eventos.suscribir("juego_derrota", function()
        estadoJuego = "GAME_OVER"
        if sndDerrota then sndDerrota:clone():play() end
    end)

    Eventos.suscribir("juego_victoria", function()
        estadoJuego = "VICTORIA"
        if sndVictoria then sndVictoria:clone():play() end
    end)
end

function Destruir.enter()
    avion.x = 370
    avion.y = 500
    avion.vida = 100
    puntos = 0
    estadoJuego = "JUGANDO"
    tiempoFlashDano = 0
    textoFeedback = "¡Partida iniciada! ¡A destruir objetivos!"
    colorFeedback = {1, 1, 1}
    disparos = {}
    enemigos = {}
    Destruir.volverMenu = false

    for i = 1, 5 do
        table.insert(enemigos, { x = math.random(50, 700), y = math.random(-400, -50), velocidad = math.random(120, 220), ancho = 45, alto = 45 })
    end

    miCorrutina = coroutine.create(function()
        coroutine.yield(3)
        textoFeedback = "¡Atención: Actividad enemiga intensa!"
        colorFeedback = {1, 0.6, 0.2}
        coroutine.yield(4)
        textoFeedback = "¡Destruye los objetivos y sobrevive!"
        colorFeedback = {0.2, 1, 1}
        coroutine.yield(5)
        textoFeedback = "¡Mantén el ritmo de disparo!"
        colorFeedback = {1, 1, 1}
    end)
    temporizadorCorrutina = 0
end

function Destruir.update(dt)
    if estadoJuego ~= "JUGANDO" then return end

    if tiempoFlashDano > 0 then
        tiempoFlashDano = tiempoFlashDano - dt
    end

    if miCorrutina and coroutine.status(miCorrutina) ~= "dead" then
        temporizadorCorrutina = temporizadorCorrutina - dt
        if temporizadorCorrutina <= 0 then
            local success, tiempoEspera = coroutine.resume(miCorrutina)
            if success and type(tiempoEspera) == "number" then
                temporizadorCorrutina = tiempoEspera
            end
        end
    end

    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        avion.x = math.max(0, avion.x - avion.velocidad * dt)
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        avion.x = math.min(800 - avion.anchoVisual, avion.x + avion.velocidad * dt)
    end

    for i = #disparos, 1, -1 do
        local d = disparos[i]
        d.y = d.y - 450 * dt
        if d.y < -10 then table.remove(disparos, i) end
    end

    for i, e in ipairs(enemigos) do
        e.y = e.y + e.velocidad * dt
        if e.y > 600 then
            e.y = math.random(-200, -50)
            e.x = math.random(50, 700)
        end

        for j = #disparos, 1, -1 do
            local d = disparos[j]
            if d.x > e.x + 5 and d.x < e.x + e.ancho - 5 and d.y > e.y + 5 and d.y < e.y + e.alto - 5 then
                table.remove(disparos, j)
                e.y = math.random(-200, -50)
                e.x = math.random(50, 700)
                Eventos.disparar("enemigo_destruido", 100)
            end
        end

        local hitX = avion.x + 30
        local hitY = avion.y + 5
        local hitAncho = avion.anchoVisual - 10
        local hitAlto = avion.altoVisual - 10

        if e.x < hitX + hitAncho and e.x + e.ancho > hitX and
           e.y < hitY + hitAlto and e.y + e.alto > hitY then
            e.y = math.random(-200, -50)
            e.x = math.random(50, 700)
            Eventos.disparar("jugador_dano", 20)
        end
    end
end

function Destruir.keypressed(key)
    if estadoJuego == "JUGANDO" then
        if key == "space" then
            table.insert(disparos, { x = avion.x + (avion.anchoVisual / 2), y = avion.y })
            Eventos.disparar("jugador_disparo")
        end
    else
        if key == "r" then
            Destruir.enter()
        elseif key == "escape" then
            Destruir.volverMenu = true
        end
    end
end

function Destruir.mousepressed(x, y, button)
    if (estadoJuego == "GAME_OVER" or estadoJuego == "VICTORIA") and button == 1 then
        -- 1. Botón REINICIAR
        if x >= 300 and x <= 500 and y >= 320 and y <= 370 then
            Destruir.enter()
        -- 2. Botón VOLVER
        elseif x >= 300 and x <= 500 and y >= 390 and y <= 440 then
            Destruir.volverMenu = true
        -- 3. Botón SALIR 
        elseif x >= 300 and x <= 500 and y >= 460 and y <= 510 then
            love.event.quit()
        end
    end
end

function Destruir.draw()
    if tiempoFlashDano > 0 then
        love.graphics.clear(0.4, 0.1, 0.1)
    else
        love.graphics.clear(0.1, 0.1, 0.18)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(imgAvion, avion.x - 3, avion.y - 18, 0, 0.10, 0.10)

    love.graphics.setColor(1, 1, 0)
    for _, d in ipairs(disparos) do
        love.graphics.circle("fill", d.x, d.y, 5)
    end

    love.graphics.setColor(1, 1, 1)
    for _, e in ipairs(enemigos) do
        love.graphics.draw(imgEnemigo, e.x - 5, e.y - 5, 0, 0.11, 0.11)
    end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 800, 60)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 20, 20, 200, 20)
    love.graphics.setColor(1 - (avion.vida/100), avion.vida/100, 0.2)
    love.graphics.rectangle("fill", 20, 20, math.max(0, avion.vida * 2), 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. avion.vida, 25, 22)
    love.graphics.print("PUNTOS: " .. puntos, 250, 22)
    love.graphics.setColor(colorFeedback)
    love.graphics.print(textoFeedback, 380, 22)

    -- Pantallas Finales con 3 Botones
    if estadoJuego == "GAME_OVER" or estadoJuego == "VICTORIA" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 800, 600)

        if estadoJuego == "GAME_OVER" then
            love.graphics.setColor(1, 0.2, 0.2)
            love.graphics.printf("¡GAME OVER!", 0, 160, 800, "center")
        else
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.printf("¡VICTORIA!", 0, 160, 800, "center")
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Puntuación Final: " .. puntos, 0, 220, 800, "center")

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

return Destruir