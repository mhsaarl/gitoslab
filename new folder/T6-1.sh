#!/bin/bash

DURATION=30
echo "Monitoring system processes for $DURATION seconds..."
top -b -d 1 -n "$DURATION" | tee /tmp/top_output.txt

# Extract the process with the highest CPU and RAM usage
max_cpu_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k9 -nr | head -n 1)
max_mem_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k10 -nr | head -n 1)

# Display processes with highest CPU and RAM usage
echo "Process with highest CPU usage over $DURATION seconds:"
echo "PID: $(echo "$max_cpu_process" | awk '{print $1}'), User: $(echo "$max_cpu_process" | awk '{print $2}'), CPU: $(echo "$max_cpu_process" | awk '{print $9}'), Cmd: $(echo "$max_cpu_process" | awk '{print $12}')"

echo "Process with highest RAM usage over $DURATION seconds:"
echo "PID: $(echo "$max_mem_process" | awk '{print $1}'), User: $(echo "$max_mem_process" | awk '{print $2}'), RAM: $(echo "$max_mem_process" | awk '{print $10}'), Cmd: $(echo "$max_mem_process" | awk '{print $12}')"

pid_highest_cpu=$(echo "$max_cpu_process" | awk '{print $1}')

# Signal menu loop for highest CPU usage process
while true; do
    echo "Choose a kill signal to send to the process with the highest CPU usage:"
    echo "1. SIGCONT"
    echo "2. SIGSTOP"
    echo "3. SIGTERM"
    echo "4. SIGHUP"
    echo "5. SIGKILL"
    echo "6. Exit"
    read -p "Enter Signal option: " signal_option

    case $signal_option in
        1) kill -SIGCONT "$pid_highest_cpu"; echo "SIGCONT sent to process $pid_highest_cpu";;
        2) kill -SIGSTOP "$pid_highest_cpu"; echo "SIGSTOP sent to process $pid_highest_cpu";;
        3) kill -SIGTERM "$pid_highest_cpu"; echo "SIGTERM sent to process $pid_highest_cpu";;
        4) kill -SIGHUP "$pid_highest_cpu"; echo "SIGHUP sent to process $pid_highest_cpu";;
        5) kill -SIGKILL "$pid_highest_cpu"; echo "SIGKILL sent to process $pid_highest_cpu";;
        6) echo "Exiting signal menu."; break;;
        *) echo "Invalid option. Please try again.";;
    esac
done

# Clean up
rm /tmp/top_output.txt

# Function: Test different process states
test_process_states() {
     echo "Testing Different Process States"
    echo "---------------------------"

    # Running state
    echo "Running State Example"
    running_pid=$(ps -e -o pid,state,cmd --no-headers | awk '$2 ~/^R/{print $1; exit}')
    if [[ -n "$running_pid" && "$running_pid" =~ ^[0-9]+$ ]]; then
        echo "Found running process with PID: $running_pid"
        ps -o pid,state,cmd -p "$running_pid"
    else
        echo "No running process found."
    fi

    # Sleeping state
    echo "Sleeping State Example"
    sleeping_pid=$(ps -e -o pid,state,cmd --no-headers | awk '$2 == "S" {print $1; exit}')
    if [[ -n "$sleeping_pid" && "$sleeping_pid" =~ ^[0-9]+$ ]]; then
        echo "Found sleeping process with PID: $sleeping_pid"
        ps -o pid,state,cmd -p "$sleeping_pid"
    else
        echo "No sleeping process found."
    fi

    # Stopped state
    echo "Stopped State Example"
    stopped_pid=$(ps -e -o pid,state,cmd --no-headers | awk '$2 == "T" {print $1; exit}')
    if [[ -n "$stopped_pid" && "$stopped_pid" =~ ^[0-9]+$ ]]; then
        echo "Found stopped process with PID: $stopped_pid"
        ps -o pid,state,cmd -p "$stopped_pid"
    else
        echo "No stopped process found."
    fi

    # Zombie state
    echo "Zombie State Example"
    zombie_pid=$(ps -e -o pid,state,cmd --no-headers | awk '$2 == "Z" {print $1; exit}')
    if [[ -n "$zombie_pid" && "$zombie_pid" =~ ^[0-9]+$ ]]; then
        echo "Found zombie process with PID: $zombie_pid"
        ps -o pid,state,cmd -p "$zombie_pid"
    else
        echo "No zombie processes found."
    fi

    echo "Process state testing complete."
    echo "---------------------------"
}


