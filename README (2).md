# p2p-config-tui (raspi-config風 TUI)

端末上で動く **Wi‑Fi Direct (P2P)** 設定ツール。`whiptail` を使った CUI メニューで、
- GO開始（`p2p_group_add freq=…`）
- WPS受け入れ（GO側 `wps_pbc`）
- 探索/ピア一覧（`p2p_find` / `p2p_peers`）
- Client接続（`p2p_connect <MAC> pbc join`）
- IP割当（GO/Client）
- 状態表示（`systemctl` / `iw` / `wpa_cli`）
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

### メモ
- デフォルトIFACEは自動検出（`wlan*` / `wlo*` を優先）。メニューの「設定変更」で上書き可能。
- IP割当は GO/Client どちらのテンプレ値でも入力し直せます。
- `sudo`は各アクション内で適用（スクリプト自体は非rootでOK）。

## 免責
本ツールはネットワークを変更します。実行は自己責任でお願いします。
