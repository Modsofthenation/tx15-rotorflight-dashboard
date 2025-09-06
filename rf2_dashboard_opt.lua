local M = {

    options = {
        {"showTotalVoltage", BOOL  , 0      }, -- 0=Show as average Lipo cell level, 1=show the total voltage (voltage as is)
        {"textColor"       , COLOR , WHITE  }, -- Main text color
        {"showBottomBar"   , BOOL  , 1      }, -- 0=Hide bottom bar, 1=Show bottom bar
        {"tempTop"         , VALUE , 100, 50, 150}, -- Maximum temperature for percentage calculation
        {"minVoltAlarm"    , VALUE , 35, 30, 52}, -- Minimum voltage alarm threshold (in 0.1V, so 35 = 3.5V, max 5.2V for 12S)
        {"battLowPercent"  , VALUE , 20, 10, 50}, -- Battery low percentage threshold
    },

    translate = function(name)
        local translations = {
            showTotalVoltage="Show Total Voltage",
            textColor="Text Color",
            showBottomBar="Show Bottom Status Bar",
            tempTop="Max Temperature",
            minVoltAlarm="Min Voltage Alarm (0.1V)",
            battLowPercent="Battery Low Threshold (%)",
        }
        return translations[name]
    end

}

return M
