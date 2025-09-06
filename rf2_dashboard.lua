local app_name = "rf2_dashboard"
local baseDir = "/WIDGETS/rf2_dashboard/"
local inSimu = string.sub(select(2,getVersion()), -4) == "simu"
local build_ui_fancy = nil
local img_box = nil
local timerNumber = 1
local err_img = bitmap.open(baseDir.."img/no_connection_wr.png")
local wgt = {}

-- Enhanced features from RF2 Dashboard V2.1
local flightData = {
    date = "",
    modelName = "",
    flightTime = 0,
    flightCount = 0,
    usedCapacity = 0,
    minVoltage = 0,
    maxCurrent = 0,
    maxPower = 0,
    maxRPM = 0,
    minBEC = 0
}
local flightCount = 0
local showFlightSummary = true
local timerTipsNum = 0
local gov_state_names = { "OFF", "IDLE", "SPOOLUP", "RECOVERY", "ACTIVE", "THR-OFF", "LOST-HS", "AUTOROT", "BAILOUT" }

-- Enhanced timer functionality
local T_0 = 0  -- Base time
local T_P = 0  -- Pause time
local T_Ssecond = 0
local T_MM = "00"
local T_SS = "00"

local FS={FONT_38=XXLSIZE,FONT_16=DBLSIZE,FONT_12=MIDSIZE,FONT_8=0,FONT_6=SMLSIZE}

local function isFileExist(file_name)
    local hFile = io.open(file_name, "r")
    if hFile == nil then
        return false
    end
    io.close(hFile)
    return true
end

local function buildBlackboxHorz(parentBox, wgt, myBatt, fPercent, getPercentColor)
    local percent = fPercent(wgt)
    local r = 30
    local fill_color = myBatt.bar_color or GREEN
    local fill_color= (getPercentColor~=nil) and getPercentColor(wgt, percent) or GREEN
    local tw = 4
    local th = 4

    local box = parentBox:box({x=myBatt.x, y=myBatt.y})
    box:rectangle({x=0, y=0, w=myBatt.w, h=myBatt.h, color=myBatt.bg_color, filled=true, rounded=6, thickness=8})
    box:rectangle({x=0, y=0, w=myBatt.w, h=myBatt.h, color=WHITE, filled=false, thickness=myBatt.fence_thickness or 3, rounded=8})
    box:rectangle({x=5, y=5,
        -- w=0, h=myBatt.h,
        filled=true, rounded=4,
        size =function() return math.floor(fPercent(wgt) / 100 * myBatt.w)-10, myBatt.h-10 end,
        color=function() return getPercentColor(wgt, percent) or GREEN end,
    })

    return box
end

local function formatTime(wgt, t1)
    local dd_raw = t1.value
    local isNegative = false
    if dd_raw < 0 then
      isNegative = true
      dd_raw = math.abs(dd_raw)
    end

    local dd = math.floor(dd_raw / 86400)
    dd_raw = dd_raw - dd * 86400
    local hh = math.floor(dd_raw / 3600)
    dd_raw = dd_raw - hh * 3600
    local mm = math.floor(dd_raw / 60)
    dd_raw = dd_raw - mm * 60
    local ss = math.floor(dd_raw)

    local time_str
    if dd == 0 and hh == 0 then
      -- less then 1 hour, 59:59
      time_str = string.format("%02d:%02d", mm, ss)

    elseif dd == 0 then
      -- lass then 24 hours, 23:59:59
      time_str = string.format("%02d:%02d:%02d", hh, mm, ss)
    else
      -- more than 24 hours
      if wgt.options.use_days == 0 then
        -- 25:59:59
        time_str = string.format("%02d:%02d:%02d", dd * 24 + hh, mm, ss)
      else
        -- 5d 23:59:59
        time_str = string.format("%dd %02d:%02d:%02d", dd, hh, mm, ss)
      end
    end
    if isNegative then
      time_str = '-' .. time_str
    end
    return time_str, isNegative
end

