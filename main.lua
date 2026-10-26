local destruir = require("destruir")
local recolectar = require("recolectar")

local estadoApp = "MENU" -- "MENU", "DESTRUIR", "RECOLECTAR"

function love.load()
    if destruir.load then destruir.load() end
    if recolectar.load then recolectar.load() end
end

function love.update(dt)
    if estadoApp == "DESTRUIR" then
        destruir.update(dt)
        if destruir.volverMenu then
            estadoApp = "MENU"
        end
    elseif estadoApp == "RECOLECTAR" then
        recolectar.update(dt)
        if recolectar.volverMenu then
            estadoApp = "MENU"
        end
    end
end

function love.mousepressed(x, y, button)
    if estadoApp == "MENU" then
        if button == 1 then
            -- Botón DESTRUIR
            if x >= 300 and x <= 500 and y >= 220 and y <= 270 then
                estadoApp = "DESTRUIR"
                destruir.enter()
            -- Botón RECOLECTAR
            elseif x >= 300 and x <= 500 and y >= 290 and y <= 340 then
                estadoApp = "RECOLECTAR"
                recolectar.enter()
            -- Botón SALIR
            elseif x >= 300 and x <= 500 and y >= 360 and y <= 410 then
                love.event.quit()
            end
        end
    elseif estadoApp == "DESTRUIR" then
        destruir.mousepressed(x, y, button)
        if destruir.volverMenu then estadoApp = "MENU" end
    elseif estadoApp == "RECOLECTAR" then
        recolectar.mousepressed(x, y, button)
        if recolectar.volverMenu then estadoApp = "MENU" end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if estadoApp == "MENU" then
            love.event.quit()
        else
            estadoApp = "MENU"
        end
    end

    if estadoApp == "DESTRUIR" then
        destruir.keypressed(key)
        if destruir.volverMenu then estadoApp = "MENU" end
    elseif estadoApp == "RECOLECTAR" then
        recolectar.keypressed(key)
        if recolectar.volverMenu then estadoApp = "MENU" end
    end
end

function love.draw()
    if estadoApp == "MENU" then
        love.graphics.clear(0.1, 0.1, 0.2)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SUPER ARCADE - MENÚ PRINCIPAL", 0, 120, 800, "center")

        -- Botón Destruir
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", 300, 220, 200, 50, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("DESTRUIR", 300, 235, 200, "center")

        -- Botón Recolectar
        love.graphics.setColor(0.2, 0.6, 0.8)
        love.graphics.rectangle("fill", 300, 290, 200, 50, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("RECOLECTAR", 300, 305, 200, "center")

        -- Botón Salir
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", 300, 360, 200, 50, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SALIR", 300, 375, 200, "center")

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Selecciona un juego para comenzar", 0, 480, 800, "center")

    elseif estadoApp == "DESTRUIR" then
        destruir.draw()
    elseif estadoApp == "RECOLECTAR" then
        recolectar.draw()
    end
end