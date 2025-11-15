#ifndef WPA_CTRL_H
#define WPA_CTRL_H

#include <stddef.h>

struct wpa_ctrl;

struct wpa_ctrl *wpa_ctrl_open(const char *ctrl_path);
void wpa_ctrl_close(struct wpa_ctrl *ctrl);
int wpa_ctrl_request(struct wpa_ctrl *ctrl,
                     const char *cmd,
                     size_t cmd_len,
                     char *reply,
                     size_t *reply_len,
                     void (*msg_cb)(char *msg, size_t len));

#endif /* WPA_CTRL_H */
