#!/bin/bash

DURATION=5
CPU_THRESHOLD=50
RAM_THRESHOLD=50

echo "Monitoring system processes for $DURATION seconds..."

top -b -d 1 -n $DURATION | tee /tmp/top_output.txt

max_cpu_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k9 -nr | head -n 1)
max_mem_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k10 -nr | head -n 1)
min_cpu_process=$(grep -E "^[ ]*[0-9]+" /tmp/top_output.txt | sort -k9 -nr | head -n 1)

 
echo "Process with highest CPU usage over $DURATION seconds:"
echo "PID: $(echo $max_cpu_process | awk '{print $1}'), User: $(echo $max_cpu_process | awk '{print $2}'), CPU: $(echo $max_cpu_process | awk '{print $9}'), Cmd: $(echo $max_cpu_process | awk '{print $12}')"

echo "Process with highest RAM usage over $DURATION seconds:"
echo "PID: $(echo $max_mem_process | awk '{print $1}'), User: $(echo $max_mem_process | awk '{print $2}'), RAM: $(echo $max_mem_process | awk '{print $10}'), Cmd: $(echo $max_mem_process | awk '{print $12}')"

cpu_usage=$(echo $max_cpu_process | awk '{print $9}' | cut -d'.' -f1)
ram_usage=$(echo $max_mem_process | awk '{print $10}' | cut -d'.' -f1)

send_nonintrusive_signals() {
    pid=$(echo $min_cpu_process | awk '{print $1}')
    echo -e "\nSending non-intrusive signals to process with PID: $pid"
      kill -3 $pid
           
}

monitor_resources() {
    echo -e "\nMonitoring system resources for stability..."
    
    if (( cpu_usage > CPU_THRESHOLD )); then
        echo "Warning: CPU usage exceeded threshold - $cpu_usage%"
    fi

    if (( ram_usage > RAM_THRESHOLD )); then
        echo "Warning: RAM usage exceeded threshold - $ram_usage%"
    fi
}

send_nonintrusive_signals
monitor_resources

