# RF2 Dashboard for TX15 (Current Behavior)

Full-screen EdgeTX Lua widget for Rotorflight telemetry on Radiomaster TX15 Max. Based on [rf2_widget_dash](https://github.com/nhutlv01/rf2_widget_dash) with TX15-focused improvements.

## Requirements
- Radiomaster TX15 Max, EdgeTX 3.0.0
- Rotorflight 2.2.1
- SD card path: `/WIDGETS/rf2_dashboard/`

## Telemetry Inputs
- **Hspd**: RPM
- **RxBt`/`Vbat**: Battery voltage (total)
- **Cels`/`Vcel**: Lowest cell voltage
- **Curr**: Current (tracks max)
- **RTE#**: Flight mode (from FC)
- **ARM`/`1RST**: Armed status
- **RSSI`/`1RSS`/`2RSS**: Signal strength
- **Cnsp`/`Capa**: Used capacity (mAh)

## Calculations
- Cell%/Batt% from `Cels`: ((V − 3.0) / 1.2) × 100, clamped 0–100
- Armed if `ARM` or `1RST` > 0
- Max current/power tracked (power = `RxBt` × `Curr`)
- Timer formats: MM:SS / HH:MM:SS / Dd HH:MM:SS (supports negative)

## UI Layout
- Background: dark (#111111)
- Timer: top-left (XXL)
- RPM: left, below timer
- Voltage bar: left center (200×50), red < 3.5V cell
- Current (max): right side
- Craft image: top-right (bordered), auto: craft → model bitmap → default
- Craft name: under image
- Bottom bar: full width, 45px, black with white top border
  - Sections (weighted columns): Min V, Status (double width), Batt %, Flight Mode, RSSI, mAh

### Bottom Bar Logic
- Min V: red if < 3.3V
- Status: ARM (green) / DISARM (red)
- Batt %: red ≤ 20%, yellow ≤ 40%, else text color
- RSSI: red < −100, yellow < −90, green ≥ −90

## Behavior
- Connected if `getRSSI() > 0`; disconnected shows overlay
- Image updates when model changes
- Flight log written on disconnect after > 30s; flight summary modal shown
- Simulation mode provides test values when simulator detected

## Options
- `showTotalVoltage` (0/1): total vs cell voltage
- `textColor`: main text color
- `showBottomBar` (0/1): toggle bottom bar
- Thresholds used in display logic: `tempTop`, `minVoltAlarm`, `battLowPercent`

## Install
1. Copy this repo (or the `rf2_dashboard` folder) to SD: `/WIDGETS/`
2. Add the widget to a full-screen view in EdgeTX
3. Ensure sensors are discovered and named as in Telemetry Inputs

## Files
- `rf2_dashboard.lua` (main)
- `rf2_dashboard_opt.lua` (options)
- `main.lua` (entry)
- `img/` assets

Note: Bottom bar Status column is wider (weighted layout).