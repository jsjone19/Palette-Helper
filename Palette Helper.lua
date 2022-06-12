-- Initial code written by Chaonic
-- J19 revamped the code and rewrote the dlg section to minimalize and streamline the design

local minColors = 3

-- YOU CAN HAVE A LARGE MAX COLORS SIZE -- 32 IS RECOMMENDED FOR BASE WINDOW
local maxColors = 32 -- should make proportional to window bounds width


-- defaults
local defaultName = "Custom 1"
local defaultColorLeft = Color {r = 0, g = 0, b = 0, a = 255}
local defaultColorRight = Color {r = 255, g = 255, b = 255, a = 255}
local defaultAmountOfColorsVar = 15
local defaultAmountOfHuesVar = 12
local defaultAmountOfSoftHuesVar = 6
local defaultHueStrength = 100
local defaultSatStrength = 100
local defaultValStrenght = 100
local defaultAlphaStrength = 100
local defaultHueInterpolationVar = "Standard"
local defaultSatInterpolationVar = "Quad"
local defaultValInterpolationVar = "Standard"
local defaultAlphaInterpolationVar = "Quad"

-- STANDARD VALUES
local colorLeft = Color {r = 15, g = 15, b = 30, a = 255}
local colorMain = app.fgColor
local colorRight = Color {r = 245, g = 245, b = 230, a = 255}
local hueStrength = 100
local alphaStrength = 100
local alphaWeight = .1

-- WINDOW DATA
local defMainWindowWidth = 368 --initial window width
--local minMainWindowWidth = 357 -- ideally, clamp width so it can't go smaller (not sure how to scan for change in window size but if I find it, I will add this)
local defMainWindowHeight = 339 -- small view window height

local defMainWindowX = 350
local defMainWindowY = 0

local interpolationTypes = {
    "Standard",
    "Linear",
    "Sine",
    "Quad",
    "Cubic",
    "Circ",
    "outSine",
    "outQuad",
    "outCubic",
    "outCirc"
}

local hueInterpolationVar = interpolationTypes[1] --standard
local satInterpolationVar = interpolationTypes[4] --quad
local valInterpolationVar = interpolationTypes[1] --standard
local alphaInterpolationVar = interpolationTypes[4] --quad

-- SHADE TYPES AND LABELS
local shadingTypes = {"Magic Shade", "Light", "Value", "Saturation", "Soft Hue", "Hard Hue"}
local shadeDropDownVar = shadingTypes[1]

local shadeID = { "paletteShade", "paletteLight", "paletteValue", "paletteSaturation", "paletteSoftHue", "paletteHardHue"}
local shadeIDVar = shadeID[1]

--TABLES FOR CALCULATIONS
local calcTable = {}
local genericColorTable = {}

-- CHANGED VALUES
local CL = colorLeft -- stores the color set on colorLeft
local CM = colorMain -- stores the color set on colorMain
local CR = colorRight -- stores the colore set on colorRight
local AOC = maxColors--stores the total number of colors with which to populate the Magic Shade, Light Shade, Value Shades, and Saturation Shade
local HS = hueStrength --stores the relative strength 1 to 100 for the hue
local AS = alphaStrength --stores the relative strength 1 to 100 for the alpha
local HI = hueInterpolationVar --stores the type of interpolation to be done on the hue
local SI = satInterpolationVar --stores the type of interpolation to be done on the saturation
local VI = valInterpolationVar --stores the type of interpolation to be done on the value
local AI = alphaInterpolationVar --stores the type of interpolation to be done on the alpha
local CT = calcTable --prepares colors to apply the interpolations to
--------------------------

local SDI = shadeIDVar -- used by small tab to update calculation of the shade
local SL = shadeDropDownVar -- label text for the shade (also present in the combo box)

local leftIncluded = true
local rightIncluded = true

local inclusionSelectionStates = {"Included", "Not Included"}

local leftSelectionStateVar = inclusionSelectionStates[1]
local rightSelectionStateVar = inclusionSelectionStates[1]

--HOW MUCH SPACING TO ADD TO THE VARIOUS LABELS
--every space is 4 pixels wide.
local strengthLabelOffset = {2, 0, 0, 0}
local colorLabelOffset = {10, 9, 10}

--DLG FIRST INSTANCE?
local dlgFirstInstance = true

--VERY BASIC UNDO COUNTER
local count = 0

-- EASING CALCULATIONS

-- These calculations were taken from https://github.com/EmmanuelOga/easing
-- The authors of the LUA port are Yuichi Tateno and Emmanuel Oga

