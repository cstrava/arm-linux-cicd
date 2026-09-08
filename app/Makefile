CC = gcc
ARM_CC = arm-linux-gnueabihf-gcc
AARCH64_CC = aarch64-linux-gnu-gcc

CFLAGS = -Wall -Wextra -Werror

TARGET = sensor-service
ARM_TARGET = sensor-service-arm
AARCH64_TARGET = sensor-service-arm64

SRC = src/main.c

all:
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

arm:
	$(ARM_CC) $(CFLAGS) $(SRC) -o $(ARM_TARGET)

arm64:
	$(AARCH64_CC) $(CFLAGS) $(SRC) -o $(AARCH64_TARGET)

test: all
	cd ../tests && ./test_sensor_service.sh

format-check:
	clang-format --dry-run --Werror $(SRC)

static-analysis:
	cppcheck --enable=warning,style,performance,portability \
		--error-exitcode=1 $(SRC)

quality: format-check static-analysis test

clean:
	rm -f $(TARGET) $(ARM_TARGET) $(AARCH64_TARGET)