build_ui_fancy = function(wgt)
    local txtColor = wgt.options.textColor
    local titleGreyColor = LIGHTGREY
    local dx = 20

    lvgl.clear()

    -- global
    lvgl.rectangle({x=0, y=0, w=LCD_W, h=LCD_H, color=lcd.RGB(0x111111), filled=true})
    local pMain = lvgl.box({x=0, y=0})

    -- time
    pMain:build({
        {type="box", x=20, y=10, children={
            {type="label", text=function() return wgt.values.timer_str end, x=0, y=0, font=FS.FONT_38 ,color=txtColor},
        }}
    })

    -- rpm
    pMain:build({{type="box", x=20, y=160,
        children={
            {type="label", text="RPM",  x=0, y=0, font=FS.FONT_6, color=titleGreyColor},
            {type="label", text=function() return wgt.values.rpm_str end, x=0, y=10, font=FS.FONT_16 ,color=txtColor},
        }
    }})

    -- voltage
    local bVolt = pMain:box({x=20, y=72})
    buildBlackboxHorz(bVolt, wgt,
        {x=0, y=17,w=200,h=50,segments_w=20, color=WHITE, bg_color=GREY, cath_w=10, cath_h=30, segments_h=20, cath=false},
        function(wgt) return wgt.values.cell_percent end,
        function(wgt) return wgt.values.cellColor end
    )
    bVolt:label({text=function() return string.format("%.02fv", wgt.values.volt, wgt.values.cell_percent) end , x=50, y=21, font=FS.FONT_16 ,color=txtColor})

    -- current
    local bCurr = pMain:box({x=150, y=160})
    bCurr:label({text="Max Current",  x=0, y=0, font=FS.FONT_6, color=titleGreyColor})
    bCurr:label({text=function() return wgt.values.curr_str end, x=0, y=12, font=FS.FONT_16 ,color=txtColor})

    -- image
    local isizew=150
    local isizeh=120
    local bImageArea = pMain:box({x=310, y=20})
    bImageArea:rectangle({x=0, y=0, w=isizew, h=isizeh, thickness=4, rounded=15, filled=false, color=WHITE})
    local bImg = bImageArea:box({})
    img_box = bImg

    -- craft name
    local bCraftName = pMain:box({x=310, y=142})
    bCraftName:rectangle({x=0, y=20, w=isizew, h=25, filled=true, rounded=8, color=DARKGREY, opacity=200})
    bCraftName:label({text=function() return wgt.values.craft_name end,  x=10, y=22, font=FS.FONT_8, color=txtColor})

    -- no connection
    local bNoConn = lvgl.box({x=310, y=20, visible=function() return wgt.is_connected==false end})
    bNoConn:rectangle({x=5, y=5, w=isizew-10, h=isizeh-10, rounded=15, filled=true, color=BLACK, opacity=250})
    -- bNoConn:label({x=22, y=90, text=function() return wgt.not_connected_error end , font=FS.FONT_8, color=WHITE})
    bNoConn:image({x=30, y=15, w=90, h=90, file=baseDir.."img/no_connection_wr.png"})

    -- Governor state display
    pMain:label({text=function() return wgt.values.gov_state or "UNKNOWN" end, x=310, y=170, font=FS.FONT_8, color=txtColor})

    -- Flight summary modal overlay - full screen backdrop
    local bFlightSummaryBackdrop = lvgl.box({x=0, y=0, visible=function() return showFlightSummary end})
    bFlightSummaryBackdrop:rectangle({x=0, y=0, w=LCD_W, h=LCD_H, filled=true, color=BLACK, opacity=180})
    
    -- Flight summary dialog - properly centered
    local modalW = 300
    local modalH = 200
    local modalX = (LCD_W - modalW) / 2
    local modalY = (LCD_H - modalH) / 2 - 40
    
    local bFlightSummary = lvgl.box({x=0, y=0, visible=function() return showFlightSummary end})
    bFlightSummary:rectangle({x=modalX, y=modalY, w=modalW, h=modalH, filled=true, color=DARKGREY, opacity=255, rounded=15})
    bFlightSummary:rectangle({x=modalX, y=modalY, w=modalW, h=modalH, filled=false, color=WHITE, thickness=3, rounded=15})
    
    -- Title bar
    local titleBarH = 35
    bFlightSummary:rectangle({x=modalX, y=modalY, w=modalW, h=titleBarH, filled=true, color=WHITE, opacity=255, rounded=15})
    bFlightSummary:label({text="Flight Summary", x=modalX + modalW/2 - 140, y=modalY + titleBarH/2 - 20, font=FS.FONT_16, color=BLACK, center=true})
    
    -- Close button (X) in top right corner
    local closeButtonW = 20
    local closeButtonH = 20
    local closeButtonX = modalX + modalW - closeButtonW - 5
    local closeButtonY = modalY + 5
    
    -- Close button background
    bFlightSummary:rectangle({x=closeButtonX, y=closeButtonY, w=closeButtonW, h=closeButtonH, filled=true, color=RED, opacity=255, rounded=3})
    bFlightSummary:rectangle({x=closeButtonX, y=closeButtonY, w=closeButtonW, h=closeButtonH, filled=false, color=WHITE, thickness=1, rounded=3})
    
    -- X icon properly centered
    bFlightSummary:label({text="X", x=closeButtonX + closeButtonW/2 - 5, y=closeButtonY + closeButtonH/2 - 10, font=FS.FONT_10, color=WHITE, center=true})
    
    -- Flight data content
    local contentStartY = modalY + titleBarH + 5
    bFlightSummary:label({text=function() return string.format("Flight Time: %s", flightData.flightTime) end, x=modalX + 15, y=contentStartY, font=FS.FONT_12, color=WHITE})
    bFlightSummary:label({text=function() return string.format("Max Current: %.1fA", flightData.maxCurrent) end, x=modalX + 15, y=contentStartY + 25, font=FS.FONT_12, color=WHITE})
    bFlightSummary:label({text=function() return string.format("Max RPM: %d", flightData.maxRPM) end, x=modalX + 15, y=contentStartY + 50, font=FS.FONT_12, color=WHITE})
    bFlightSummary:label({text=function() return string.format("Used Capacity: %dmAh", flightData.usedCapacity) end, x=modalX + 15, y=contentStartY + 75, font=FS.FONT_12, color=WHITE})
    bFlightSummary:label({text=function() return string.format("Min Voltage: %.1fV", flightData.minVoltage) end, x=modalX + 15, y=contentStartY + 100, font=FS.FONT_12, color=WHITE})
    bFlightSummary:label({text=function() return string.format("Max Power: %dW", flightData.maxPower) end, x=modalX + 15, y=contentStartY + 125, font=FS.FONT_12, color=WHITE})
    
    -- Bottom status bar
    local zoneW = wgt.zone.w or LCD_W
    local zoneH = wgt.zone.h or LCD_H
    local bottomBarY = zoneH - 45
    local bBottomBar = pMain:box({x=0, y=bottomBarY})
    bBottomBar:rectangle({x=0, y=0, w=zoneW, h=45, filled=true, color=BLACK, opacity=255})
    bBottomBar:rectangle({x=0, y=0, w=zoneW, h=2, filled=true, color=WHITE})

    -- Bottom bar sections
    local sections = {
        {label="Min V", value=function() return string.format("%.2fv", wgt.values.min_volt) end, color=function() return wgt.values.min_volt < 3.3 and RED or txtColor end},
        {label="Status", value=function() return wgt.values.armed and "ARM" or "DISARM" end, color=function() return wgt.values.armed and GREEN or RED end},
        {label="Batt %", value=function() return string.format("%d%%", wgt.values.batt_percent) end, color=function() 
            local pct = wgt.values.batt_percent
            if pct <= 20 then return RED
            elseif pct <= 40 then return YELLOW
            else return txtColor end
        end},
        {label="Flight Mode", value=function() return wgt.values.flight_mode end, color=txtColor},
        {label="RSSI", value=function() return string.format("%ddB", wgt.values.rssi) end, color=function() 
            local rssi = wgt.values.rssi
            if rssi < -100 then return RED
            elseif rssi < -90 then return YELLOW
            else return GREEN end
        end},
        {label="mAh", value=function() return string.format("%d", wgt.values.usedCapacity) end, color=txtColor},
    }

    local numSections = #sections
    local spacing = math.floor(zoneW / numSections)

    for i, sec in ipairs(sections) do
        local secBox = bBottomBar:box({x=(i-1)*spacing + 5, y=5})
        secBox:label({text=sec.label, x=0, y=0, font=FS.FONT_6, color=titleGreyColor})
        secBox:label({text=sec.value, x=0, y=12, font=FS.FONT_12, color=sec.color})
    end