--[[
    MIT LICENSE
    Copyright (c) 2014 Enrique García Cota, Yuichi Tateno, Emmanuel Oga
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)

local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt

local function linear(t, b, c, d)
    return c * t / d + b
end

local function inQuad(t, b, c, d)
    t = t / d
    return c * t ^ 2 + b
end

local function outQuad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end

local function inCubic(t, b, c, d)
    t = t / d
    return c * t ^ 3 + b
end

local function outCubic(t, b, c, d)
    t = t / d - 1
    return c * (t ^ 3 + 1) + b
end

local function inSine(t, b, c, d)
    return -c * cos(t / d * (pi / 2)) + c + b
end

local function outSine(t, b, c, d)
    return c * sin(t / d * (pi / 2)) + b
end

local function inCirc(t, b, c, d)
    t = t / d
    return (-c * (sqrt(1 - t ^ 2) - 1) + b)
end

local function outCirc(t, b, c, d)
    t = t / d - 1
    return (c * sqrt(1 - t ^ 2) + b)
end

-- END OF EASING CALCULATIONS

-- CALCULATION TABLE GENERATION

local function generateCalcTable()
    local hasCenter = false
    local copyColorAmount = AOC
    local tempTable = {}

    -- If it has a center, remove and mark it
    if copyColorAmount % 2 == 1 then
        copyColorAmount = copyColorAmount - 1
        hasCenter = true
    end

    -- Halve the number, we'll mirror it later
    copyColorAmount = copyColorAmount / 2

    -- Let's get the actual numbers
    local addNumber = 0
    if hasCenter == true then
        for i = 1, copyColorAmount do
            addNumber = math.abs(1 - (i * (100 / (copyColorAmount + 1))) / 100)
            table.insert(tempTable, addNumber)
        end
        table.insert(tempTable, 0)
        for i = 1, copyColorAmount do
            addNumber = (i * (100 / (copyColorAmount + 1))) / 100
            table.insert(tempTable, addNumber)
        end
    else
        for i = 1, copyColorAmount do
            addNumber = ((100 / copyColorAmount) * (copyColorAmount - (i * ((copyColorAmount * 2) / (copyColorAmount * 2 + 1))))) / 100
            table.insert(tempTable, addNumber)
        end
        for i = 1, copyColorAmount do
            addNumber = ((100 / copyColorAmount) * (math.abs((((copyColorAmount * 2) / (copyColorAmount * 2 + 1)) * copyColorAmount) - copyColorAmount) +
			((i - 1) * ((copyColorAmount * 2) / (copyColorAmount * 2 + 1))))) / 100
            table.insert(tempTable, addNumber)
        end
    end
    CT = tempTable
end

-- COLOR TABLE GENERATION

local function generateColorTable()
    genericColorTable = {}
    for i = 1, AOC do
        table.insert(genericColorTable, CM)
    end
end

local function paletteShadeCalc()
    paletteShade = {}
    local copyColorAmount = AOC
    local secondRound = 0
    local hasCenter = false

    -- If it has a center, remove and mark it
    if copyColorAmount % 2 == 1 then
        copyColorAmount = copyColorAmount - 1
        hasCenter = true
    end

    -- Halve the number and prepare the second round
    copyColorAmount = copyColorAmount / 2
    secondRound = copyColorAmount

    -- Let's get the actual table now
    -- Starting with left color to main color
    
    --if leftIncluded is true, then add the left color to the palette as well
    if leftIncluded then
        table.insert(paletteShade, CL)
    end

    for i = 1, copyColorAmount do
        local tempColor = Color {}
        if HI == "Standard" then
            tempColor.red = linear(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = linear(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = linear(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "Sine" then
            tempColor.red = inSine(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = inSine(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = inSine(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "Quad" then
            tempColor.red = inQuad(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = inQuad(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = inQuad(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "Cubic" then
            tempColor.red = inCubic(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = inCubic(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = inCubic(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "Circ" then
            tempColor.red = inCirc(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = inCirc(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = inCirc(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "outSine" then
            tempColor.red = outSine(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = outSine(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = outSine(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "outQuad" then
            tempColor.red = outQuad(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = outQuad(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = outQuad(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "outCubic" then
            tempColor.red = outCubic(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = outCubic(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = outCubic(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        elseif HI == "outCirc" then
            tempColor.red = outCirc(CT[i] * (HS / 100), CM.red, CL.red - CM.red, 1)
            tempColor.green = outCirc(CT[i] * (HS / 100), CM.green, CL.green - CM.green, 1)
            tempColor.blue = outCirc(CT[i] * (HS / 100), CM.blue, CL.blue - CM.blue, 1)
        end

        if SI == "Linear" then
            tempColor.saturation = linear(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "Sine" then
            tempColor.saturation = inSine(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "Quad" then
            tempColor.saturation = inQuad(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "Cubic" then
            tempColor.saturation = inCubic(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "Circ" then
            tempColor.saturation = inCirc(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "outSine" then
            tempColor.saturation = outSine(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "outQuad" then
            tempColor.saturation = outQuad(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "outCubic" then
            tempColor.saturation = outCubic(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        elseif SI == "outCirc" then
            tempColor.saturation = outCirc(CT[i] * (HS / 100), CM.saturation, CL.saturation - CM.saturation, 1)
        end

        if VI == "Linear" then
            tempColor.value = linear(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "Sine" then
            tempColor.value = inSine(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "Quad" then
            tempColor.value = inQuad(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "Cubic" then
            tempColor.value = inCubic(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "Circ" then
            tempColor.value = inCirc(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "outSine" then
            tempColor.value = outSine(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "outQuad" then
            tempColor.value = outQuad(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "outCubic" then
            tempColor.value = outCubic(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        elseif VI == "outCirc" then
            tempColor.value = outCirc(CT[i] * (HS / 100), CM.value, CL.value - CM.value, 1)
        end

        if AI == "Linear" then
            tempColor.alpha = linear(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "Sine" then
            tempColor.alpha = inSine(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "Quad" then
            tempColor.alpha = inQuad(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "Cubic" then
            tempColor.alpha = inCubic(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "Circ" then
            tempColor.alpha = inCirc(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "outSine" then
            tempColor.alpha = outSine(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "outQuad" then
            tempColor.alpha = outQuad(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "outCubic" then
            tempColor.alpha = outCubic(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        elseif AI == "outCirc" then
            tempColor.alpha = outCirc(CT[i] * (AS / 100), CM.alpha, CL.alpha - CM.alpha, 1)
        end
        table.insert(paletteShade, tempColor)
    end
    -- If it has a center, just add the main color in the middle
    if hasCenter == true then
        table.insert(paletteShade, CM)
        secondRound = secondRound + 1
    end
    -- Lastly, main color to right color
    for y = 1, copyColorAmount do
        local tempColor = Color {}
        if HI == "Standard" then
            tempColor.red = linear(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = linear(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = linear(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "Sine" then
            tempColor.red = inSine(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = inSine(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = inSine(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "Quad" then
            tempColor.red = inQuad(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = inQuad(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = inQuad(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "Cubic" then
            tempColor.red = inCubic(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = inCubic(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = inCubic(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "Circ" then
            tempColor.red = inCirc(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = inCirc(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = inCirc(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "outSine" then
            tempColor.red = outSine(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = outSine(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = outSine(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "outQuad" then
            tempColor.red = outQuad(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = outQuad(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = outQuad(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "outCubic" then
            tempColor.red = outCubic(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = outCubic(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = outCubic(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        elseif HI == "outCirc" then
            tempColor.red = outCirc(CT[y + secondRound] * (HS / 100), CM.red, CR.red - CM.red, 1)
            tempColor.green = outCirc(CT[y + secondRound] * (HS / 100), CM.green, CR.green - CM.green, 1)
            tempColor.blue = outCirc(CT[y + secondRound] * (HS / 100), CM.blue, CR.blue - CM.blue, 1)
        end

        if SI == "Linear" then
            tempColor.saturation =
                linear(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "Sine" then
            tempColor.saturation =
                inSine(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "Quad" then
            tempColor.saturation =
                inQuad(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "Cubic" then
            tempColor.saturation =
                inCubic(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "Circ" then
            tempColor.saturation =
                inCirc(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "outSine" then
            tempColor.saturation =
                outSine(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "outQuad" then
            tempColor.saturation =
                outQuad(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "outCubic" then
            tempColor.saturation =
                outCubic(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        elseif SI == "outCirc" then
            tempColor.saturation =
                outCirc(CT[y + secondRound] * (HS / 100), CM.saturation, CR.saturation - CM.saturation, 1)
        end

        if VI == "Linear" then
            tempColor.value = linear(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "Sine" then
            tempColor.value = inSine(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "Quad" then
            tempColor.value = inQuad(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "Cubic" then
            tempColor.value = inCubic(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "Circ" then
            tempColor.value = inCirc(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "outSine" then
            tempColor.value = outSine(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "outQuad" then
            tempColor.value = outQuad(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "outCubic" then
            tempColor.value = outCubic(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        elseif VI == "outCirc" then
            tempColor.value = outCirc(CT[y + secondRound] * (HS / 100), CM.value, CR.value - CM.value, 1)
        end

        if AI == "Linear" then
            tempColor.alpha = linear(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "Sine" then
            tempColor.alpha = inSine(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "Quad" then
            tempColor.alpha = inQuad(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "Cubic" then
            tempColor.alpha = inCubic(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "Circ" then
            tempColor.alpha = inCirc(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "outSine" then
            tempColor.alpha = outSine(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "outQuad" then
            tempColor.alpha = outQuad(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "outCubic" then
            tempColor.alpha = outCubic(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        elseif AI == "outCirc" then
            tempColor.alpha = outCirc(CT[y + secondRound] * (AS / 100), CM.alpha, CR.alpha - CM.alpha, 1)
        end

        table.insert(paletteShade, tempColor)
    end

    --if rightIncluded is true, then add the right color to the palette as well
    if rightIncluded then
        table.insert(paletteShade, CR)
    end

    return paletteShade
end

local function paletteLightCalc()
    paletteLight = {}
    local copyColorAmount = AOC
    local secondRound = 0
    local hasCenter = false

    -- If it has a center, remove and mark it
    if copyColorAmount % 2 == 1 then
        copyColorAmount = copyColorAmount - 1
        hasCenter = true
    end

    -- Halve the number and prepare the second round
    copyColorAmount = copyColorAmount / 2
    secondRound = copyColorAmount

    -- Let's get the actual table now
    -- Starting with black to normal
    for i = 1, copyColorAmount do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha

        if VI == "Standard" then
            tempColor.lightness = linear(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "Linear" then
            tempColor.lightness = linear(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "Sine" then
            tempColor.lightness = inSine(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "Quad" then
            tempColor.lightness = inQuad(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "Cubic" then
            tempColor.lightness = inCubic(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "Circ" then
            tempColor.lightness = inCirc(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "outSine" then
            tempColor.lightness = outSine(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "outQuad" then
            tempColor.lightness = outQuad(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "outCubic" then
            tempColor.lightness = outCubic(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        elseif VI == "outCirc" then
            tempColor.lightness = outCirc(CT[i] * (HS / 100), CM.lightness, 0 - CM.lightness, 1)
        end

        table.insert(paletteLight, tempColor)
    end
    -- If it has a center, just add the main color in the middle
    if hasCenter == true then
        table.insert(paletteLight, CM)
        secondRound = secondRound + 1
    end
    -- Lastly, normal to white
    for y = 1, copyColorAmount do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha

        if VI == "Standard" then
            tempColor.lightness = linear(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "Linear" then
            tempColor.lightness = linear(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "Sine" then
            tempColor.lightness = inSine(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "Quad" then
            tempColor.lightness = inQuad(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "Cubic" then
            tempColor.lightness = inCubic(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "Circ" then
            tempColor.lightness = inCirc(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "outSine" then
            tempColor.lightness = outSine(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "outQuad" then
            tempColor.lightness = outQuad(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "outCubic" then
            tempColor.lightness = outCubic(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        elseif VI == "outCirc" then
            tempColor.lightness = outCirc(CT[y + secondRound] * (HS / 100), CM.lightness, 1 - CM.lightness, 1)
        end

        table.insert(paletteLight, tempColor)
    end
    return paletteLight
end

local function paletteValueCalc()
    paletteValue = {}
    local copyColorAmount = AOC
    local secondRound = 0
    local hasCenter = false

    -- If it has a center, remove and mark it
    if copyColorAmount % 2 == 1 then
        copyColorAmount = copyColorAmount - 1
        hasCenter = true
    end

    -- Halve the number and prepare the second round
    copyColorAmount = copyColorAmount / 2
    secondRound = copyColorAmount

    -- Let's get the actual table now
    -- Starting with black to normal
    for i = 1, copyColorAmount do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha

        if VI == "Standard" then
            tempColor.value = linear(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "Linear" then
            tempColor.value = linear(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "Sine" then
            tempColor.value = inSine(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "Quad" then
            tempColor.value = inQuad(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "Cubic" then
            tempColor.value = inCubic(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "Circ" then
            tempColor.value = inCirc(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "outSine" then
            tempColor.value = outSine(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "outQuad" then
            tempColor.value = outQuad(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "outCubic" then
            tempColor.value = outCubic(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        elseif VI == "outCirc" then
            tempColor.value = outCirc(CT[i] * (HS / 100), CM.value, 0 - CM.value, 1)
        end

        table.insert(paletteValue, tempColor)
    end
    -- If it has a center, just add the main color in the middle
    if hasCenter == true then
        table.insert(paletteValue, CM)
        secondRound = secondRound + 1
    end
    -- Lastly, normal to white
    for y = 1, copyColorAmount do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha

        if VI == "Standard" then
            tempColor.value = linear(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "Linear" then
            tempColor.value = linear(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "Sine" then
            tempColor.value = inSine(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "Quad" then
            tempColor.value = inQuad(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "Cubic" then
            tempColor.value = inCubic(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "Circ" then
            tempColor.value = inCirc(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "outSine" then
            tempColor.value = outSine(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "outQuad" then
            tempColor.value = outQuad(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "outCubic" then
            tempColor.value = outCubic(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        elseif VI == "outCirc" then
            tempColor.value = outCirc(CT[y + secondRound] * (HS / 100), CM.value, 1 - CM.value, 1)
        end

        table.insert(paletteValue, tempColor)
    end
    return paletteValue
end

local function paletteSaturationCalc()
    paletteSaturation = {}
    local copyColorAmount = AOC
    local secondRound = 0
    local hasCenter = false

    -- If it has a center, remove and mark it
    if copyColorAmount % 2 == 1 then
        copyColorAmount = copyColorAmount - 1
        hasCenter = true
    end

    -- Halve the number and prepare the second round
    copyColorAmount = copyColorAmount / 2
    secondRound = copyColorAmount

    -- Let's get the actual table now
    -- Starting with desaturated to normal
    for i = 1, copyColorAmount do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha
        if SI == "Standard" then
            tempColor.saturation = linear(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "Linear" then
            tempColor.saturation = linear(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "Sine" then
            tempColor.saturation = inSine(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "Quad" then
            tempColor.saturation = inQuad(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "Cubic" then
            tempColor.saturation = inCubic(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "Circ" then
            tempColor.saturation = inCirc(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "outSine" then
            tempColor.saturation = outSine(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "outQuad" then
            tempColor.saturation = outQuad(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "outCubic" then
            tempColor.saturation = outCubic(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        elseif SI == "outCirc" then
            tempColor.saturation = outCirc(CT[i] * (HS / 100), CM.saturation, 1 - CM.saturation, 1)
        end

        table.insert(paletteSaturation, tempColor)
    end
    -- If it has a center, just add the main color in the middle
    if hasCenter == true then
        table.insert(paletteSaturation, CM)
        secondRound = secondRound + 1
    end
    -- Lastly, normal to saturated
    for y = 1, copyColorAmount do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha

        if SI == "Standard" then
            tempColor.saturation = linear(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "Linear" then
            tempColor.saturation = linear(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "Sine" then
            tempColor.saturation = inSine(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "Quad" then
            tempColor.saturation = inQuad(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "Cubic" then
            tempColor.saturation = inCubic(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "Circ" then
            tempColor.saturation = inCirc(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "outSine" then
            tempColor.saturation = outSine(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "outQuad" then
            tempColor.saturation = outQuad(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "outCubic" then
            tempColor.saturation = outCubic(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        elseif SI == "outCirc" then
            tempColor.saturation = outCirc(CT[y + secondRound] * (HS / 100), CM.saturation, 0 - CM.saturation, 1)
        end

        table.insert(paletteSaturation, tempColor)
    end
    return paletteSaturation
end

local function paletteHueCalc()
    paletteHue = {}

    for i = 1, AOC do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha

        if HI == "Standard" then
            tempColor.hue = linear((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Sine" then
            tempColor.hue = inSine((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Quad" then
            tempColor.hue = inQuad((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Cubic" then
            tempColor.hue = inCubic((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Circ" then
            tempColor.hue = inCirc((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outSine" then
            tempColor.hue = outSine((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outQuad" then
            tempColor.hue = outQuad((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outCubic" then
            tempColor.hue = outCubic((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outCirc" then
            tempColor.hue = outCirc((1 / AOC) * (i - 1), CM.hue, 360, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        end

        table.insert(paletteHue, tempColor)
    end
    return paletteHue
end

local function paletteSoftHueCalc()
    paletteSoftHue = {}

    for i = 1, AOC do
        local tempColor = Color {}
        tempColor.red = CM.red
        tempColor.green = CM.green
        tempColor.blue = CM.blue
        tempColor.alpha = CM.alpha
        if HI == "Standard" then
            tempColor.hue = linear((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Sine" then
            tempColor.hue = inSine((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Quad" then
            tempColor.hue = inQuad((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Cubic" then
            tempColor.hue = inCubic((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "Circ" then
            tempColor.hue = inCirc((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outSine" then
            tempColor.hue = outSine((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outQuad" then
            tempColor.hue = outQuad((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outCubic" then
            tempColor.hue = outCubic((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        elseif HI == "outCirc" then
            tempColor.hue = outCirc((1 / AOC) * (i - 1), CM.hue, 360 / AOC, 1)
            while tempColor.hue >= 360 do
                tempColor.hue = tempColor.hue - 360
            end
        end
        table.insert(paletteSoftHue, tempColor)
    end
    return paletteSoftHue
end

-- Create the shade color group for the small tab
local function makeShadeGroup()
	--if SDI is blah, then do blah calc
		--get the appropriate color array
		if SDI == "paletteShade" then
			return paletteShadeCalc()
		elseif SDI == "paletteLight" then
			return paletteLightCalc()
		elseif SDI == "paletteValue" then
			return paletteValueCalc()
		elseif SDI == "paletteSaturation" then
			return paletteSaturationCalc()
		elseif SDI == "paletteSoftHue" then
			return paletteSoftHueCalc()
		else
			return paletteHueCalc()
		end
end


function findNearestColorInPalette(CM)
    local nearestValIDX = CM.index
    -- use the ChangeColor command to select the nearest color in the palette window
    app.command.ChangeColor{target = nearestValIDX}
    --set the foreground color to the CM again so that the user doesn't have their fg change
    app.fgColor = CM
end

-- RELOAD COLORS
local function reloadColors(windowBounds)
    local dlg = Dialog {title = "Palette Helper", onclose = updateVarsOnClose}
    CM = app.fgColor
    -- First, let's get the calculation table and the generic palette
    generateCalcTable()
    generateColorTable()

    -- create spacing offsets

    strengthLabelSpacing1 = createSpacing(strengthLabelOffset[1])
    strengthLabelSpacing2 = createSpacing(strengthLabelOffset[2])
    strengthLabelSpacing3 = createSpacing(strengthLabelOffset[3])
    strengthLabelSpacing4 = createSpacing(strengthLabelOffset[4])

    colorLabelSpacing1 = createSpacing(colorLabelOffset[1])
    colorLabelSpacing2 = createSpacing(colorLabelOffset[2])
    colorLabelSpacing3 = createSpacing(colorLabelOffset[3])

    paletteHue = paletteHueCalc()
    -- DIALOG

    dlg:button {text = "&HELP", focus = false, onclick = helpMe}
    dlg:button {text = "&About", focus = false, onclick = aboutThis}
    dlg:separator {
        id = "separator",
        text = "Base Colors"
    }:label {
        id = labelColorLeft,
        text = colorLabelSpacing1 .. "Left"
    }:label {
        id = labelColorMain,
        text = colorLabelSpacing2 .. "Main"
    }:label {
        id = labelColorRight,
        text = colorLabelSpacing3 .. "Right"
    } :shades {
        id = "mainColors",
        colors = {CL, CM, CR},
        onclick = function(ev)
            if (ev.button == MouseButton.LEFT) then
                app.fgColor = ev.color
            end
        end
    }:button {
        id = "buttonSetLeft",
        text = "Set",
        onclick = function()
            CL = app.fgColor
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
            dlg:modify{
                id = "mainColors",
                colors = {CL,CM,CR}
            }
        end
    }:button {
        id = "buttonSetMain",
        text = "Set",
        onclick = function()
            CM = app.fgColor
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
            dlg:modify{
                id = "mainColors",
                colors = {CL,CM,CR}
            }
        end
    }:button {
        id = "buttonSetRight",
        text = "Set",
        onclick = function()
            CR = app.fgColor
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
            dlg:modify{
                id = "mainColors",
                colors = {CL,CM,CR}
            }
        end
    }:newrow()

    :button{
        id = "leftIncludedButton",
        text = leftSelectionStateVar,
        onclick = function()
            --modify the text to say not included and update the left inclusion variable
            leftIncluded = not leftIncluded
            if leftIncluded then
                leftSelectionStateVar = inclusionSelectionStates[1]
            else 
                leftSelectionStateVar = inclusionSelectionStates[2]
            end
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:button{
        id = "findNearestColorButton",
        text = "Find Nearest Color",
        onclick = findNearestColorInPalette
    }:button{
        id="rightIncludedButton",
        text = rightSelectionStateVar,
        onclick = function()
            --modify the text to say not included and update the right inclusion variable
            rightIncluded = not rightIncluded
            if rightIncluded then
                rightSelectionStateVar = inclusionSelectionStates[1]
            else 
                rightSelectionStateVar = inclusionSelectionStates[2]
            end
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }

    
    :separator {
        id = "separator",
        text = "Color Control"
    }:label {
        id = "huelabel",
        text = strengthLabelSpacing1 .. "Hue/Color"
    }:label {
        id = "satlabel",
        text = strengthLabelSpacing2 .. "Saturation"
    }:label {
        id = "vallabel",
        text = strengthLabelSpacing3 .. "Value/Light"
    }:label {
        id = "alphalabel",
        text = strengthLabelSpacing4 .. "Alpha"
    }:combobox {
        id = "hueInterpolation",
        label = "Interpolations: ",
        option = HI,
        options = interpolationTypes,
        onchange = function()
            HI = dlg.data.hueInterpolation
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:combobox {
        id = "satInterpolation",
        option = SI,
        options = interpolationTypes,
        onchange = function()
            SI = dlg.data.satInterpolation
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:combobox {
        id = "valInterpolation",
        option = VI,
        options = interpolationTypes,
        onchange = function()
            VI = dlg.data.valInterpolation
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:combobox {
        id = "alphaInterpolation",
        option = AI,
        options = interpolationTypes,
        onchange = function()
            AI = dlg.data.alphaInterpolation
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:slider {
        id = "amountOfColorsSlider",
        label = "Amount of Colors: ",
        min = minColors,
        max = maxColors,
        value = defaultAmountOfColorsVar,
        onchange = function()
            AOC = dlg.data.amountOfColorsSlider
        end,
        onrelease = function()
            AOC = dlg.data.amountOfColorsSlider
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:slider {
        id = "hueStrengthSlider",
        label = "Variance: ",
        min = 0,
        max = 100,
        value = HS,
        onchange = function()
            HS = dlg.data.hueStrengthSlider
        end,
        onrelease = function()
            HS = dlg.data.hueStrengthSlider
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:newrow()
    :slider {
        id = "alphaStrengthSlider",
        label = "Magic Shade Alpha: ",
        min = 0,
        max = 100,
        value = AS,
        onchange = function()
            AS = dlg.data.alphaStrengthSlider
        end,
        onrelease = function()
            AS = dlg.data.alphaStrengthSlider
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end
    }:separator {
        id = "separator",
        text = "Shades"
    }:-- SHADE
    combobox {
        
        id = "shadesDropDown",
        option = SL,
        options = shadingTypes,
        onchange = function()
            SL = dlg.data.shadesDropDown
            for i=1,#shadingTypes,1 do
                if SL == shadingTypes[i] then
                    SDI = shadeID[i]
                end
            end
            updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)
        end

    }:shades {
        id = "paletteShade",
        label = "Magic Shade",
        colors = makeShadeGroup(SDI),
        onclick = function(ev)
            if (ev.button == MouseButton.LEFT) then
                app.fgColor = ev.color
            end
        end

    }:button {
        id = "buttonShadeLine",
        text = "Copy Line to Palette",
        onclick = function()
            copyColor = Color {}
            app.transaction(function()
                if SDI == shadeID[1] then
                    for i = 1, AOC do
                        copyColor = paletteShade[i]
                        app.command.AddColor {
                            color = copyColor
                        }
                    end 
                elseif SDI == shadeID[2] then
                    for i = 1, AOC do
                        copyColor = paletteLight[i]
                        app.command.AddColor {
                            color = copyColor
                        }
                    end 
                elseif SDI == shadeID[3] then
                    for i = 1, AOC do
                        copyColor = paletteValue[i]
                        app.command.AddColor {
                            color = copyColor
                        }
                    end 
                elseif SDI == shadeID[4] then
                    for i = 1, AOC do
                        copyColor = paletteSaturation[i]
                        app.command.AddColor {
                            color = copyColor
                        }
                    end 
                elseif SDI == shadeID[5] then
                    for i = 1, AOC do
                        copyColor = paletteSoftHue[i]
                        app.command.AddColor {
                            color = copyColor
                        }
                    end 
                elseif SDI == shadeID[6] then
                    for i = 1, AOC do
                        copyColor = paletteHue[i]
                        app.command.AddColor {
                            color = copyColor
                        }
                    end 
                end
            end)
            count = count + 1
            app.refresh()

        end
    }:button {
        id = "buttonShadePalette",
        text = "Generate whole Palette",
        onclick = function()
            for y = 1, AOC do
                app.transaction(function()
                    if SDI == shadeID[1] then
                        for i = 1, AOC do
                            copyColor = paletteShade[i]
                            app.command.AddColor {
                                color = copyColor
                            }
        
                        end
                    elseif SDI == shadeID[2] then
                        for i = 1, AOC do
                            copyColor = paletteLight[i]
                            app.command.AddColor {
                                color = copyColor
                            }
        
                        end
                    elseif SDI == shadeID[3] then
                        for i = 1, AOC do
                            copyColor = paletteValue[i]
                            app.command.AddColor {
                                color = copyColor
                            }
        
                        end
                    elseif SDI == shadeID[4] then
                        for i = 1, AOC do
                            copyColor = paletteSaturation[i]
                            app.command.AddColor {
                                color = copyColor
                            }
        
                        end
                    elseif SDI == shadeID[5] then
                        for i = 1, AOC do
                            copyColor = paletteSoftHue[i]
                            app.command.AddColor {
                                color = copyColor
                            }
        
                        end
                    elseif SDI == shadeID[6] then
                        for i = 1, AOC do
                            copyColor = paletteHue[i]
                            app.command.AddColor {
                                color = copyColor
                            }
        
                        end
                    end
                 end)
                count = count + 1
                app.refresh()

                local wrap = 0
                if y + 1 > AOC then
                    wrap = AOC
                end
                CM = paletteHue[y + 1 - wrap]
                paletteShadeCalc()
            end
        end
    }:newrow()
    :button {
        id = "buttonCancel",
        text = "Cancel",
        onclick = undoEverything
    }:show {
        wait = false,
        bounds = windowBounds
    }
end

function undoEverything()
    --undo all
    for i=1,count,1 do
        app.command.Undo()
    end
    count = 0
end


function createSpacing(labelOffset)
    labelOffset_ = labelOffset --make dynamic to window bounds in the x direction
    local labelSpacing = ""
    for i = 1, labelOffset_ do
        labelSpacing = labelSpacing .. " "
    end
    return labelSpacing
end

function updateVarsOnClose()
    CM = app.fgColor
    CL = colorLeft
    CR = colorRight
    AOC = amountOfColorsVar
    HS = hueStrength
    AS = alphaStrength
    HI = hueInterpolationVar
    SI = satInterpolationVar
    VI = valInterpolationVar
    AI = alphaInterpolationVar
end

function aboutThis()
    print("The Palette Helper project was inspired by domjohn`s Color Shading extension.\n")
    print("Palette Helper gives you bit more control over your gradients.")
    print("You can use Palette Helper without having to learn a good deal about color theory and how to pick colors.")
    print("However, some familiarity with these things is necessary if you want to use this tool to its highest potential\n")
    print("We look forward to all of the custom palette-making in the community!\n\n")
    print("Authors: Chaonic, J19\n")
    print("--------------------------------------------------------------------------------\n")
    print("Chaonic came up with the idea for the Palette Helper.\n")
    print("He's the one who made the code for most of the background calculations that give you those beautiful color gradients.\n")
    print("The source of the easing functions used in the interpolations is https://github.com/EmmanuelOga/easing\n")
    print("--------------------------------------------------------------------------------\n")
    print("J19 edited the code for Chaonic's Palette Helper. He streamlined the UI and added several new functionalities as well.\n")
    print("functionalites added by J19: 'Help' button, 'About' button, L/R included buttons, 'Find Nearest Color' button, 'Shades' Drop-Down, 'Cancel' button\n")
    print("In addition, the Palette Helper can now be freely moved and resized without snapping back to its original bounds.\n")
end

function helpMe()
    print("Sorry you're stuck. Let me walk you through the answer to some common questions.\n")
    print("--------------------------------------------------------------------------------\n")
    print("Q: How do I update the base colors?\n")
    print("A: Change your foreground color to the color you wish to set. Then press the 'Set' button beneath one of the base colors.")
    print("--------------------------------------------------------------------------------\n")
    print("Q: What am I supposed to do with the 'Amount of Colors' and 'Variance' sliders? What is the interpolation?\n")
    print("A: 'Amount of Colors' does what its name suggests. Change it and you will see that the number of colors on the shade preview goes up.\n")
    print(" 'Variance' is a metric that changes how the interpolations do their calculations. The higher the number, the more the resultant shade will vary.\n")
    print(" An interpolation is a means of constructing a function from data points in order to find new points in between the old points.\n")
    print("There are several kinds of interpolations. You're welcome to play around with them.\n")
    print("--------------------------------------------------------------------------------\n")
    print("Q: I have 'Amount of Colors' set to a fairly large number and the preview works... but why don't I see lots of new colors generated on the palette window?\n")
    print("A: Great question! You see, the palette helper only adds the color if it was not already in your palette. This means that some colors will be left out if you already have a large palette.\n")
    print("--------------------------------------------------------------------------------\n")
    print("Q: Why does 'Generate Whole Palette' do the same thing as 'Copy Line to Palette' if I'm on something other than 'Magic Shade'?\n")
    print("A: My, my, you're quite observant! That's just the way the program is designed at this point.\n")
    print(" There may come a point in time where 'Light', 'Value', and 'Saturation' alternate in hue as well... but for now, it is the way it is. *Shrug*\n")
    print("----------------------------------Scroll Up-------------------------------------\n")
    print("Q: What does find nearest color do?")
end

function updatePanel(dlg,SDI,AOC,HS,AS,HI,SI,VI,AI)

    generateCalcTable()
    generateColorTable()

    dlg:modify{
        id = "leftIncludedButton",
        text = leftSelectionStateVar
    }
    dlg:modify{
        id = "rightIncludedButton",
        text = rightSelectionStateVar
    }

    dlg:modify{
        id = "paletteShade",
        colors = makeShadeGroup(SDI)
    }

end

do
        windowBounds = Rectangle(defMainWindowX, defMainWindowY, defMainWindowWidth, defMainWindowHeight)
        reloadColors(windowBounds)
end
