# Wi-Fi Direct (P2P) Connection Guide  
**for Ground Station (Group Owner)**

---

## 🗂 Overview

This document explains how to establish a **Wi-Fi Direct (P2P)** link between a **Ground Station (Group Owner)** and a **Client (Drone / Device)**.  
The setup uses `wpa_supplicant` and `NetworkManager` on Linux.

---

## 📶 P2P Connection Flow

```mermaid
sequenceDiagram
    participant GS as Ground Station (GO)
    participant NM as NetworkManager
    participant WS as wpa_supplicant
    participant CL as Client Device

    Note over GS,CL: Wi-Fi Direct (P2P) WPS PBC Connection Flow

    GS->>NM: Stop and mask global wpa_supplicant.service
    GS->>GS: Set unmanaged devices in /etc/NetworkManager/conf.d/unmanaged.conf
    GS->>WS: Create /etc/wpa_supplicant/wpa_supplicant-ground.conf
    GS->>WS: Edit systemd unit: wpa_supplicant@wlo1.service
    GS->>WS: Enable and start wpa_supplicant@wlo1
    GS->>NM: Restart NetworkManager

    GS->>WS: Flush existing P2P sessions (p2p_flush)
    GS->>WS: Create new group (p2p_group_add freq=2437)
    WS->>GS: Interface appears as p2p-wlo1-0
    GS->>CL: Waits for WPS PBC connection
    CL->>GS: Initiates WPS PBC join request
    GS->>CL: Completes connection, establishes P2P link

    GS->>GS: Assign IP 192.168.49.1/24 to p2p-wlo1-0
    CL->>CL: Assign IP 192.168.49.x/24
    Note over GS,CL: Communication channel established
```

---

## 🧭 Step-by-Step Setup

### 1️⃣ Disable global wpa_supplicant and configure unmanaged interfaces

```bash
sudo systemctl stop wpa_supplicant.service
sudo systemctl mask wpa_supplicant.service

echo "[keyfile]
unmanaged-devices=interface-name:wlo*;interface-name:p2p-*" | sudo tee /etc/NetworkManager/conf.d/unmanaged.conf
```

---

### 2️⃣ Create Ground Station wpa_supplicant config

```bash
echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
device_name=GroundStation
device_type=1-0050F204-1
config_methods=virtual_push_button physical_display keypad" | sudo tee /etc/wpa_supplicant/wpa_supplicant-ground.conf
```

---

### 3️⃣ Edit and enable service unit

```bash
sudo systemctl edit wpa_supplicant@wlo1.service
```

```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/wpa_supplicant -Dnl80211 -iwlo1 -c/etc/wpa_supplicant/wpa_supplicant-ground.conf
```

Then reload and enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now wpa_supplicant@wlo1.service
sudo systemctl restart NetworkManager
```

---

### 4️⃣ Flush any existing sessions

```bash
sudo wpa_cli -i wlo1 p2p_cancel
sudo wpa_cli -i wlo1 p2p_stop_find
sudo wpa_cli -i wlo1 p2p_flush
sudo pkill -f wpa_supplicant
sudo ip link set wlo1 down
sudo ip link set wlo1 up
sudo systemctl restart wpa_supplicant@wlo1
```

---

### 5️⃣ Start Group Owner (GO)

```bash
sudo wpa_cli -i wlo1 p2p_group_add freq=2437
```

Check the P2P interface:

```bash
iw dev $(basename /sys/class/net/p2p-wlo1-*) info
sudo wpa_cli -i "$(basename /sys/class/net/p2p-wlo1-*)" status
ip addr show $(ls /sys/class/net/ | grep ^p2p-wlo1-)
```

---

### 6️⃣ Accept client connection

```bash
sudo wpa_cli -p /var/run/wpa_supplicant -i p2p-wlo1-0 wps_pbc
```

---

### 7️⃣ Verify connection

```bash
iw dev $(basename /sys/class/net/p2p-wlo1-*) station dump
sudo wpa_cli -i wlo1 p2p_peer da:3a:dd:09:24:2a
```

---

### 8️⃣ Assign IP address to GO

```bash
sudo ip addr add 192.168.49.1/24 dev p2p-wlo1-0
```

---

### 9️⃣ Monitor logs

```bash
sudo journalctl -u wpa_supplicant@wlo1 -f
```

---

## 🧩 Example Network Topology

```mermaid
graph LR
    subgraph GroundStation["Ground Station (GO)"]
        WLO["wlo1 (Wi-Fi Interface)"]
        P2P["p2p-wlo1-0 (P2P Group)"]
    end

    subgraph Client["Client Device"]
        WLAN["wlan0 (P2P Client)"]
    end

    WLO --> P2P
    P2P <---> WLAN
    P2P -->|"192.168.49.1/24"| WLAN
```

---

## 📜 License

MIT © 2025 FPV Japan / GroundStation Project
