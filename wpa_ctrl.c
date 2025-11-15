#include "wpa_ctrl.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

struct wpa_ctrl
{
    int s;
    struct sockaddr_un local;
    struct sockaddr_un dest;
};

static int make_unique_local(struct wpa_ctrl *ctrl)
{
    static unsigned int counter;
    int ret;

    ctrl->local.sun_family = AF_UNIX;
    ret = snprintf(ctrl->local.sun_path,
                   sizeof(ctrl->local.sun_path),
                   "/tmp/wpa_ctrl_%d-%u",
                   getpid(),
                   ++counter);
    if (ret < 0 || (size_t)ret >= sizeof(ctrl->local.sun_path))
    {
        return -1;
    }

    unlink(ctrl->local.sun_path);
    if (bind(ctrl->s, (struct sockaddr *)&ctrl->local, sizeof(ctrl->local)) < 0)
    {
        return -1;
    }

    return 0;
}

struct wpa_ctrl *wpa_ctrl_open(const char *ctrl_path)
{
    struct wpa_ctrl *ctrl;

    if (!ctrl_path)
    {
        return NULL;
    }

    ctrl = calloc(1, sizeof(*ctrl));
    if (!ctrl)
    {
        return NULL;
    }

    ctrl->s = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (ctrl->s < 0)
    {
        free(ctrl);
        return NULL;
    }

    if (make_unique_local(ctrl) < 0)
    {
        close(ctrl->s);
        free(ctrl);
        return NULL;
    }

    ctrl->dest.sun_family = AF_UNIX;
    if (strlen(ctrl_path) >= sizeof(ctrl->dest.sun_path))
    {
        wpa_ctrl_close(ctrl);
        return NULL;
    }

    strncpy(ctrl->dest.sun_path, ctrl_path, sizeof(ctrl->dest.sun_path) - 1);
    ctrl->dest.sun_path[sizeof(ctrl->dest.sun_path) - 1] = '\0';

    if (connect(ctrl->s, (struct sockaddr *)&ctrl->dest, sizeof(ctrl->dest)) < 0)
    {
        wpa_ctrl_close(ctrl);
        return NULL;
    }

    return ctrl;
}

void wpa_ctrl_close(struct wpa_ctrl *ctrl)
{
    if (!ctrl)
    {
        return;
    }

    if (ctrl->s >= 0)
    {
        close(ctrl->s);
    }

    if (ctrl->local.sun_path[0])
    {
        unlink(ctrl->local.sun_path);
    }

    free(ctrl);
}

static int wait_for_reply(struct wpa_ctrl *ctrl, char *reply, size_t *reply_len, void (*msg_cb)(char *msg, size_t len))
{
    while (1)
    {
        fd_set rfds;
        struct timeval tv = { .tv_sec = 5, .tv_usec = 0 };
        int sel;

        FD_ZERO(&rfds);
        FD_SET(ctrl->s, &rfds);

        sel = select(ctrl->s + 1, &rfds, NULL, NULL, &tv);
        if (sel < 0)
        {
            if (errno == EINTR)
            {
                continue;
            }
            return -1;
        }
        if (sel == 0)
        {
            return -2; // timeout
        }

        if (FD_ISSET(ctrl->s, &rfds))
        {
            ssize_t res = recv(ctrl->s, reply, *reply_len, 0);
            if (res < 0)
            {
                if (errno == EINTR)
                {
                    continue;
                }
                return -1;
            }
            if (res == 0)
            {
                continue;
            }

            if (reply[0] == '<')
            {
                if (msg_cb)
                {
                    msg_cb(reply, res);
                }
                continue;
            }

            *reply_len = (size_t)res;
            return 0;
        }
    }
}

int wpa_ctrl_request(struct wpa_ctrl *ctrl,
                     const char *cmd,
                     size_t cmd_len,
                     char *reply,
                     size_t *reply_len,
                     void (*msg_cb)(char *msg, size_t len))
{
    if (!ctrl || ctrl->s < 0 || !cmd || !reply || !reply_len)
    {
        return -1;
    }

    if (send(ctrl->s, cmd, cmd_len, 0) < 0)
    {
        return -1;
    }

    return wait_for_reply(ctrl, reply, reply_len, msg_cb);
}
