#!/bin/bash

DURATION=5
echo "Monitoring system processes for $DURATION seconds..."

top -b -d 1 -n $DURATION | tee /tmp/top_output.txt

max_cpu_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k9 -nr | head -n 1)
max_mem_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k10 -nr | head -n 1)

echo "Process with highest CPU usage over $DURATION seconds:"
echo "PID: $(echo $max_cpu_process | awk '{print $1}'), User: $(echo $max_cpu_process | awk '{print $2}'), CPU: $(echo $max_cpu_process | awk '{print $9}'), Cmd: $(echo $max_cpu_process | awk '{print $12}')"

echo "Process with highest RAM usage over $DURATION seconds:"
echo "PID: $(echo $max_mem_process | awk '{print $1}'), User: $(echo $max_mem_process | awk '{print $2}'), RAM: $(echo $max_mem_process | awk '{print $10}'), Cmd: $(echo $max_mem_process | awk '{print $12}')"

cpu_usage=$(echo $max_cpu_process | awk '{print $9}' | cut -d'.' -f1)
ram_usage=$(echo $max_mem_process | awk '{print $10}' | cut -d'.' -f1)

pid_highest_cpu=$(echo $max_cpu_process | awk '{print $1}')

while true; do
    echo "Choose a kill signal to send to the process with the highest CPU usage:"
    echo "1. SIGCONT"
    echo "2. SIGSTOP"
    echo "3. SIGPOLL"
    echo "4. SIGHUP"
    echo "5. SIGILL"
    echo "6. Exit"
    read -p "Enter Signal option: " signal

    # Send the selected signal or exit the loop
    case $signal in
        1) kill -SIGCONT "$pid_highest_cpu" && echo "signal sent" ;;
        2) kill -SIGSTOP " $pid_highest_cpu" && echo "signal sent" ;;
        3) kill -SIGPOLL " $pid_highest_cpu" && echo "signal sent" ;;
        4) kill -SIGHUP " $pid_highest_cpu" && echo "signal sent" ;;
        5) kill -SIGILL " $pid_highest_cpu" && echo "signal sent";;
        6) echo "Exiting signal menu."; break ;;
    esac
    echo
done

rm /tmp/top_output.txt

echo "Testing Different Process States"
echo "---------------------------"

# 1. Running State Example
echo "Running State Example"
# Find a process in the "R" (running)
 state
running_pid=$(ps -e -o pid,state,cmd | grep ' R ' | awk '{print $1}' | head -n 1)
if [ -n "$running_pid" ]; then
    echo "Found running process with PID: $running_pid"
    ps -o pid,state,cmd -p $running_pid
else
    echo "No running process found."
fi

# 2. Sleeping State Example
echo "Sleeping State Example"
# Find a process in the "S" (sleeping) state
sleeping_pid=$(ps -e -o pid,state,cmd | grep ' S ' | awk '{print $1}' | head -n 1)
if [ -n "$sleeping_pid" ]; then
    echo "Found sleeping process with PID: $sleeping_pid"
    ps -o pid,state,cmd -p $sleeping_pid
else
    echo "No sleeping process found."
fi

# 3. Stopped State Example
echo "Stopped State Example"
# Find a process to stop temporarily
stopped_pid=$(ps -e -o pid,state,cmd | grep ' S ' | awk '{print $1}' | head -n 1)
if [ -n "$stopped_pid" ]; then
    echo "Found process to stop with PID: $stopped_pid"
    kill -STOP $stopped_pid
    ps -o pid,state,cmd -p $stopped_pid
    sleep 2 # Allow time to observe the stopped state
    kill -CONT $stopped_pid # Resume the process
else
    echo "No process found to stop."
fi

# 4. Zombie State Example
echo "Zombie State Example"
# Find zombie processes (state "Z")
zombie_pid=$(ps -e -o pid,state,cmd | grep ' Z ' | awk '{print $1}' | head -n 1)
if [ -n "$zombie_pid" ]; then
    echo "Found zombie process with PID: $zombie_pid"
    ps -o pid,state,cmd -p $zombie_pid
else
    echo "No zombie processes found."
fi

echo "Process state testing complete."
echo "---------------------------"


# Thresholds for CPU and RAM usage
CPU_THRESHOLD=50
RAM_THRESHOLD=50

# Function to log high-usage processes
log_high_usage_processes() {
    echo "High Resource Usage Detected"
    echo "------------------------------------"
    echo "Top processes by CPU usage:"
    ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | head -n 5
    echo "Top processes by RAM usage:"
    ps -eo pid,%cpu,%mem,cmd --sort=-%mem | head -n 5
    echo "------------------------------------"
}

# Function to check CPU and RAM usage and adjust process priorities
check_and_manage_resources() {
    # Get overall CPU and RAM usage
    CPU_USAGE=$(top -b -n 1 | awk '/Cpu\(s\)/ {print $2 + $4}')
    RAM_USAGE=$(free | awk '/Mem/ {printf "%.2f", $3/$2 * 100.0}')

    echo "CPU Usage: $CPU_USAGE%"
    echo "RAM Usage: $RAM_USAGE%"

    if (( ${CPU_USAGE%%.} > CPU_THRESHOLD || ${RAM_USAGE%%.} > RAM_THRESHOLD )); then
        log_high_usage_processes

        # Identify high-usage processes by CPU and RAM
        high_usage_pids=$(ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | awk -v cpu_thresh="$CPU_THRESHOLD" -v ram_thresh="$RAM_THRESHOLD" 'NR>1 && ($2 > cpu_thresh || $3 > ram_thresh) {print $1}')

        echo "Adjusting priorities for high-usage processes..."

        # Gradually increase the niceness of each high-usage process
        for pid in $high_usage_pids; do
            current_nice=$(ps -o ni -p $pid --no-headers)
            if [ "$current_nice" -lt 10 ]; then  # Ensure the nice value is not already high
                new_nice=$((current_nice + 5))
                renice $new_nice -p $pid
                echo "Increased niceness of process $pid to $new_nice."
            else
                echo "Process $pid already has a high niceness value ($current_nice)."
            fi
        done
    fi
}

# Main monitoring loop
while true; do
    check_and_manage_resources
    sleep 10  # Adjust the interval as needed
done
send_nonintrusive_signals
monitor_resources

