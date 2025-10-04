# PiOLED Setup

Automated setup script for PiOLED 128x32 OLED display on Raspberry Pi. Displays real-time system information including hostname, IP address, RAM usage, and disk usage.

## Features

- **System Information Display**: Shows hostname, IP address, RAM, and disk usage on a rotating display
- **Auto-rotating Pages**: Alternates between network info (hostname/IP) and resource usage (RAM/disk) every 5 seconds
- **Systemd Service**: Runs automatically on boot as a system service
- **Clean Display**: Uses TrueType fonts with smart text ellipsization to fit the 128x32 screen
- **Signal Handling**: Gracefully clears the display on shutdown

## Hardware Requirements

- Raspberry Pi (tested on Raspberry Pi 5)
- PiOLED 128x32 OLED display (I²C, SSD1306 driver)
- I²C address: 0x3C (default)

## Installation

1. Clone this repository or download `setup.sh`:
   ```bash
   git clone https://github.com/jpkelly/pioled_setup.git
   cd pioled_setup
   ```

2. Make the setup script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the setup script with sudo:
   ```bash
   sudo ./setup.sh
   ```

The script will:
- Install required packages (Python3, PIL, fonts, I²C tools)
- Enable I²C interface on the Raspberry Pi
- Install the Adafruit CircuitPython SSD1306 driver
- Create a Python application at `~/pioled_status.py`
- Set up and start a systemd service to run the display automatically

**Note**: If I²C was just enabled for the first time, a reboot may be required.

## What Gets Displayed

### Page 1 (Network Information)
- Line 1: Hostname (with `.local` suffix)
- Line 2: IPv4 address (or "Not Connected")

### Page 2 (System Resources)
- Line 1: RAM usage (used/total and percentage)
- Line 2: Disk usage (used/total and percentage)

Pages alternate every 5 seconds.

## Service Management

Check service status:
```bash
sudo systemctl status pioled-status.service
```

View logs:
```bash
journalctl -u pioled-status.service -f
```

Stop the service:
```bash
sudo systemctl stop pioled-status.service
```

Start the service:
```bash
sudo systemctl start pioled-status.service
```

Restart the service:
```bash
sudo systemctl restart pioled-status.service
```

Disable auto-start on boot:
```bash
sudo systemctl disable pioled-status.service
```

Enable auto-start on boot:
```bash
sudo systemctl enable pioled-status.service
```

## Configuration

The Python script (`~/pioled_status.py`) contains configurable parameters at the top:

```python
WIDTH, HEIGHT = 128, 32        # Display dimensions
I2C_ADDR = 0x3C                # I²C address
FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_SIZE = 15                 # Font size in points
PAGE_DURATION = 5              # Seconds per page
DISK_PATH = "/"                # Mount point to report
```

After modifying the script, restart the service:
```bash
sudo systemctl restart pioled-status.service
```

## Troubleshooting

### Display not working
1. Verify I²C is enabled:
   ```bash
   sudo raspi-config nonint do_i2c 0
   sudo reboot
   ```

2. Check if the display is detected:
   ```bash
   sudo i2cdetect -y 1
   ```
   You should see `3c` in the output.

3. Check service logs:
   ```bash
   journalctl -u pioled-status.service -n 50
   ```

### Permission issues
Ensure your user is in the i2c group:
```bash
sudo usermod -aG i2c $USER
```
Then log out and back in, or reboot.

### Display shows garbled text
The script uses the DejaVu Sans font. If it's not available, the script falls back to a default bitmap font. To reinstall fonts:
```bash
sudo apt install --reinstall fonts-dejavu
```

## Uninstall

To remove the service:
```bash
sudo systemctl stop pioled-status.service
sudo systemctl disable pioled-status.service
sudo rm /etc/systemd/system/pioled-status.service
sudo systemctl daemon-reload
rm ~/pioled_status.py
```

## License

This project is provided as-is for use with PiOLED displays on Raspberry Pi.
