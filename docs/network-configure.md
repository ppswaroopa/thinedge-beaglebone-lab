# BeagleBone Black Wi-Fi Configuration - WiFI Dongle

```bash
# 1. Verify the USB Wi-Fi dongle is detected by the hardware
lsusb
# 2. Enter the interactive ConnMan network configuration utility
sudo connmanctl
# 3. Inside the connmanctl menu (prompt changes to connmanctl>), run:
enable wifi
# 4. Trigger a scan for local wireless networks (wait 3-5 seconds after running)
scan wifi
# 5. List all discovered networks and copy the long 'wifi_...' string for your router
services
# 6. Enable the password input agent to securely process your Wi-Fi key
agent on
# 7. Connect to your network (replace the string below with your copied service string)
connect wifi_xxxxxxxxxxxx_xxxxxxxxxxxxxxxxxxxx_managed_psk
# 8. Type your Wi-Fi password when prompted, then exit the utility once connected
quit
# 9. Verify your new wireless IP address on the wlan0 interface
ip a show wlan0
```

## Diagnostics

* ping -c 3 google.com — Checks if board has active internet access.
* systemctl status connman — Checks if the underlying network management service is running properly.
