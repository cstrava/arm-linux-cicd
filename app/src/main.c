#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifndef VERSION
#define VERSION "dev"
#endif

int main(int argc, char const *argv[]) {
  if (argc == 2) {
    if (strcmp(argv[1], "--health") == 0) {
      printf("OK\n");
      return 0;
    }

    if (strcmp(argv[1], "--version") == 0) {
      printf("sensor-service %s\n", VERSION);
      return 0;
    }

    if (strcmp(argv[1], "--serve") == 0) {
      while (1) {
        printf("temperature=24.5\n");
        printf("accel_x=0.02\n");
        printf("accel_y=-0.01\n");
        printf("accel_z=0.98\n");
        printf("status=OK\n");

        fflush(stdout);
        sleep(5);
      }
    }

    printf("Unknown option: %s\n", argv[1]);
    return 1;
  }

  if (argc > 2) {
    printf("Too many arguments\n");
    return 1;
  }

  printf("temperature=24.5\n");
  printf("accel_x=0.02\n");
  printf("accel_y=-0.01\n");
  printf("accel_z=0.98\n");
  printf("status=OK\n");

  return 0;
}