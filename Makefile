TARGET := monitor_wlan0
SRC := monitor_wlan0.c wpa_ctrl.c
CC := gcc
CFLAGS := -Wall -O2
LDFLAGS := 

# wpa_ctrl.h が同じディレクトリにある前提
INCLUDES := -I.

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(INCLUDES) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)