#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <dirent.h>
#include <sys/stat.h>

void initialize_git(const char *path) {
    char command[512];
    snprintf(command, sizeof(command), "cd %s && git init", path);
    system(command);
    printf("[Git] Initialized Git repository at path: %s\n", path);

    snprintf(command, sizeof(command), "cd %s && git add .", path);
    system(command);
    printf("[Git] Added files to Git repository at path: %s\n", path);
}

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

void git_status(const char *path) {
    char command[512];
    snprintf(command, sizeof(command), "cd %s && git status", path);
    system(command);
}

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

int has_extension(const char *filename, const char *extension) {
    const char *dot = strrchr(filename, '.');
    return dot && strcmp(dot, extension) == 0;
}

void monitor_txt_files(const char *path) {
    DIR *dir;
    struct dirent *entry;

    printf("[TXT] Monitoring .txt files in directory: %s\n", path);

    if ((dir = opendir(path)) == NULL) {
        perror("opendir");
        return;
    }

    FILE *log = fopen("log_txt.txt", "w");
    if (!log) {
        perror("fopen");
        closedir(dir);
        return;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (has_extension(entry->d_name, ".txt")) {
            fprintf(log, "File: %s\n", entry->d_name);
            printf("[TXT] Found file: %s\n", entry->d_name);
        }
    }

    fclose(log);
    closedir(dir);
    printf("[TXT] Monitoring completed. Log saved to log_txt.txt.\n");
}

void monitor_c_files(const char *path) {
    DIR *dir;
    struct dirent *entry;

    printf("[C] Monitoring .c files in directory: %s\n", path);

    if ((dir = opendir(path)) == NULL) {
        perror("opendir");
        return;
    }

    FILE *log = fopen("log_c.txt", "w");
    if (!log) {
        perror("fopen");
        closedir(dir);
        return;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (has_extension(entry->d_name, ".c")) {
            fprintf(log, "File: %s\n", entry->d_name);
            printf("[C] Found file: %s\n", entry->d_name);
        }
    }

    fclose(log);
    closedir(dir);
    printf("[C] Monitoring completed. Log saved to log_c.txt.\n");
}

void deep_monitoring() {
    printf("[DEEP] Deep monitoring process started, PID: %d\n", getpid());
    system("git status > deep_log.txt");
    printf("[DEEP] Deep monitoring completed, log saved to deep_log.txt\n");
}

void supervisor_process(pid_t txt_pid, pid_t c_pid, pid_t deep_pid) {
    printf("[SUPERVISOR] Supervisor process started, PID: %d\n", getpid());
    printf("[SUPERVISOR] Monitoring child processes:\n");
    printf("  - TXT Process PID: %d\n", txt_pid);
    printf("  - C Process PID: %d\n", c_pid);
    printf("  - Deep Monitoring Process PID: %d\n", deep_pid);

    int status;
    pid_t finished_pid;
    while ((finished_pid = wait(&status)) > 0) {
        printf("[SUPERVISOR] Process with PID %d finished with status %d.\n", finished_pid, WEXITSTATUS(status));
    }

    printf("[SUPERVISOR] All child processes have completed.\n");
}

int main() {
    const char *repo_path = "./repository"; // Path for Git repository
    mkdir(repo_path, 0777); 

    initialize_git(repo_path);

    pid_t pid_txt = fork();

    if (pid_txt == 0) {
        // Child process for .txt files
        printf("Monitoring .txt files...\n");
        monitor_txt_files(repo_path);
        exit(0);
    }

    pid_t pid_c = fork();

    if (pid_c == 0) {
        // Child process for .c files
        printf("Monitoring .c files...\n");
        monitor_c_files(repo_path);
        exit(0);
    }

    pid_t pid_deep = fork();

    if (pid_deep == 0) {
        // Child process for deep monitoring
        deep_monitoring();;
        exit(0);
    }

    // Parent process as supervisor
    pid_t pid_supervisor = fork();

    if (pid_supervisor == 0) {
        // Supervisor process
        supervisor_process(pid_txt, pid_c, pid_deep);
        exit(0);
    }

    // Parent process
    printf("[PARENT] Parent process, PID: %d\n", getpid());

    wait(NULL); // Wait for supervisor process

    git_commit(repo_path, "Initial commit with monitored changes");
    git_status(repo_path);
    git_revert_last_commit(repo_path);

    printf("[PARENT] All processes completed.\n");

    return 0;
}
