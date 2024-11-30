#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <string.h>

int main() { 
    int mode;
    printf("Enter mode (1 or 2 or 3): ");
    scanf("%d", &mode);

    if (mode == 1) {
        pid_t pid = fork();
        if (pid == -1) {
            perror("Error forking process");
            exit(EXIT_FAILURE);
        }

        // Child process
        if (pid == 0) {
            // Open the file
            int fd = open("testfile.txt", O_RDONLY);
            if (fd == -1) {
                perror("Error opening file");
                exit(EXIT_FAILURE);
            }

            // Read and display the file content
            char buffer[1024];
            ssize_t bytes_read;
            while ((bytes_read = read(fd, buffer, sizeof(buffer))) > 0) {
                if (write(STDOUT_FILENO, buffer, bytes_read) == -1) {
                    perror("Error writing to standard output");
                    close(fd);
                    exit(EXIT_FAILURE);
                }
            }

            if (bytes_read == -1) {
                perror("Error reading file");
            }

            // Close the file
            close(fd);
            exit(EXIT_SUCCESS);
        }

        // Parent process
        else {
            wait(NULL); // Wait for the child process to complete
        }
    }

    return 0;
}

