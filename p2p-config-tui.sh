#!/bin/bash
# p2p-config-tui.sh - raspi-config風 Wi‑Fi Direct (P2P) 設定メニュー
# Requires: whiptail, wpa_cli, ip, iw, systemd (journalctl), bash
# Optional: NetworkManager, wpa_supplicant@<iface>.service
# License: MIT

set -euo pipefail

TITLE="P2P Config Tool"
IFACE_DEFAULT="wlan0"
FREQ_DEFAULT="2437"   # ch6
IP_DEFAULT_GO="192.168.49.1/24"
IP_DEFAULT_CL="192.168.49.2/24"

# --- helpers ---
require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 127; }; }
msg() { whiptail --title "$TITLE" --msgbox "$1" 15 70; }
yesno() { whiptail --title "$TITLE" --yesno "$1" 12 70; }
input() { 
  local prompt="$1" default="${2:-}"
  whiptail --title "$TITLE" --inputbox "$prompt" 10 70 "$default" 3>&1 1>&2 2>&3
}
textbox() {
  local text="$1"
  whiptail --title "$TITLE" --scrolltext --msgbox "$text" 25 90
}
run() {
  local cmd="$1"
  local out rc
  if out=$(bash -lc "$cmd" 2>&1); then
    textbox "$ $cmd

$out"
  else
    rc=$?
    textbox "$ $cmd

$out

[rc=$rc]"
  fi
}

detect_iface() {
  # pick first wlan*/wlo* that exists
  for n in /sys/class/net/*; do
    b=$(basename "$n")
    [[ "$b" =~ ^wlan[0-9]+$ || "$b" =~ ^wlo[0-9]+$ ]] && { echo "$b"; return; }
  done
  echo "$IFACE_DEFAULT"
}

p2p_name() {
  local base="$1"
  # first p2p-<iface>-* that exists
  shopt -s nullglob
  for n in /sys/class/net/p2p-"$base"-*; do
    [[ -e "$n" ]] && { basename "$n"; return; }
  done
  echo ""
}

show_status() {
  local iface="$1"
  local p2p="$(p2p_name "$iface")"
  local out="=== systemctl ===
$(systemctl status -n 0 "wpa_supplicant@${iface}" 2>&1)

=== iw dev ===
$(iw dev 2>&1)

=== wpa_cli status (${iface}) ===
$(wpa_cli -i "${iface}" status 2>&1)

=== wpa_cli status (${p2p}) ===
$( [ -n "$p2p" ] && wpa_cli -i "${p2p}" status 2>&1 || echo "(no p2p iface yet)")
"
  textbox "$out"
}

tail_logs() {
  local iface="$1"
  run "journalctl -u wpa_supplicant@${iface} -n 200 --no-pager"
}

# --- main menu loop ---
main_menu() {
  local iface freq ip_go ip_cl
  iface="$(detect_iface)"
  freq="$FREQ_DEFAULT"
  ip_go="$IP_DEFAULT_GO"
  ip_cl="$IP_DEFAULT_CL"

  while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "IFACE=${iface} | FREQ=${freq}\nChoose an action:" 20 78 12 \
      "1" "GO開始 (p2p_group_add freq=…)" \
      "2" "WPS受け入れ (GO: wps_pbc)" \
      "3" "探索開始 (p2p_find) / ピア一覧 (p2p_peers)" \
      "4" "Client接続 (p2p_connect <MAC> pbc join)" \
      "5" "IP割り当て (GO/Client)" \
      "6" "状態表示 (systemctl / iw / wpa_cli)" \
      "7" "ログ表示 (journalctl -u wpa_supplicant@IFACE)" \
      "8" "設定変更 (IFACE / FREQ / IP)" \
      "9" "終了" 3>&1 1>&2 2>&3) || exit 0

    case "$CHOICE" in
      1)  # GO start
          freq=$(input "周波数 (MHz) を入力 (例: 2437=Ch6)" "$freq") || true
          run "sudo wpa_cli -i ${iface} p2p_group_add freq=${freq}"
          local p2p="$(p2p_name "$iface")"
          run "iw dev ${p2p:-p2p-${iface}-0} info || true"
          ;;
      2)  # WPS accept
          local p2p="$(p2p_name "$iface")"
          if [ -z "$p2p" ]; then msg "p2pインターフェースが見つかりません。先にGO開始してください。"; continue; fi
          run "sudo wpa_cli -i ${p2p} wps_pbc"
          ;;
      3)  # find & peers
          run "sudo wpa_cli -i ${iface} p2p_find"
          run "sudo wpa_cli -i ${iface} p2p_peers"
          ;;
      4)  # connect as client
          MAC=$(input "接続先のMACアドレス（例: bc:09:1b:1d:15:92）" "") || true
          [ -z "${MAC:-}" ] && { msg "MACが未入力です。"; continue; }
          run "sudo wpa_cli -i ${iface} p2p_connect ${MAC} pbc join"
          ;;
      5)  # assign IP
          local p2p="$(p2p_name "$iface")"
          if [ -z "$p2p" ]; then msg "p2pインターフェースが見つかりません。"; continue; fi
          if yesno "GOに ${ip_go} を割り当てますか？いいえを選ぶとClient (${ip_cl}) を割り当てます。"; then
            ip=$(input "割り当てるIP/CIDR" "$ip_go") || true
          else
            ip=$(input "割り当てるIP/CIDR" "$ip_cl") || true
          fi
          [ -z "${ip:-}" ] && { msg "IP/CIDRが未入力です。"; continue; }
          run "sudo ip addr add ${ip} dev ${p2p}"
          run "ip addr show ${p2p}"
          ;;
      6)  show_status "$iface" ;;
      7)  tail_logs "$iface" ;;
      8)  # settings
          iface=$(input "Wi‑Fi IFACE を入力（例: wlan0 / wlo1）" "$iface") || true
          freq=$(input "デフォルト周波数 (MHz)" "$freq") || true
          ip_go=$(input "GO用デフォルトIP/CIDR" "$ip_go") || true
          ip_cl=$(input "Client用デフォルトIP/CIDR" "$ip_cl") || true
          ;;
      9)  clear; exit 0 ;;
    esac
  done
}

# requirements check
require whiptail
require wpa_cli
require iw
require ip
# journalctl may not exist on tiny systems; menu will still work without it
command -v journalctl >/dev/null 2>&1 || true

main_menu
