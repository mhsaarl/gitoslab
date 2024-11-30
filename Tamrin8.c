#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <dirent.h>
#include <sys/stat.h>

void initialize_git() {
    system("git init");  // Initialize the Git repository
    printf("Initialized Git repository. PID: %d\n", getpid());
}

void add_commit_git() {
    system("git add .");  // Add files to the staging area
    system("git commit -m \"Updated files\"");  // Commit the changes
    printf("Changes committed to Git. PID: %d\n", getpid());
}

void revert_changes() {
    system("git revert HEAD --no-edit");  // Revert to the previous commit
    printf("Reverted to previous commit. PID: %d\n", getpid());
}

void check_git_status() {
    system("git status");  // Show the current Git status
    printf("Checked Git status. PID: %d\n", getpid());
}

void monitor_txt_files() {
    system("git status > log.txt");  // Update the log for .txt files
    printf("Monitoring .txt files. Log updated. PID: %d\n", getpid());
    sleep(5);  // Simulate monitoring
}

void monitor_c_files() {
    system("git status > log_c.txt");  // Update the log for .c files
    printf("Monitoring .c files. Log updated. PID: %d\n", getpid());
    sleep(5);  // Simulate monitoring
}

void monitor_process_depth(const char* path) {
    char buffer[512];
    getcwd(buffer, sizeof(buffer));  // Get the current working directory
    printf("Current Path Depth: %s -> %s\n", path, buffer);  // Show depth of process in path
}

int main() {
    pid_t pid_txt, pid_c, pid_parent;

    // Initialize the Git repository and simulate file addition
    pid_parent = getpid();
    printf("Parent Process (PID: %d)\n", pid_parent);
    initialize_git();

    // Forking for .txt file monitoring
    pid_txt = fork();
    if (pid_txt == 0) {
        // Child process for .txt files
        monitor_process_depth("/path/to/txt");  // Example path
        printf("Child Process for .txt files, PID: %d\n", getpid());
        monitor_txt_files();
        exit(0);
    }

    // Forking for .c file monitoring
    pid_c = fork();
    if (pid_c == 0) {
        // Child process for .c files
        monitor_process_depth("/path/to/c");  // Example path
        printf("Child Process for .c files, PID: %d\n", getpid());
        monitor_c_files();
        exit(0);
    }

    // Parent process: Perform Git operations
    sleep(2);  // Simulate some delay
    add_commit_git();
    revert_changes();
    check_git_status();

    // Wait for child processes to finish
    wait(NULL);
    wait(NULL);

    // End of process
    printf("All processes completed. Parent PID: %d\n", pid_parent);
    return 0;
}