end

local function updateCraftName(wgt)
    wgt.values.craft_name = string.gsub(model.getInfo().name, "^>", "")
end

local function updateTimeCount(wgt)
    local t1 = model.getTimer(timerNumber - 1)
    local time_str, isNegative = formatTime(wgt, t1)
    wgt.values.timer_str = time_str
end

local function updateRpm(wgt)
    local Hspd = getValue("Hspd")
    if inSimu then Hspd = 1800 end
    wgt.values.rpm = Hspd
    wgt.values.rpm_str = string.format("%s",Hspd)
end

local function updateCell(wgt)
    local vbat = getValue("RxBt") or getValue("Vbat")  -- Main battery voltage
    local vcel = getValue("Cels") or getValue("Vcel")  -- Cell voltage (lowest cell)

    if inSimu then
        vbat = 22.2
        vcel = 3.66
    end

    -- Calculate cell percentage based on single cell voltage
    local cellPercent = 0
    if vcel and vcel > 0 then
        -- Standard LiPo voltage range: 3.0V (0%) to 4.2V (100%)
        cellPercent = math.max(0, math.min(100, ((vcel - 3.0) / 1.2) * 100))
    end

    wgt.values.vbat = vbat or 0
    wgt.values.vcel = vcel or 0
    wgt.values.cell_percent = math.floor(cellPercent)
    wgt.values.volt = (wgt.options.showTotalVoltage == 1) and (vbat or 0) or (vcel or 0)
    wgt.values.cellColor = (vcel and vcel < 3.5) and RED or lcd.RGB(0x00963A) --GREEN
