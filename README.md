# pioled_setup

A setup utility for configuring PiOLED displays on Raspberry Pi devices. This tool helps you quickly get your PiOLED display up and running with minimal effort.

## Project Description

`pioled_setup` provides a single setup script to configure an Adafruit PiOLED (SSD1306 128x32 OLED) display on a Raspberry Pi. It installs all required packages, enables I2C, deploys a Python status script, and creates a systemd service so the display starts automatically on boot.

The display cycles through three pages every 5 seconds:

| Page | Line 1 | Line 2 |
|------|--------|--------|
| 1 | hostname.local | IPv4 address |
| 2 | RAM used/total % | Disk used/total % |
| 3 | SSID &lt;network&gt; | IP &lt;wlan0 address&gt; |

## Installation

Run the one-liner on your Raspberry Pi:

```bash
curl -fsSL https://raw.githubusercontent.com/jpkelly/pioled_setup/main/setup.sh | sudo bash
```

The script will:
- Install required system packages and the Adafruit SSD1306 driver
- Enable I2C
- Write the status display script to `~/pioled_status.py`
- Create and enable a `pioled-status` systemd service

After installation, reboot to start the display:

```bash
sudo reboot
```

## Updating

To update an existing installation, re-run the install command:

```bash
curl -fsSL https://raw.githubusercontent.com/jpkelly/pioled_setup/main/setup.sh | sudo bash
```

Then restart the service:

```bash
sudo systemctl restart pioled-status.service
```

## Requirements

- Raspberry Pi running Raspberry Pi OS (or compatible)
- Adafruit PiOLED (SSD1306 128x32 OLED) display
- I2C enabled on Raspberry Pi
- Python 3.6+

---

For further details, see individual script comments and the Adafruit PiOLED [guide](https://learn.adafruit.com/adafruit-pioled-128x32-mini-oled-for-raspberry-pi/usage).
