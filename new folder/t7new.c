#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <math.h>
#include <time.h>
#include <string.h>

int gcd(int a, int b) {
    return b == 0 ? a : gcd(b, a % b);
}

int lcm(int a, int b) {
    return (a * b) / gcd(a, b);
}

typedef struct {
    char name[50];
    int duration;
} Task;

int main() {
    int mode, operation, num1, num2;
    int  result = 0;
    
    printf("Enter mode (1 or 2 or 3): ");
    scanf("%d", &mode);
    
    if (mode == 1) {
     
        printf("Enter first number: ");
        scanf("%d", &num1);
        printf("Enter second number: ");
        scanf("%d", &num2);

        printf("menu:\n1. Add\n2. Subtract\n3. Multiply\n4. Divide\n5. GCD\n6. LCM\n7. Power\n8. Square Root\n");
        scanf("%d", &operation);

        pid_t pid = fork();
        if (pid==0) {
     
            switch (operation) {
                case 1: result = num1 + num2; break;
                case 2: result = num1 - num2; break;
                case 3: result = num1 * num2; break;
               case 4: result = (num2 != 0) ? num1 / num2 : 0; break;
                case 5: result = gcd(num1, num2); break;
                case 6: result = lcm(num1, num2); break;
               case 7: result = pow(num1, num2); break;
                case 8: result = sqrt(num1); break;
                
            }
            printf("Child Process with pid %d is created and calculated the result. Operation result is %d\n", getpid(), result);
            exit(result);  
        } else if (pid>1){
           
            int status;
            wait(&status);
            result = WEXITSTATUS(status);
            printf("Parent with pid %d shows the result: %d\n", getpid(), result);

            pid_t pid2 = fork(); 
            if (pid2==0) {
                int remainder_num;
                printf("Enter another number for calculating remainder: ");
                scanf("%d", &remainder_num);
                int k;
                k  = result % remainder_num;
                printf("Child with pid %d calculated the remainder: %d\n", getpid(), k);
                exit(0);
            } else {
                wait(NULL);  
            }
        }
    } else if (mode == 2) {
       
        printf("Enter first number: ");
        scanf("%d", &num1);
        
        pid_t pid = fork();      

        if (pid == 0) {
            printf("Enter second number: ");
            scanf("%d", &num2);           
            printf("Child with pid %d created and got the second number\n", getpid()); 
            pid_t pid2 = fork(); 
            if (pid2 == 0) {
                printf("menu:\n1. Add\n2. Subtract\n3. Multiply\n4. Divide\n5. GCD\n6. LCM\n7. Power\n8. Square Root\n");
                scanf("%d", &operation);
                switch (operation) {
                    case 1: result = num1 + num2; break;
                    case 2: result = num1 - num2; break;
                    case 3: result = num1 * num2; break;
                    case 4: result = (num2 != 0) ? num1 / num2 : 0; break;
                     case 5: result = gcd(num1, num2); break;
                    case 6: result = lcm(num1, num2); break;
                    case 7: result = pow(num1, num2); break;
                    case 8: result = sqrt(num1); break; }
                printf("Child with pid %d calculated the result: %d\n", getpid(), result);
                exit(result);  
            } else {
                int status;
                wait(&status);
                result = WEXITSTATUS(status);
                printf("Parent with pid %d Received result: %d\n", getpid(), result);

                pid_t pid3 = fork();  
                if (pid3 == 0) {
                    int remainder_num;
                    printf("Enter  number for finding remainder: ");
                    scanf("%d", &remainder_num);
                    int r = result % remainder_num;
                    printf("anothe Child with pid %d was created and calculated the Remainder: %d\n", getpid(), r);
                    exit(0);
                } else {
                    wait(NULL); 
                }
            }
        } else {
            wait(NULL); 
        }
    } else {
         int num_tasks;
    printf("Enter number of tasks: ");
    scanf("%d", &num_tasks);

    Task tasks[num_tasks];
    for (int i = 0; i < num_tasks; i++) {
        printf("Enter name for task %d: ", i + 1);
        scanf("%s", tasks[i].name);
        printf("Enter duration for task %d (in seconds): ", i + 1);
        scanf("%d", &tasks[i].duration);
    }

    
    time_t start_time = time(NULL);

    for (int i = 0; i < num_tasks; i++) {
        pid_t pid = vfork(); 

        if (pid == 0) { // Child process
            printf("Child with pid %d was created for Task '%s' with duration %d seconds\n", getpid(), tasks[i].name, tasks[i].duration);
            sleep(tasks[i].duration); 
            printf(" Task '%s' with pid %d is completed!\n", tasks[i].name, getpid());
            exit(0);
        } else if (pid < 0) {
            perror(" vfork failed ");
            exit(1);
        }
    }

    // Parent process 
    int status;
    while (wait(&status) > 0);

    time_t end_time = time(NULL);
    printf("tasks completed by parent\nparent PID:%d  ", getpid());
    printf("Total time: %ld seconds\n", end_time - start_time);
    }

    return 0;
}
