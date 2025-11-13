
======================================================================
GO (Ground Station)
======================================================================

sudo systemctl stop wpa_supplicant.service
sudo systemctl mask wpa_supplicant.service

echo "[keyfile]
unmanaged-devices=sinterface-name:wlo*;interface-name:p2p-*" | sudo tee /etc/NetworkManager/conf.d/unmanaged.conf
sudo systemctl restart NetworkManager

echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
device_name=GroundStation
device_type=1-0050F204-1
config_methods=virtual_push_button physical_display keypad" | sudo tee /etc/wpa_supplicant/wpa_supplicant-ground.conf

sudo systemctl edit wpa_supplicant@wlo1.service
```
[Service]
ExecStart=
ExecStart=/usr/sbin/wpa_supplicant -Dnl80211 -iwlo1 -c/etc/wpa_supplicant/wpa_supplicant-ground.conf
```

sudo systemctl daemon-reload
sudo systemctl enable --now wpa_supplicant@wlo1.service

======================================================================

sudo systemctl status NetworkManager
sudo systemctl status wpa_supplicant.service
sudo systemctl status wpa_supplicant@wlo1.service

======================================================================

sudo wpa_cli -i wlo1 p2p_cancel
sudo wpa_cli -i wlo1 p2p_stop_find
sudo wpa_cli -i wlo1 p2p_flush
sudo pkill -f wpa_supplicant
sudo ip link set wlo1 down
sudo ip link set wlo1 up
sudo systemctl restart wpa_supplicant@wlo1

======================================================================

sudo wpa_cli -i wlo1 p2p_group_add freq=2437

iw dev $(basename /sys/class/net/p2p-wlo1-*) info 2>/dev/null
sudo wpa_cli -i "$(basename /sys/class/net/p2p-wlo1-*)" status 2>/dev/null
ip addr show $(ls /sys/class/net/ | grep ^p2p-wlo1-)

======================================================================

<Client join>

======================================================================

sudo wpa_cli -p /var/run/wpa_supplicant -i p2p-wlo1-0 wps_pbc

======================================================================

iw dev $(basename /sys/class/net/p2p-wlo1-*) station dump
sudo wpa_cli -i wlo1 p2p_peer da:3a:dd:09:24:2a

======================================================================

sudo ip addr add 192.168.49.1/24 dev p2p-wlo1-0

======================================================================

sudo journalctl -u wpa_supplicant@wlo1 -f
