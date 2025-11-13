# p2p-config-tui (raspi-config風 TUI)

端末上で動く **Wi‑Fi Direct (P2P)** 設定ツール。`whiptail` を使った CUI メニューで、
- GO開始（`p2p_group_add freq=…`）
- WPS受け入れ（GO側 `wps_pbc`）
- 探索/ピア一覧（`p2p_find` / `p2p_peers`）
- Client接続（`p2p_connect <MAC> pbc join`）
- IP割当（GO/Client）
- 事前セットアップ（`wpa_supplicant.service` の mask、NetworkManager 除外、config/override 作成）
- 状態表示（`systemctl status wpa_supplicant@IFACE`）
- デバイス情報（`iw dev`）
- P2Pステータス（`wpa_cli status`）
- ログ表示（`journalctl`）

を実行できます。SSH でも利用可能。GUI不要。

## 必要パッケージ

```bash
sudo apt update
sudo apt install -y whiptail wpasupplicant iw iproute2
# 状態/ログ表示で使うコマンド（入っていなければ）
sudo apt install -y systemd
```

## 使い方

```bash
chmod +x p2p-config-tui.sh
./p2p-config-tui.sh
```

### セットアップメニュー

最初にメニュー `Run setup (mask/NetworkManager/wpa_supplicant)` を実行すると、GO/Client 共通で必要な以下の初期設定をまとめて行えます。

1. `wpa_supplicant.service` を停止・mask。
2. `/etc/NetworkManager/conf.d/unmanaged.conf` を上書きし、指定した Wi-Fi インターフェースと P2P 仮想 IF を NetworkManager 管理から外す。
3. `/etc/wpa_supplicant/<任意>.conf` を作成（`device_name` や `p2p_go_intent=0` の有無を対話的に指定）。
4. `wpa_supplicant@<iface>.service` 用の override を作成し、上記 config を参照するように変更。
5. `systemctl daemon-reload` → `enable --now wpa_supplicant@<iface>` → `NetworkManager` 再起動。

プロンプトで設定した内容は `textbox` で確認できます。セットアップが完了すると、メインメニューの IFACE にも反映されます。

### メモ
- デフォルトIFACEは自動検出（`wlan*` / `wlo*` を優先）。メニューの「設定変更」で上書き可能。
- IP割当は GO/Client どちらのテンプレ値でも入力し直せます。
- `sudo`は各アクション内で適用（スクリプト自体は非rootでOK）。

## 免責
本ツールはネットワークを変更します。実行は自己責任でお願いします。
