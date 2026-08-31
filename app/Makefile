CC = gcc
CFLAGS = -Wall -Wextra -Werror
TARGET = sensor-service
SRC = src/main.c

all:
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

test: all
	cd ../tests && ./test_sensor_service.sh

format-check:
	clang-format --dry-run --Werror $(SRC)

static-analysis:
	cppcheck --enable=warning,style,performance,portability \
		--error-exitcode=1 $(SRC)

quality: format-check static-analysis test

clean:
	rm -f $(TARGET)