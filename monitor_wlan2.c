// file: monitor_wlan2.c
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "wpa_ctrl.h"

#define CTRL_PATH "/var/run/wpa_supplicant/wlan2"

// コマンド送信＆レスポンス表示用ヘルパー
static int send_cmd(struct wpa_ctrl *ctrl, const char *cmd)
{
    char buf[4096];
    size_t len = sizeof(buf) - 1;

    int ret = wpa_ctrl_request(ctrl, cmd, strlen(cmd), buf, &len, NULL);
    if (ret != 0)
    {
        fprintf(stderr, "Failed to send command: %s (ret=%d)\n", cmd, ret);
        return -1;
    }

    buf[len] = '\0';
    printf("%s\n", buf);
    return 0;
}

int main(void)
{
    struct wpa_ctrl *ctrl;

    // wlan2 の control interface に接続
    ctrl = wpa_ctrl_open(CTRL_PATH);
    if (!ctrl)
    {
        fprintf(stderr, "Failed to connect to wpa_supplicant at %s\n", CTRL_PATH);
        return 1;
    }

    printf("Connected to wpa_supplicant: %s\n", CTRL_PATH);

    while (1)
    {
        printf("===== STATUS =====\n");
        if (send_cmd(ctrl, "STATUS") < 0)
        {
            // 失敗したらループ抜ける
            break;
        }

        printf("===== SIGNAL_POLL =====\n");
        if (send_cmd(ctrl, "SIGNAL_POLL") < 0)
        {
            break;
        }

        printf("-------------------------\n");
        fflush(stdout);

        sleep(1); // 1秒ごとに実行
    }

    wpa_ctrl_close(ctrl);
    return 0;
}
