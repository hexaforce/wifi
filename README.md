# wifi



sudo wpa_cli -i wlo1 p2p_group_remove p2p-wlo1-0
sudo wpa_cli -i wlo1 p2p_group_add freq=2437   # ch6で作成
sudo wpa_cli -i wlo1 status                    # ip=192.168.100.1 等を再確認