# Function: Monitor CPU and RAM usage and adjust priorities
# Thresholds for resource usage
# Duration for monitoring in seconds
DURATION=30
CPU_THRESHOLD=50
RAM_THRESHOLD=50
LOG_FILE="/tmp/resource_monitor.log"

echo "Monitoring system processes for $DURATION seconds..."
top -b -d 1 -n $DURATION | tee /tmp/top_output.txt

# Find process with the highest CPU usage
max_cpu_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k9 -nr | head -n 1)
max_mem_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k10 -nr | head -n 1)

echo "Process with highest CPU usage over $DURATION seconds:"
echo "PID: $(echo $max_cpu_process | awk '{print $1}'), User: $(echo $max_cpu_process | awk '{print $2}'), CPU: $(echo $max_cpu_process | awk '{print $9}'), Cmd: $(echo $max_cpu_process | awk '{print $12}')"

echo "Process with highest RAM usage over $DURATION seconds:"
echo "PID: $(echo $max_mem_process | awk '{print $1}'), User: $(echo $max_mem_process | awk '{print $2}'), RAM: $(echo $max_mem_process | awk '{print $10}'), Cmd: $(echo $max_mem_process | awk '{print $12}')"

# Get CPU and RAM usage values for thresholds
cpu_usage=$(echo $max_cpu_process | awk '{print $9}' | cut -d'.' -f1)
ram_usage=$(echo $max_mem_process | awk '{print $10}' | cut -d'.' -f1)

# Log high-usage processes
log_high_usage_processes() {
    echo "High Resource Usage Detected" | tee -a "$LOG_FILE"
    echo "------------------------------------" | tee -a "$LOG_FILE"
    echo "Processes exceeding $CPU_THRESHOLD% CPU usage:" | tee -a "$LOG_FILE"
    grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k9 -nr | awk -v cpu_thresh="$CPU_THRESHOLD" '{if ($9 > cpu_thresh) print "PID: " $1 ", CPU: " $9 "%, Cmd: " $12}' | tee -a "$LOG_FILE"
    echo "Processes exceeding $RAM_THRESHOLD% RAM usage:" | tee -a "$LOG_FILE"
    grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k10 -nr | awk -v ram_thresh="$RAM_THRESHOLD" '{if ($10 > ram_thresh) print "PID: " $1 ", RAM: " $10 "%, Cmd: " $12}' | tee -a "$LOG_FILE"
    echo "------------------------------------" | tee -a "$LOG_FILE"
}

# Adjust niceness for high-usage processes
adjust_priorities() {
    high_usage_pids=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k9 -nr | awk -v cpu_thresh="$CPU_THRESHOLD" -v ram_thresh="$RAM_THRESHOLD" '{if ($9 > cpu_thresh || $10 > ram_thresh) print $1}')

    echo "Adjusting priorities for high-usage processes..."
    for pid in $high_usage_pids; do
        if [ -n "$pid" ]; then
            current_nice=$(ps -o ni -p $pid --no-headers | xargs)
            if [ "$current_nice" -lt 10 ]; then
                new_nice=$((current_nice + 5))
                if renice $new_nice -p $pid > /dev/null; then
                    echo "Increased niceness of process $pid to $new_nice." | tee -a "$LOG_FILE"
                else
                    echo "Failed to adjust niceness for process $pid. Try running as root." | tee -a "$LOG_FILE"
                fi
            else
                echo "Process $pid already has a high niceness value ($current_nice)." | tee -a "$LOG_FILE"
            fi
        fi
    done
}

# Monitor CPU and RAM usage
check_and_manage_resources() {
    if (( cpu_usage > CPU_THRESHOLD || ram_usage > RAM_THRESHOLD )); then
        log_high_usage_processes
        adjust_priorities
    else
        echo "System resources are stable."
    fi
}
# Main monitoring loop
main() {
    # Run process state tests once
    test_process_states

    # Start resource monitoring
    echo "Monitoring resource usage..."
    while true; do
        check_and_manage_resources
        sleep 5  # Adjust monitoring interval as needed
    done
}

# Execute main function
main