end

local function updateCurr(wgt)
    local curr = getValue("Curr") or 0
    
    if curr > wgt.values.curr then
        wgt.values.curr = curr
    end

    wgt.values.curr_str = string.format("%.2fA", wgt.values.curr)
end

local function updateBottomBarTelemetry(wgt)
    -- Min Voltage - Use Cels (lowest cell voltage)
    local minVolt = getValue("Cels") or 0
    if minVolt > 0 and (wgt.values.min_volt == 0 or minVolt < wgt.values.min_volt) then
        wgt.values.min_volt = minVolt
        flightData.minVoltage = minVolt  -- Track for logging
    end

    -- Armed status - Use ARM sensor with fallback to 1RST
    local armValue = getValue("ARM") or getValue("1RST") or 0
    wgt.values.armed = armValue > 0

    -- Battery percentage - Calculate from cell voltage
    local cellVolt = getValue("Cels") or 0
    if cellVolt > 0 then
        -- Standard LiPo voltage range: 3.0V (0%) to 4.2V (100%)
        wgt.values.batt_percent = math.max(0, math.min(100, math.floor(((cellVolt - 3.0) / 1.2) * 100)))
    else
        wgt.values.batt_percent = 0
    end

    -- Flight mode - Get from RTE# sensor (flight controller reported mode)
    wgt.values.flight_mode = getValue("RTE#") or 1

    -- Governor state - Get from GOV sensor
    local govState = getValue("GOV") or 1
    wgt.values.gov_state = gov_state_names[govState] or "UNKNOWN"

    -- RSSI - Get from ELRS telemetry
    local rssi = getValue("RSSI") or getValue("1RSS") or getValue("2RSS") or 0
    wgt.values.rssi = rssi

    -- Used capacity (mAh) - Get from current consumption
    local usedMah = getValue("Cnsp") or getValue("Capa") or 0
    wgt.values.usedCapacity = usedMah
    flightData.usedCapacity = usedMah  -- Track for logging

    -- Track maximum values for flight logging
    local current = getValue("Curr") or 0
    if current > flightData.maxCurrent then
        flightData.maxCurrent = current
    end

    local rpm = getValue("Hspd") or 0
    if rpm > flightData.maxRPM then
        flightData.maxRPM = rpm
    end

    -- Calculate max power
    local vbat = getValue("RxBt") or getValue("Vbat") or 0
    local maxPow = vbat * current
    if maxPow > flightData.maxPower then
        flightData.maxPower = math.floor(maxPow)
    end

    -- Track minimum BEC voltage
    local becVolt = getValue("Vbec") or 0
    if becVolt > 0 and (flightData.minBEC == 0 or becVolt < flightData.minBEC) then
        flightData.minBEC = becVolt
    end
end

-- Enhanced timer functions
local function startTimer()
    T_Ssecond = getRtcTime() - T_0 + T_P
    T_MM = string.format("%02d", math.floor(T_Ssecond / 60))
    T_SS = string.format("%02d", math.floor(T_Ssecond % 60))
end

local function pauseTimer()
    T_P = T_Ssecond
    T_0 = getRtcTime()
end

local function timerTips()
    if wgt.values.armed then
        if tonumber(T_MM) > timerTipsNum then
            timerTipsNum = tonumber(T_MM)
            playNumber(timerTipsNum, 36)  -- Voice announcement
        end
    end
end

-- Flight data logging
local function writeFlightLog()
    local deviceDate = getDateTime()
    flightData.date = string.format("%04d%02d%02d", deviceDate.year, deviceDate.mon, deviceDate.day)
    flightData.modelName = model.getInfo().name
    flightData.flightTime = T_MM .. ":" .. T_SS
    flightData.flightCount = flightCount

    local filename = "/LOGS/RFLog_" .. flightData.date .. ".csv"
    local logFile = io.open(filename, "a")
    
    if logFile then
        local logData = {
            flightData.date,
            flightData.modelName,
            flightData.flightTime,
            flightData.flightCount,
            flightData.usedCapacity,
            string.format("%.1f", flightData.minVoltage),
            string.format("%.1f", flightData.maxCurrent),
            flightData.maxPower,
            flightData.maxRPM,
            string.format("%.1f", flightData.minBEC)
        }
        
        for i, data in ipairs(logData) do
            io.write(logFile, data .. "|")
        end
        io.write(logFile, "\n")
        io.close(logFile)
    end
