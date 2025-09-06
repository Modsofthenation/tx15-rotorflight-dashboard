# RF2 Dashboard Widget Specification

## Project Overview

**Project Name:** RF2 Dashboard for TX15  
**Version:** 1.0.0  
**Target Platform:** EdgeTX 3.0.0 on Radiomaster TX15 Max  
**Flight Controller:** Rotorflight 2.2.1 with custom telemetry options  
**Widget Type:** Full-screen dashboard widget  
**Base Project:** Extended from [rf2_widget_dash](https://github.com/nhutlv01/rf2_widget_dash)

## Hardware Requirements

- **Transmitter:** Radiomaster TX15 Max
- **Firmware:** EdgeTX 3.0.0
- **Flight Controller:** Rotorflight 2.2.1
- **Telemetry:** Custom telemetry options enabled
- **SD Card:** Required for widget storage and image assets

## Software Architecture

### Core Components

1. **Main Widget File:** `rf2_dashboard.lua` (376 lines)
2. **Options Configuration:** `rf2_dashboard_opt.lua` (27 lines)
3. **Visual Assets:** Image directory with connection status indicators
4. **Dependencies:** EdgeTX Lua widget framework

### Widget Structure

The widget follows EdgeTX's standard widget architecture with these key functions:
- `create()` - Widget initialization
- `update()` - Configuration updates
- `refresh()` - Real-time data updates
- `background()` - Background processing

## Telemetry Data Sources

### Primary Telemetry Sensors

| Sensor ID | Description | Usage | Fallback | Simulation Value |
|-----------|-------------|-------|----------|------------------|
| `Hspd` | Motor RPM | Main RPM display | None | 1800 |
| `RxBt`/`Vbat` | Battery voltage | Total battery voltage | `Vbat` | 22.2V |
| `Cels`/`Vcel` | Cell voltage | Lowest cell voltage | `Vcel` | 3.66V |
| `Curr` | Current consumption | Max current tracking | None | 0A |
| `RTE#` | Flight mode (FC reported) | Flight mode display | None | 0 |
| `ARM` | Flight mode (TX) | Armed status | `1RST` | 0 |
| `RSSI` | Signal strength | Connection quality | `1RSS`, `2RSS` | 0 |
| `Cnsp`/`Capa` | Capacity used | mAh consumption | `Capa` | 0 |

### Flight Mode Display

The flight mode is now sourced from the `RTE#` telemetry sensor, which reports the actual flight mode as determined by the flight controller. This provides more accurate mode information compared to transmitter-side mode detection.

**Mode Mapping:**
- `RTE#` value 1 → "Flight profile/rate 1"
- `RTE#` value 2 → "Flight profile/rate 2" 
- `RTE#` value 3 → "Flight profile/rate 3"

**Benefits:**
- More accurate flight mode reporting
- Reflects actual flight controller state
- Better synchronization with flight controller behavior
- Reduces discrepancies between TX and FC mode states

### Calculated Values

- **Cell Percentage:** Based on 3.0V-4.2V LiPo range using formula: `((vcel - 3.0) / 1.2) * 100`
- **Battery Percentage:** Derived from cell voltage using same formula
- **Armed Status:** Boolean from flight mode value (> 0 = armed)
- **Flight Mode Names:** Mapped from numeric values to human-readable names
- **Max Current:** Tracks peak current consumption during flight

## User Interface Layout

### Main Display Areas

#### 1. Timer Section (Top-left)
- **Position:** x=20, y=10
- **Font:** 38pt (XXLSIZE)
- **Format:** 
  - < 1 hour: `MM:SS`
  - < 24 hours: `HH:MM:SS`
  - ≥ 24 hours: `Dd HH:MM:SS` or `HH:MM:SS` (configurable)
- **Features:** Supports negative values with `-` prefix

#### 2. RPM Display (Left side)
- **Position:** x=20, y=160
- **Label:** "RPM" (6pt font, grey)
- **Value:** Real-time motor RPM (16pt font)
- **Color:** Configurable text color

#### 3. Voltage Bar (Center-left)
- **Position:** x=20, y=72
- **Dimensions:** 200x50px horizontal progress bar
- **Features:**
  - Shows cell percentage with color coding
  - Displays voltage value (total or per-cell based on config)
  - Rounded corners (6px radius)
  - White border (3px thickness)
- **Color Logic:**
  - Green: Normal voltage (≥3.5V)
  - Red: Low voltage (<3.5V)

#### 4. Current Display (Right side)
- **Position:** x=150, y=160
- **Label:** "Max Current" (6pt font, grey)
- **Value:** Peak current consumption (16pt font)
- **Format:** `X.XXA`

#### 5. Craft Image (Top-right)
- **Position:** x=310, y=20
- **Dimensions:** 150x120px image area
- **Border:** White, 4px thickness, 15px rounded corners
- **Image Priority:**
  1. Craft-specific image: `/img/{craft_name}.png`
  2. Model bitmap: `/IMAGES/{model_bitmap}`
  3. Default: `/img/rf2_logo.png`
- **Connection Status:** Shows "no connection" overlay when disconnected

#### 6. Craft Name (Below image)
- **Position:** x=310, y=142
- **Dimensions:** 150x25px
- **Background:** Dark grey with 200 opacity, 8px rounded corners
- **Text:** Model name (sanitized, removes leading ">")
- **Font:** 8pt

#### 7. Bottom Status Bar (Full width)
- **Position:** x=0, y={zone_height - 45}
- **Height:** 45px
- **Background:** Black with white top border
- **Sections:** 6 equal-width sections with real-time data

##### Bottom Bar Sections

| Section | Label | Value | Color Logic |
|---------|-------|-------|-------------|
| Min V | Min V | `X.XXv` | Red if < 3.3V, else text color |
| Status | Status | ARM/DISARM | Green if armed, Red if disarmed |
| Batt % | Batt % | `XX%` | Red ≤20%, Yellow ≤40%, else text color |
| Mode | Mode | Flight mode name | Text color |
| RSSI | RSSI | `XXdB` | Red <-100, Yellow <-90, Green ≥-90 |
| mAh | mAh | `XXXX` | Text color |

### Color Scheme

- **Background:** Dark grey (#111111)
- **Text:** Configurable (default: White)
- **Labels:** Light grey
- **Borders:** White with rounded corners
- **Status Colors:**
  - Green: Normal/Armed/Good signal
  - Red: Low voltage/Disarmed/Poor signal
  - Yellow: Warning levels
  - Grey: Labels and inactive elements

## Configuration Options

### User-Configurable Settings

| Option | Type | Default | Range | Description |
|--------|------|---------|-------|-------------|
| `showTotalVoltage` | Boolean | 0 | 0/1 | Show total vs per-cell voltage |
| `textColor` | Color | White | Color picker | Main text color |
| `showBottomBar` | Boolean | 1 | 0/1 | Show/hide bottom status bar |
| `tempTop` | Value | 100 | 50-150 | Max temperature for calculations |
| `minVoltAlarm` | Value | 35 | 30-52 | Min voltage alarm (0.1V units) |
| `battLowPercent` | Value | 20 | 10-50 | Battery low threshold (%) |

### Configuration Translation

The widget includes English translations for all configuration options:
- `showTotalVoltage` → "Show Total Voltage"
- `textColor` → "Text Color"
- `showBottomBar` → "Show Bottom Status Bar"
- `tempTop` → "Max Temperature"
- `minVoltAlarm` → "Min Voltage Alarm (0.1V)"
- `battLowPercent` → "Battery Low Threshold (%)"

## Flight Mode Mapping

The widget supports 7 flight modes from Rotorflight 2.2.1:

| Mode Value | Display Name | Description |
|------------|--------------|-------------|
| 0 | ACRO | Acro mode |
| 1 | LEVEL | Level mode |
| 2 | HORI | Horizon mode |
| 3 | RESCUE | Rescue mode |
| 4 | ANGLE | Angle mode |
| 5 | GPS | GPS mode |
| 6 | RTH | Return to Home |
| Other | UNK | Unknown mode |

## Installation Requirements

### File Structure
```
/WIDGETS/rf2_dashboard/
├── rf2_dashboard.lua          # Main widget file
├── rf2_dashboard_opt.lua      # Configuration options
├── main.lua                   # Widget entry point
├── main.luac                  # Compiled main.lua
├── rf2_dashboard.luac         # Compiled main widget
├── rf2_dashboard_opt.luac     # Compiled options
├── README.md                  # Basic documentation
├── SPECIFICATION.md           # This specification
└── img/
    ├── no_connection_wr.png   # No connection indicator
    └── rf2_logo.png           # Default craft image (if exists)
```

### Installation Steps
1. Copy `rf2_dashboard` folder to SD card under `/WIDGETS/`
2. Add widget to fullscreen view in EdgeTX
3. Configure telemetry sensors in Rotorflight
4. Set up custom telemetry options in Rotorflight 2.2.1

## Telemetry Setup Requirements

### Rotorflight 2.2.1 Configuration
- Enable custom telemetry options
- Configure sensor IDs to match widget expectations:
  - `Hspd` for motor RPM
  - `RxBt` or `Vbat` for battery voltage
  - `Cels` or `Vcel` for cell voltage
  - `Curr` for current consumption
  - `FM` for flight mode
  - `RSSI` for signal strength
  - `Cnsp` or `Capa` for capacity used
- Set up proper telemetry rates for real-time updates
- Ensure all required sensors are active

### EdgeTX Configuration
- Verify telemetry sensors are properly mapped
- Check sensor names match widget expectations
- Configure timer for flight time display
- Ensure RSSI calculation is working

## Performance Characteristics

- **Update Rate:** Real-time (limited by telemetry rate)
- **Memory Usage:** Minimal Lua widget footprint
- **CPU Usage:** Low (event-driven updates only)
- **Display Refresh:** On telemetry data changes
- **Simulation Support:** Built-in simulation mode for testing
- **Connection Detection:** Based on RSSI > 0

## Error Handling

### Connection Management
- **Connection Loss:** Displays "no connection" overlay with image
- **RSSI Check:** Uses `getRSSI()` function for connection status
- **Data Reset:** Resets all values to defaults when disconnected

### Data Validation
- **Missing Sensors:** Graceful fallback to default values
- **Invalid Data:** Range checking and validation
- **File Errors:** Fallback to default images
- **Simulation Mode:** Automatic detection and test values

### Fallback Hierarchy
1. **Images:** Craft-specific → Model bitmap → RF2 logo → No connection
2. **Voltage:** `RxBt` → `Vbat`
3. **Cell Voltage:** `Cels` → `Vcel`
4. **RSSI:** `RSSI` → `1RSS` → `2RSS`
5. **Capacity:** `Cnsp` → `Capa`

## Development Notes

### Code Structure
- **Modular Design:** Separate functions for each data update
- **Event-Driven:** Updates only when data changes
- **Simulation Support:** Built-in test mode for development
- **Logging:** Debug logging with `log()` function

### Key Functions
- `buildBlackboxHorz()` - Creates horizontal progress bars
- `formatTime()` - Handles timer formatting with day support
- `updateCraftName()` - Manages craft name display
- `updateImage()` - Handles image loading and fallbacks
- `refreshUI()` - Main update function for all data

### Font Sizes
- **FONT_38 (XXLSIZE):** Timer display
- **FONT_16 (DBLSIZE):** Main values
- **FONT_12 (MIDSIZE):** Bottom bar values
- **FONT_8 (0):** Craft name
- **FONT_6 (SMLSIZE):** Labels

## Future Enhancements

Based on the code structure, potential improvements could include:
- Additional telemetry sensors (GPS, altitude, etc.)
- Customizable layout options
- More flight mode support
- Enhanced visual indicators
- Data logging capabilities
- Multi-language support
- Custom color themes
- Additional image formats
- Sound alerts for warnings

## Troubleshooting

### Common Issues
1. **No Data Display:** Check telemetry sensor configuration
2. **Wrong Images:** Verify image files exist in `/img/` directory
3. **Connection Issues:** Verify RSSI sensor is working
4. **Wrong Flight Modes:** Check Rotorflight flight mode configuration
5. **Voltage Display Issues:** Verify voltage sensor mapping

### Debug Information
- Enable debug logging by checking console output
- Verify sensor values in EdgeTX telemetry screen
- Check file paths and SD card structure
- Ensure proper EdgeTX version compatibility

---

**Last Updated:** $(date)  
**Compatible With:** EdgeTX 3.0.0, Rotorflight 2.2.1, Radiomaster TX15 Max
