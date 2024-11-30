#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <dirent.h>
#include <sys/stat.h>

void monitor_txt_files() {
    system("git status > log.txt");
    printf("Monitoring .txt files. Log updated.\n");
    sleep(5); // simulate monitoring
}

void monitor_c_files() {
    system("git status > log_c.txt");
    printf("Monitoring .c files. Log updated.\n");
    sleep(5); // simulate monitoring
}

void initialize_git() {
    system("git init");
    printf("Initialized Git repository.\n");
}

void add_commit_git() {
    system("git add .");
    system("git commit -m \"Updated files\"");
    printf("Changes committed to Git.\n");
}

void check_git_status() {
    system("git status");
}

void revert_last_commit() {
    system("git log --oneline");  // Check if there's at least one commit
    printf("Reverting to previous commit...\n");
    system("git revert HEAD");
    printf("Reverted to previous commit.\n");
}

int main() {
    pid_t pid_txt, pid_c;

    printf("Initializing Git repository...\n");
    initialize_git();

    // Forking for .txt file monitoring
    pid_txt = fork();
    if (pid_txt == 0) {
        // Child process for .txt files
        printf("Child Process for .txt files, PID: %d\n", getpid());
        monitor_txt_files();
        exit(0);
    }

    // Forking for .c file monitoring
    pid_c = fork();
    if (pid_c == 0) {
        // Child process for .c files
        printf("Child Process for .c files, PID: %d\n", getpid());
        monitor_c_files();
        exit(0);
    }

    // Parent process
    printf("Parent Process, PID: %d\n", getpid());

    // Simulating Git actions
    sleep(2);
    add_commit_git();
    check_git_status();
    revert_last_commit(); // Only try to revert if there's a commit

    // Waiting for child processes to finish
    wait(NULL);
    wait(NULL);

    printf("All processes completed.\n");

    return 0;
}
