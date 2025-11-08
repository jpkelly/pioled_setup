# pioled_setup

A setup utility for configuring PiOLED displays on Raspberry Pi devices. This tool helps you quickly get your PiOLED display up and running with minimal effort.

## Project Description

`pioled_setup` provides scripts and instructions to set up and use Adafruit PiOLED (SSD1306 128x32 OLED) displays with a Raspberry Pi. It automates installing required libraries, setting up I2C, and running test scripts to verify your display is working.

## Installation Instructions

Run
```
curl -fsSL https://raw.githubusercontent.com/jpkelly/pioled_setup/main/setup.sh | sudo bash
```

1. **Enable I2C on your Raspberry Pi:**
   - Run `sudo raspi-config`
   - Go to `Interfacing Options` > `I2C` and enable it.
   - Reboot if prompted.

2. **Clone this repository:**
   ```bash
   git clone https://github.com/jpkelly/pioled_setup.git
   cd pioled_setup
   ```

3. **Install dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y python3-pip python3-dev i2c-tools
   pip3 install -r requirements.txt
   ```

## Usage Examples

After installation, you can test your PiOLED display:

```bash
python3 pioled_test.py
```

This command will run a demo script that displays sample text and graphics on your PiOLED.

## Requirements/Dependencies

- Raspberry Pi running Raspberry Pi OS (or compatible)
- Adafruit PiOLED (SSD1306 128x32 OLED) display
- I2C enabled on Raspberry Pi
- Python 3.6+
- System packages:
  - `python3-pip`
  - `python3-dev`
  - `i2c-tools`
- Python packages (see `requirements.txt`):
  - `Adafruit-SSD1306`
  - `Pillow`
  - `RPi.GPIO`
  - `smbus`

---

For further details, see individual script comments and the Adafruit PiOLED [guide](https://learn.adafruit.com/adafruit-pioled-128x32-mini-oled-for-raspberry-pi/usage).