end

local function updateImage(wgt)
    local newCraftName = wgt.values.craft_name
    if newCraftName == wgt.values.img_craft_name_for_image then
        return
    end

    local imageName = baseDir.."/img/"..newCraftName..".png"

    if isFileExist(imageName) == false then
        imageName = "/IMAGES/".. model.getInfo().bitmap

        if imageName == "" or isFileExist(imageName) ==false then
            imageName = baseDir.."img/rf2_logo.png"
        end
    end

    if imageName ~= wgt.values.img_last_name then
        -- image replacment
        local isizew=150
        local isizeh=100

        img_box:clear()
        img_box:image({file=imageName, x=0, y=0, w=isizew, h=isizeh, fill=false})

        wgt.values.img_last_name = imageName
        wgt.values.img_craft_name_for_image = newCraftName
    end
end

local function resetWidgetValues(wgt)
    wgt.values = {
        craft_name = "Not connected",
        timer_str = "--:--",
        rpm = 0,
        rpm_str = "0",
        vbat = 0,
        vcel = 0,
        cell_percent = 0,
        volt = 0,
        curr = 0,
        curr_str = "0",
        min_volt = 0,
        batt_percent = 0,
        armed = false,
        flight_mode = 1,
        rssi = 0,
        usedCapacity = 0,
        img_last_name = "---",
        img_craft_name_for_image = "---",
    }
end

-- Enhanced refresh function
local function refreshUI(wgt)
    updateCraftName(wgt)
    updateTimeCount(wgt)
    updateRpm(wgt)
    updateCell(wgt)
    updateCurr(wgt)
    updateBottomBarTelemetry(wgt)
    updateImage(wgt)
    
    -- Enhanced timer and logging
    if wgt.is_connected then
        startTimer()
        timerTips()
    else
        pauseTimer()
    end
end

---------------------------------------------------------------------------------------

local function update(wgt, options)
    if (wgt == nil) then return end
    wgt.options = options
    -- wgt.not_connected_error = "Not connected"
    resetWidgetValues(wgt)
    build_ui_fancy(wgt)
    return wgt
end

local function create(zone, options)
    wgt.zone = zone
    wgt.options = options
    resetWidgetValues(wgt)
    return update(wgt, options)
end

local function background(wgt)
end

-- Enhanced refresh function with flight logging
local function refresh(wgt, event, touchState)
    if (wgt == nil) then return end

    -- Handle touch events for flight summary
    if showFlightSummary and touchState and touchState.x and touchState.y then
        local modalW = 300
        local modalH = 200
        local modalX = (LCD_W - modalW) / 2
        local modalY = (LCD_H - modalH) / 2
        
        -- Check if touch is on close button
        local closeButtonW = 20
        local closeButtonH = 20
        local closeButtonX = modalX + modalW - closeButtonW - 5
        local closeButtonY = modalY + 5
        
        if touchState.x >= closeButtonX and touchState.x <= closeButtonX + closeButtonW and
           touchState.y >= closeButtonY and touchState.y <= closeButtonY + closeButtonH then
            showFlightSummary = false
            return
        end
    end

    local wasConnected = wgt.is_connected
    wgt.is_connected = getRSSI() > 0

    if wgt.is_connected == false then
        -- Connection lost - log flight data if flight was longer than 30 seconds
        if wasConnected and T_Ssecond > 30 then
            flightCount = flightCount + 1
            writeFlightLog()
            showFlightSummary = true
        end
        
        -- Reset flight data
        flightData = {
            date = "",
            modelName = "",
            flightTime = 0,
            flightCount = 0,
            usedCapacity = 0,
            minVoltage = 0,
            maxCurrent = 0,
            maxPower = 0,
            maxRPM = 0,
            minBEC = 0
        }
        timerTipsNum = 0
        resetWidgetValues(wgt)
        return
    end

    -- Initialize timer on first connection
    if not wasConnected and wgt.is_connected then
        T_0 = getRtcTime()
        T_P = 0
        T_Ssecond = 0
        showFlightSummary = false
    end

    refreshUI(wgt)
end

return {create=create, update=update, background=background, refresh=refresh}