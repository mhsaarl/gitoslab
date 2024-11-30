#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

// Function to analyze strace output and create a report
void analyze_strace_output(const char *strace_file, const char *report_file) {
    FILE *strace_fp = fopen(strace_file, "r");
    FILE *report_fp = fopen(report_file, "w");

    if (!strace_fp || !report_fp) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    char line[1024];
    fprintf(report_fp, "System Call Analysis Report\n");
    fprintf(report_fp, "--------------------------------\n");

    // Parse strace output and identify key system calls
    while (fgets(line, sizeof(line), strace_fp)) {
        if (strstr(line, "fork(") || strstr(line, "wait(") ||
            strstr(line, "read(") || strstr(line, "open(") ||
            strstr(line, "close(")) {
            fprintf(report_fp, "%s", line); // Write relevant lines to the report
        }
    }

    fclose(strace_fp);
    fclose(report_fp);

    printf("Analysis complete. Report saved to %s\n", report_file);
}

int main() {
    int task;
    while(1){
    printf("task (1 or 2 or 3 or 4 or 5(exit)): ");
        scanf("%d", &task);
    switch(task){
    case 1: {
        pid_t pid = fork();
        if (pid == -1) {
            perror("Error in creating child");
            exit(EXIT_FAILURE);
        }

       // Child process
      if (pid == 0) {
        // Opening the file
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
        
        }

        // Parent process
        else {
            wait(NULL); // Wait for the child process to complete
        } break;
    }





   case 2: {
    int choice;
    char filename[256] = {0}; // Declare filename at the top for use across cases
    int fd = -1;              // Initialize the file descriptor

    printf("MENU:\n1. Create file\n2. Write in file\n3. Read file\n4. Change file access\n5. Exit\n");

    while (1) {
        printf("\nEnter your choice: ");
        scanf("%d", &choice);

        switch (choice) {
            case 1: {
                // Create a file
                printf("Enter file name: ");
                scanf("%255s", filename); 

                if (fd != -1) {
                    close(fd); // Close any previously open file descriptor
                }

                fd = open(filename, O_CREAT | O_WRONLY | O_APPEND, 0644); // Open file in write/append mode
                if (fd == -1) {
                    perror("Error creating file");
                    break;
                }
                printf("File '%s' created successfully.\n", filename);
                break;
            }

            case 2: {
                // Write to the file
                if (fd == -1) {
                    printf("No file is open. Please create or open a file first.\n");
                    break;
                }

                printf("Start writing to the file or type 'exit' to quit:\n");

                char *buffer = NULL; // Pointer for dynamic memory allocation
                size_t bufsize = 0;  // Size of the allocated buffer
                ssize_t input_size;  // Size of user input

                while (1) {
                    input_size = getline(&buffer, &bufsize, stdin); // Read user input
                    if (input_size == -1) {
                        perror("Error reading input");
                        break;
                    }

                    // Check if the user wants to exit
                    if (strncmp(buffer, "exit", 4) == 0 && (buffer[4] == '\n' || buffer[4] == '\0')) {
                        printf("Exiting writing mode.\n");
                        break;
                    }

                    // Write user input to the file
                    if (write(fd, buffer, input_size) == -1) {
                        perror("Error writing to file");
                        break;
                    }
                }
                free(buffer); // Free dynamically allocated buffer
                break;
            }

            case 3: {
                // Read and display the file contents without closing the file for appending
                int temp_fd = open(filename, O_RDONLY); // Open file in read-only mode
                if (temp_fd == -1) {
                    perror("Error opening file for reading");
                    break;
                }

                char buffer[1024];
                ssize_t bytes_read;

                printf("File contents:\n");
                while ((bytes_read = read(temp_fd, buffer, sizeof(buffer))) > 0) {
                    if (write(STDOUT_FILENO, buffer, bytes_read) == -1) {
                        perror("Error writing to standard output");
                        break;
                    }
                }

                if (bytes_read == -1) {
                    perror("Error reading file");
                }

                close(temp_fd); // Close the temporary file descriptor
                break;
            }

            case 4: {
                // Change file access permissions
                if (filename[0] == '\0') {
                    printf("No file is set. Please create or specify a file first.\n");
                    break;
                }

                char permission_str[10];
                printf("Enter new file permissions (e.g., 755 for rwx-r-xr-x): ");
                scanf("%s", permission_str);

                mode_t new_permissions = strtol(permission_str, NULL, 8); // Convert string to octal mode

                if (chmod(filename, new_permissions) == -1) {
                    perror("Error changing file permissions");
                    break;
                }  


               struct stat file_stat;
               if (stat(filename, &file_stat) == -1) {
               perror("Error retrieving file information");
               break;
                }

                // Format and print the new permissions
                printf("Permissions for '%s' updated successfully.\n", filename);
                printf("New permissions: ");
                printf((file_stat.st_mode & S_IRUSR) ? "r" : "-");
                printf((file_stat.st_mode & S_IWUSR) ? "w" : "-");
                printf((file_stat.st_mode & S_IXUSR) ? "x" : "-");
                printf((file_stat.st_mode & S_IRGRP) ? "r" : "-");
                printf((file_stat.st_mode & S_IWGRP) ? "w" : "-");
                printf((file_stat.st_mode & S_IXGRP) ? "x" : "-");
                printf((file_stat.st_mode & S_IROTH) ? "r" : "-");
                printf((file_stat.st_mode & S_IWOTH) ? "w" : "-");
                printf((file_stat.st_mode & S_IXOTH) ? "x" : "-");
                printf("\n");
                break;
            }

            case 5: {
                break;
        }
    } break;
   }

      void sigint_handler(int sig){
          printf("Received SIGINT.Exiting safely...\n");
                  exit(0);
          }
    case 3:{
    //managing multiple process  

         int pipefd[2];

        // Create pipe
        if (pipe(pipefd) == -1) {
        perror("Error creating pipe");
        exit(EXIT_FAILURE);
        }

       pid_t pid1 = fork();
       if (pid1==0){
           execl("/bin/ls","ls",NULL);
           
       }
       else if (pid1 < 0) {
        perror("fork");
        exit(EXIT_FAILURE);
      }

       waitpid(pid1, NULL, 0);

       pid_t pid2 = fork();
       if (pid2==0){
        signal(SIGINT,sigint_handler);
        printf("Child 1: Waiting for SIGINT (Ctrl+C)...\n");
        while (1) {
        sleep(1);}
       }
       else if (pid2 < 0) {
        perror("fork");
        exit(EXIT_FAILURE);
      }
      
      sleep(2);

       pid_t pid3 = fork();
       if (pid3 == 0) {
        // Child 3: Reads data from file and writes to the pipe
        sleep(3);
        close(pipefd[0]); // Close unused read end of the pipe

        // Open file for reading
        int filefd = open("testfile.txt", O_RDONLY);
        if (filefd == -1) {
            perror("Error opening file");
            exit(EXIT_FAILURE);
        }

        char buffer[1024];
        ssize_t bytes_read;

        // Read data from the file and write to the pipe
        while ((bytes_read = read(filefd, buffer, sizeof(buffer))) > 0) {
            if (write(pipefd[1], buffer, bytes_read) == -1) {
                perror("Error writing to pipe");
                exit(EXIT_FAILURE);
            }
        }

        if (bytes_read == -1) {
            perror("Error reading file");
        }

        close(filefd);  // Close file
        close(pipefd[1]); // Close write end of pipe
        exit(EXIT_SUCCESS);
    } else if (pid3 < 0) {
        perror("fork");
        exit(EXIT_FAILURE);
    }
     waitpid(pid3, NULL, 0);



       // Parent Process: Reads from pipe and waits for children
       close(pipefd[1]); // Close unused write end of the pipe

       char buffer[1024];
       ssize_t bytes_read;

       // Read data from the pipe and display it
       printf("Parent: Reading data from the pipe...\n");
       while ((bytes_read = read(pipefd[0], buffer, sizeof(buffer))) > 0) {
          if (write(STDOUT_FILENO, buffer, bytes_read) == -1) {
            perror("Error writing to stdout");
            exit(EXIT_FAILURE);
          }
        }

        if (bytes_read == -1) {
        perror("Error reading from pipe");
        }

        close(pipefd[0]); // Close read end of the pipe

        
        waitpid(pid2, NULL, 0); // Wait for Child 2
   

        printf("Parent: All child processes have finished. Exiting.\n");        
     break;
 }    

   case 4:{
   const char *program_name = "./P2OS";
        const char *strace_file = "strace_output.txt";
        const char *report_file = "system_call_report.txt";

        printf("Running strace on %s...\n", program_name);

        char command[256];
        snprintf(command, sizeof(command), "strace -o %s %s", strace_file, program_name);
        int ret = system(command);

        if (ret == -1) {
            perror("Error running strace");
            exit(EXIT_FAILURE);
        }

        analyze_strace_output(strace_file, report_file);

        printf("Strace output saved to %s\n", strace_file);
        printf("Analysis report saved to %s\n", report_file);
        break;
    }
    case 5:{
        return 0;
    }
     }
    }

    return 0;
}
