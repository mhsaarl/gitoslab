#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <dirent.h>
#include <sys/stat.h>

// Function to get the depth of the current directory
int get_depth(const char *path) {
    int depth = 0;
    const char *ptr = path;
    while ((ptr = strchr(ptr, '/')) != NULL) {
        depth++;
        ptr++;
    }
    return depth;
}

// Function to monitor .txt files
void monitor_txt_files() {
    char cwd[1024];
    getcwd(cwd, sizeof(cwd));  // Get current directory
    int depth = get_depth(cwd);  // Get the depth of the current directory
    printf("Monitoring .txt files at %s (Depth: %d), PID: %d\n", cwd, depth, getpid());
    
    // Running git status and saving it to a log file
    system("git status > log.txt");
    printf("Log updated for .txt files.\n");
    sleep(5);  // simulate monitoring
}

// Function to monitor .c files
void monitor_c_files() {
    char cwd[1024];
    getcwd(cwd, sizeof(cwd));  // Get current directory
    int depth = get_depth(cwd);  // Get the depth of the current directory
    printf("Monitoring .c files at %s (Depth: %d), PID: %d\n", cwd, depth, getpid());
    
    // Running git status and saving it to a log file
    system("git status > log_c.txt");
    printf("Log updated for .c files.\n");
    sleep(5);  // simulate monitoring
}

// Initialize Git repository
void initialize_git() {
    system("git init");
    printf("Git repository initialized.\n");
}

// Add and commit changes to Git
void add_commit_git() {
    system("git add .");
    system("git commit -m \"Updated files\"");
    printf("Changes committed to Git.\n");
}

// Check Git status
void check_git_status() {
    system("git status");
}

// Revert to the previous commit if there are commits to revert
void revert_last_commit() {
    printf("Checking if there are any commits to revert...\n");
    
    // Check if there are any commits in the history
    FILE *git_log = popen("git log --oneline", "r");
    if (git_log == NULL) {
        printf("Error: Unable to check Git log.\n");
        return;
    }
    
    char line[256];
    int commit_count = 0;
    while (fgets(line, sizeof(line), git_log) != NULL) {
        commit_count++;
    }
    fclose(git_log);
    
    // If there are commits, proceed to revert
    if (commit_count > 0) {
        printf("Reverting to the previous commit...\n");
        system("git revert HEAD");
        printf("Reverted to the previous commit.\n");
    } else {
        printf("No commits to revert.\n");
    }
}

// Function to monitor child processes and print their status
void monitor_processes(pid_t pid_txt, pid_t pid_c) {
    int status;
    while (1) {
        pid_t finished_pid = waitpid(-1, &status, WNOHANG);  // Non-blocking check
        if (finished_pid > 0) {
            printf("Process with PID %d finished.\n", finished_pid);
        }
        sleep(1);  // Check every second
    }
}

int main() {
    pid_t pid_txt, pid_c, pid_monitor;

    // Initialize Git repository
    printf("Initializing Git repository...\n");
    initialize_git();

    // Forking for .txt file monitoring
    pid_txt = fork();
    if (pid_txt == 0) {
        // Child process for .txt files
        monitor_txt_files();
        exit(0);
    }

    // Forking for .c file monitoring
    pid_c = fork();
    if (pid_c == 0) {
        // Child process for .c files
        monitor_c_files();
        exit(0);
    }

    // Forking for process monitor
    pid_monitor = fork();
    if (pid_monitor == 0) {
        // Child process for monitoring other processes
        monitor_processes(pid_txt, pid_c);
        exit(0);
    }

    // Parent process actions
    printf("Parent process, PID: %d\n", getpid());
    sleep(2);  // Allow child processes to start

    // Perform Git operations
    add_commit_git();
    check_git_status();
    revert_last_commit();  // Only revert if there are commits

    // Wait for all child processes
    wait(NULL);
    wait(NULL);
    wait(NULL);

    printf("All processes completed.\n");

    return 0;
}
