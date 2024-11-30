#!/bin/bash

DURATION=5
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
check_and_manage_resources() {
 # Thresholds for resource usage
    CPU_THRESHOLD=50
    RAM_THRESHOLD=50

    # Get the number of CPU cores
    CPU_CORES=$(nproc)

    # Get total CPU and RAM usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    RAM_USAGE=$(free | awk '/Mem/ {printf "%.2f", $3/$2 * 100.0}')

    # Find processes exceeding CPU and RAM thresholds (normalized by cores)
    high_cpu_processes=$(ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | awk -v cpu_thresh="$CPU_THRESHOLD" -v cores="$CPU_CORES" '$2 / cores > cpu_thresh {print $1, $2 / cores, $3, $4}')
    high_ram_processes=$(ps -eo pid,%cpu,%mem,cmd --sort=-%mem | awk -v ram_thresh="$RAM_THRESHOLD" '$3 > ram_thresh {print $1, $2, $3, $4}')

    # Check if any high-resource processes exist
    if [[ -n "$high_cpu_processes" || -n "$high_ram_processes" ]]; then
        echo "High Resource Usage Detected!"
        echo "------------------------------------"

        # Adjust niceness for high CPU processes
        if [[ -n "$high_cpu_processes" ]]; then
            echo "Processes exceeding $CPU_THRESHOLD% CPU usage:"
            echo "$high_cpu_processes" | while read -r pid cpu ram cmd; do
                echo "PID: $pid, CPU: $cpu%, RAM: $ram%, CMD: $cmd"
                if ps -p "$pid" > /dev/null 2>&1; then
                    current_nice=$(ps -o ni -p $pid --no-headers | xargs)
                    if [[ "$current_nice" -lt 10 ]]; then
                        new_nice=$((current_nice + 5))
                        if renice "$new_nice" -p "$pid" > /dev/null; then
                            echo "  → Niceness of process $pid increased to $new_nice."
                        else
                            echo "  → Failed to adjust niceness for process $pid. Try running as root."
                        fi
                    else
                        echo "  → Process $pid already has a high niceness value ($current_nice)."
                    fi
                else
                    echo "  → Process $pid no longer exists."
                fi
            done
        fi

        # Adjust niceness for high RAM processes
        if [[ -n "$high_ram_processes" ]]; then
            echo "Processes exceeding $RAM_THRESHOLD% RAM usage:"
            echo "$high_ram_processes" | while read -r pid cpu ram cmd; do
                echo "PID: $pid, CPU: $cpu%, RAM: $ram%, CMD: $cmd"
                if ps -p "$pid" > /dev/null 2>&1; then
                    current_nice=$(ps -o ni -p $pid --no-headers | xargs)
                    if [[ "$current_nice" -lt 10 ]]; then
                        new_nice=$((current_nice + 5))
                        if renice "$new_nice" -p "$pid" > /dev/null; then
                            echo "  → Niceness of process $pid increased to $new_nice."
                        else
                            echo "  → Failed to adjust niceness for process $pid. Try running as root."
                        fi
                    else
                        echo "  → Process $pid already has a high niceness value ($current_nice)."
                    fi
                else
                    echo "  → Process $pid no longer exists."
                fi
            done
        fi

        echo "------------------------------------"
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
        sleep 10  # Adjust monitoring interval as needed
    done
}

# Execute main function
main
