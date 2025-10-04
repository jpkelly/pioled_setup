#!/usr/bin/env bash
set -euo pipefail

# -------- Detect user/home --------
APP_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$APP_USER" | cut -d: -f6)"
APP_PATH="$HOME_DIR/pioled_status.py"
SERVICE_NAME="pioled-status.service"

echo "Using user: $APP_USER"
echo "Home dir : $HOME_DIR"

# -------- Packages --------
sudo apt update
sudo apt install -y python3-pip python3-pil fonts-dejavu i2c-tools raspi-config
# CircuitPython SSD1306 driver
sudo pip3 install --break-system-packages adafruit-circuitpython-ssd1306

# -------- Enable I2C & permissions --------
sudo raspi-config nonint do_i2c 0 || true
sudo usermod -aG i2c "$APP_USER" || true

# -------- Write Python app --------
cat > "$APP_PATH" <<'PY'
#!/usr/bin/env python3
# pioled_status.py — PiOLED 128x32 status screen for Raspberry Pi 5
# Shows: hostname.local + IPv4 (page 1), RAM + Disk (page 2)

import time
import board
import busio
import socket
import subprocess
import shutil
import re
import signal
import sys
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306

# ---------- Config ----------
WIDTH, HEIGHT = 128, 32
I2C_ADDR = 0x3C
FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_SIZE = 12
PAGE_DURATION = 5  # seconds per page
DISK_PATH = "/"   # mount point to report

# ---------- Display setup ----------
i2c = busio.I2C(board.SCL, board.SDA)
display = adafruit_ssd1306.SSD1306_I2C(WIDTH, HEIGHT, i2c, addr=I2C_ADDR)

# 1-bit canvas (the path confirmed to render cleanly on your setup)
image = Image.new("1", (WIDTH, HEIGHT))
draw = ImageDraw.Draw(image)

# ---------- Font ----------
try:
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
except Exception:
    print(f"[PiOLED] WARNING: Could not load {FONT_PATH}. Falling back to default bitmap font.", file=sys.stderr)
    font = ImageFont.load_default()

# ---------- Utils ----------
def clear_oled():
    display.fill(0)
    display.show()

def signal_handler(sig, frame):
    clear_oled()
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def get_ipv4_address():
    """Return first IPv4 from `hostname -I`, else 'Not Connected'."""
    try:
        ip_output = subprocess.check_output(["hostname", "-I"], text=True).strip()
        ipv4_addrs = [ip for ip in ip_output.split() if "." in ip and ":" not in ip]
        return ipv4_addrs[0] if ipv4_addrs else "Not Connected"
    except Exception:
        return "Not Connected"

def get_hostname_local():
    host = socket.gethostname()
    return host if host.endswith(".local") else host + ".local"

def _read_meminfo():
    d = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                m = re.match(r"^(\w+):\s+(\d+)\s+kB", line)
                if m:
                    d[m.group(1)] = int(m.group(2)) * 1024  # bytes
    except Exception:
        pass
    return d

def get_ram_usage():
    mi = _read_meminfo()
    total = mi.get("MemTotal", 0)
    avail = mi.get("MemAvailable", 0)
    used = max(total - avail, 0)
    pct = (used / total * 100.0) if total else 0.0
    return used, total, pct

def get_disk_usage(path=DISK_PATH):
    total, used, free = shutil.disk_usage(path)
    pct = (used / total * 100.0) if total else 0.0
    return used, total, pct

def human_bytes(n):
    gib = 1024**3
    mib = 1024**2
    if n >= gib:
        return f"{n / gib:.1f}G"
    return f"{n / mib:.0f}M"

def trim_to_width(text, font, max_width_px):
    """Ellipsize string using pixel width (… if too long)."""
    if draw.textlength(text, font=font) <= max_width_px:
        return text
    ell = "…"
    if draw.textlength(ell, font=font) > max_width_px:
        return ""  # nothing fits
    lo, hi = 0, len(text)
    while lo < hi:
        mid = (lo + hi) // 2
        cand = text[:mid] + ell
        if draw.textlength(cand, font=font) <= max_width_px:
            lo = mid + 1
        else:
            hi = mid
    return text[:max(0, lo - 1)] + ell

def draw_two_lines(line1, line2):
    draw.rectangle((0, 0, WIDTH, HEIGHT), outline=0, fill=0)
    # For ~15pt on 32px panel, 0 and 16 line spacing looks crisp
    draw.text((0, 0),  line1, font=font, fill=255)
    draw.text((0, 16), line2, font=font, fill=255)
    display.image(image)
    display.show()

# ---------- Main loop ----------
clear_oled()
page = 0

while True:
    host = get_hostname_local()
    ip = get_ipv4_address()

    r_used, r_total, r_pct = get_ram_usage()
    d_used, d_total, d_pct = get_disk_usage(DISK_PATH)

    # Compose strings
    host_disp = trim_to_width(host, font, WIDTH) or host[:0]
    ip_disp   = trim_to_width(ip,   font, WIDTH) or ip[:0]
    line_ram  = f"M {human_bytes(r_used)}/{human_bytes(r_total)} {r_pct:3.0f}%"
    line_dsk  = f"D {human_bytes(d_used)}/{human_bytes(d_total)} {d_pct:3.0f}%"
    line_ram  = trim_to_width(line_ram, font, WIDTH)
    line_dsk  = trim_to_width(line_dsk, font, WIDTH)

    if page == 0:
        draw_two_lines(host_disp, ip_disp)
    else:
        draw_two_lines(line_ram, line_dsk)

    time.sleep(PAGE_DURATION)
    page ^= 1
PY

sudo chown "$APP_USER:$APP_USER" "$APP_PATH"
chmod +x "$APP_PATH"

# -------- Write systemd service --------
sudo tee "/etc/systemd/system/$SERVICE_NAME" >/dev/null <<SERVICE
[Unit]
Description=PiOLED 128x32 Status Display
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$HOME_DIR
ExecStart=/usr/bin/python3 $APP_PATH
Restart=always
RestartSec=3
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SERVICE

# -------- Enable + start service --------
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "------------------------------------------------------------"
echo "PiOLED service installed and started."
echo " Script : $APP_PATH"
echo " Service: $SERVICE_NAME"
echo "Check   : sudo systemctl status $SERVICE_NAME"
echo "Logs    : journalctl -u $SERVICE_NAME -f"
echo "Note    : If I²C was just enabled, a reboot may be required."
echo "------------------------------------------------------------"
