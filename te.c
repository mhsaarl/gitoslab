#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <dirent.h>
#include <sys/stat.h>

// Function to initialize Git repository at a specific path
void initialize_git(const char *path) {
    char command[512];
    snprintf(command, sizeof(command), "cd %s && git init", path);
    system(command);
    printf("[Git] Initialized Git repository at path: %s\n", path);

    snprintf(command, sizeof(command), "cd %s && git add .", path);
    system(command);
    printf("[Git] Added files to Git repository at path: %s\n", path);
}

// Function to commit changes in Git
void git_commit(const char *path, const char *message) {
    char command[512];
    snprintf(command, sizeof(command), "cd %s && git commit -m \"%s\"", path, message);
    int status = system(command);
    if (status == 0) {
        printf("[Git] Changes committed successfully with message: %s\n", message);
    } else {
        printf("[Git] No changes to commit or commit failed at path: %s\n", path);
    }
}

// Function to display Git status
void git_status(const char *path) {
    char command[512];
    snprintf(command, sizeof(command), "cd %s && git status", path);
    system(command);
}

// Function to revert the last commit
void git_revert_last_commit(const char *path) {
    char command[512];
    snprintf(command, sizeof(command), "cd %s && git revert --no-edit HEAD", path);
    int status = system(command);
    if (status == 0) {
        printf("[Git] Reverted the last commit successfully at path: %s\n", path);
    } else {
        printf("[Git] Failed to revert the last commit. Ensure there are commits to revert at path: %s\n", path);
    }
}

// Comprehensive Git manager
void manage_git(const char *path, const char *action, const char *message) {
    if (strcmp(action, "init") == 0) {
        initialize_git(path);
    } else if (strcmp(action, "commit") == 0) {
        git_commit(path, message);
    } else if (strcmp(action, "status") == 0) {
        git_status(path);
    } else if (strcmp(action, "revert") == 0) {
        git_revert_last_commit(path);
    } else {
        printf("[Git] Invalid action: %s. Available actions: init, commit, status, revert.\n", action);
    }
}

int main() {
    const char *repo_path = "./repository"; // Path for Git repository
    mkdir(repo_path, 0777); // Create directory for Git repository

    // Example usage of the comprehensive Git manager
    printf("Initializing Git repository...\n");
    manage_git(repo_path, "init", NULL);

    printf("Adding and committing changes...\n");
    manage_git(repo_path, "commit", "Initial commit with setup");

    printf("Checking Git status...\n");
    manage_git(repo_path, "status", NULL);

    printf("Reverting last commit...\n");
    manage_git(repo_path, "revert", NULL);

    printf("[MAIN] All Git operations completed.\n");

    return 0;
}
