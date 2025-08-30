# WireGuard VPN in Android "Terminal" App 
##(com.android.virtualization.terminal)

Script to install and run a **WireGuard VPN connection** inside the Android **Terminal App** (`com.android.virtualization.terminal`) on Google Pixel and similar devices.  
This project fills the gap where no official documentation exists for VPNs inside this virtualized environment.

## Why?
Android VPN apps (Mullvad, ProtonVPN, IVPN, etc.) tunnel app traffic on Android.  
The **Terminal App** runs a **virtualized Linux VM (Debian/Ubuntu via AVF)** with its own network stack — so host VPNs do **not** affect it.  
The Terminal App **completely bypasses any existing VPN connection** on the smartphone.  
Therefore, if you want traffic from inside the Terminal App to be tunneled, you must establish a **separate VPN connection inside the VM itself**.  

This has a major advantage:  
→ You can run **two separate VPNs in parallel** — one for your Android device, and one for your Terminal App (e.g. different providers, routes or countries).

This script automates exactly that.

## Features
- Install dependencies (`wireguard-tools`, `wireguard-go`, `resolvconf`, `curl`)
- Import WireGuard `.conf` from **any VPN provider** (Mullvad, ProtonVPN, IVPN, …)
- Bring up/down the tunnel with `wg-quick`
- Show peer status and current public IP
- Optional autostart with systemd (`wg-quick@wg0`)
- Kernel module or **userspace** fallback (`wireguard-go`)
- Works great on **Debian/Ubuntu inside com.android.virtualization.terminal**

## Requirements
- Android **Terminal App**: `com.android.virtualization.terminal`
- Debian/Ubuntu running inside that app
- A VPN provider that supports **WireGuard**
- A downloaded **Linux/WireGuard** config file (`.conf`)

## Installation
Clone the repo inside your Debian VM:
```bash
git clone https://github.com/s4mba-dev/wireguard-virt-terminal.git
cd wireguard-virt-terminal
chmod +x wg-helper.sh
```

Install dependencies:
```bash
./wg-helper.sh install
```

Import your provider config (downloaded for **Linux/WireGuard**):
```bash
./wg-helper.sh import /path/to/my-vpn.conf
```

Start VPN:
```bash
./wg-helper.sh up
```

Check status:
```bash
./wg-helper.sh status
```

Stop VPN:
```bash
./wg-helper.sh down
```

## Example (Mullvad)
```bash
./wg-helper.sh install
./wg-helper.sh import ~/download/mullvad-se-stockholm.conf
./wg-helper.sh up
./wg-helper.sh status
```

## FAQ

**Why doesn’t the Android VPN app affect Terminal App traffic?**  
Because the Terminal App runs a Linux VM with a separate network stack. Android VPNs don’t tunnel VM traffic. You need a VPN **inside** the VM.  
Also, the Terminal App bypasses any active VPN on the smartphone.

**Will I lose access to my Debian when the VPN is active?**  
No. You will still reach it via the local virtual IP (e.g., `10.130.x.x`).

**Which platform should I select when downloading configs?**  
Choose **Linux / WireGuard** configs from your provider.

## License
MIT License © 2025 s4mba (s4mba-dev)
You are free to use, modify and distribute this script, including commercially, as long as attribution is preserved.
