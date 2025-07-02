#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

int main(int argc, char *argv[]) {
    int fd;
    char buffer[100];
    ssize_t bytes_read;

    // Check if filename provided as command line argument
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return 1;
    }

    // Open file using openat() with current working directory
    fd = openat(AT_FDCWD, argv[1], O_RDONLY);
    if (fd == -1) {
        fprintf(stderr, "Error opening file '%s': %s\n", argv[1], strerror(errno));
        return 1;
    }

    // Read up to 50 bytes from the file
    bytes_read = read(fd, buffer, 50);

    if (bytes_read > 0) {
        // Null-terminate the buffer for safe string operations
        buffer[bytes_read] = '\0';
        printf("Read %zd bytes from '%s': %s\n", bytes_read, argv[1], buffer);
    } else if (bytes_read == 0) {
        printf("End of file reached or empty file\n");
    } else {
        fprintf(stderr, "Error reading file: %s\n", strerror(errno));
        close(fd);
        return 1;
    }

    // Close the file descriptor
    if (close(fd) == -1) {
        fprintf(stderr, "Error closing file: %s\n", strerror(errno));
        return 1;
    }

    printf("File '%s' closed successfully\n", argv[1]);
    return 0;
}
