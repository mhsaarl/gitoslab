#!/bin/bash

# Part 1: Monitor processes for highest CPU and RAM usage over a limited time

# Duration to monitor (in seconds)
DURATION=60

# Temporary file to store top output
TEMP_FILE=$(mktemp)

# Capture `top` output for the specified duration
top -b -d 1 -n "$DURATION" > "$TEMP_FILE"

# Find the process with the highest CPU usage during the period
highest_cpu_process=$(awk 'NR==1 || $9 > max_cpu {max_cpu=$9; max_cpu_line=$0} END {print max_cpu_line}' "$TEMP_FILE")
highest_cpu_pid=$(echo "$highest_cpu_process" | awk '{print $1}')

# Find the process with the highest memory usage during the period
highest_mem_process=$(awk 'NR==1 || $10 > max_mem {max_mem=$10; max_mem_line=$0} END {print max_mem_line}' "$TEMP_FILE")
highest_mem_pid=$(echo "$highest_mem_process" | awk '{print $1}')

# Display the results
echo "Process with the highest CPU usage in the last $DURATION seconds:"
echo "$highest_cpu_process"
echo
echo "Process with the highest RAM usage in the last $DURATION seconds:"
echo "$highest_mem_process"
echo

# Loop for sending signals until the user chooses to exit
while true; do
    echo "Choose a signal to send to the highest CPU usage process (PID: $highest_cpu_pid):"
    echo "1) SIGINT  - Interrupt (graceful stop)"
    echo "2) SIGSTOP - Pause process"
    echo "3) SIGCONT - Resume process"
    echo "4) SIGHUP  - Reload configuration"
    echo "5) SIGQUIT - Quit and generate core dump"
    echo "6) Exit"
    read -p "Enter the option number: " signal_option

    # Send the selected signal or exit the loop
    case $signal_option in
        1) kill -2 "$highest_cpu_pid" && echo "SIGINT sent to process $highest_cpu_pid" ;;
        2) kill -19 "$highest_cpu_pid" && echo "SIGSTOP sent to process $highest_cpu_pid" ;;
        3) kill -18 "$highest_cpu_pid" && echo "SIGCONT sent to process $highest_cpu_pid" ;;
        4) kill -1 "$highest_cpu_pid" && echo "SIGHUP sent to process $highest_cpu_pid" ;;
        5) kill -3 "$highest_cpu_pid" && echo "SIGQUIT sent to process $highest_cpu_pid (core dump may be generated)" ;;
        6) echo "Exiting signal selection loop."; break ;;
        *) echo "Invalid option. Please enter a number from 1 to 6." ;;
    esac
    echo
done

# Clean up temporary file
rm "$TEMP_FILE"

echo "---------------------------"
echo "Testing Different Process States"
echo "---------------------------"

# 1. Running State Example
echo "Running State Example"
bash -c 'while :; do :; done' &
running_pid=$!
ps -o pid,state,cmd -p $running_pid
sleep 2 # Allow some time to observe
kill $running_pid # Terminate the running process
echo "Running process terminated."

# 2. Sleeping State Example
echo "Sleeping State Example"
sleep 60 &
sleeping_pid=$!
ps -o pid,state,cmd -p $sleeping_pid
kill $sleeping_pid # Terminate the sleeping process
echo "Sleeping process terminated."

# 3. Stopped State Example
echo "Stopped State Example"
bash -c 'while :; do :; done' &
stopped_pid=$!
kill -STOP $stopped_pid
ps -o pid,state,cmd -p $stopped_pid
kill -CONT $stopped_pid
kill $stopped_pid # Terminate the stopped process
echo "Stopped process terminated."

# 4. Zombie State Example
echo "Zombie State Example"
bash -c '(sleep 0.1) & wait' &
zombie_pid=$!
sleep 0.2 # Allow time for the child to exit and become a zombie
ps -e -o pid,state,cmd | grep " Z "
kill $zombie_pid # Terminate the parent to clean up the zombie
echo "Zombie process cleaned up."

echo "Process state testing complete."
echo "---------------------------"

# Part 4: Monitor CPU and RAM usage and ensure system stability
CPU_THRESHOLD=50
RAM_THRESHOLD=50
MONITOR_INTERVAL=10

# Function to log high CPU and RAM processes
log_high_usage_processes() {
    echo "High Resource Usage Detected"
    echo "------------------------------------"
    echo "Top processes by CPU:"
    ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | head -n 5
    echo "Top processes by RAM:"
    ps -eo pid,%cpu,%mem,cmd --sort=-%mem | head -n 5
    echo "------------------------------------"
    echo
}

# Function to check if resource usage exceeds threshold
check_usage() {
    # Get overall CPU and RAM usage
    CPU_USAGE=$(top -b -n 1 | awk '/Cpu\(s\)/ {print $2 + $4}')
    RAM_USAGE=$(free | awk '/Mem/ {printf "%.2f", $3/$2 * 100.0}')

    echo "CPU Usage: $CPU_USAGE%"
    echo "RAM Usage: $RAM_USAGE%"

    if (( ${CPU_USAGE%%.} > CPU_THRESHOLD || ${RAM_USAGE%%.
} > RAM_THRESHOLD )); then
        log_high_usage_processes

        # Find non-critical processes with high CPU or RAM usage
        high_usage_pids=$(ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | awk -v cpu_thresh="$CPU_THRESHOLD" -v ram_thresh="$RAM_THRESHOLD" 'NR>1 && ($2 > cpu_thresh || $3 > ram_thresh) {print $1}')

        echo "Applying corrective actions to high usage processes..."
        
        # Pause (SIGSTOP) each high usage process to reduce load temporarily
        for pid in $high_usage_pids; do
            kill -STOP $pid
            echo "Paused process $pid to reduce load."
            sleep 1  # Delay to observe the effect

            # Resume (SIGCONT) process if needed to keep the system stable
            kill -CONT $pid
            echo "Resumed process $pid after temporary pause."
        done
    fi
}

# Main monitoring loop
while true; do
    check_usage
    sleep $MONITOR_INTERVAL
done
