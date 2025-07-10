#!/bin/bash

# Config
TARGET_IP="192.168.1.100"
VM_ID="101"
FAIL_THRESHOLD=10           # Number of consecutive ping failures before action
WAIT_BETWEEN=30             # Time (seconds) between each watchdog check
SHUTDOWN_TIMEOUT=60         # Max seconds to wait for graceful shutdown
LOG_FILE="/var/log/vm_watchdog.log"

while true; do
    fail_count=0

    # Check ping FAIL_THRESHOLD times or until success
    for i in $(seq 1 $FAIL_THRESHOLD); do
        if ! ping -c 1 -W 2 "$TARGET_IP" > /dev/null 2>&1; then
            fail_count=$((fail_count + 1))
            echo "$(date): Ping attempt $i to $TARGET_IP failed." >> "$LOG_FILE"
        else
            echo "$(date): Ping to $TARGET_IP succeeded. Resetting fail counter." >> "$LOG_FILE"
            break
        fi
        sleep 2
    done

    if [ "$fail_count" -ge "$FAIL_THRESHOLD" ]; then
        echo "$(date): $FAIL_THRESHOLD consecutive ping failures. Restarting VM $VM_ID..." >> "$LOG_FILE"

        if qm status "$VM_ID" | grep -q "status: running"; then
            echo "$(date): Sending shutdown command to VM $VM_ID..." >> "$LOG_FILE"
            qm shutdown "$VM_ID"

            stopped=0
            for ((j=1; j<=SHUTDOWN_TIMEOUT; j++)); do
                sleep 1
                if ! qm status "$VM_ID" | grep -q "status: running"; then
                    echo "$(date): VM $VM_ID shut down successfully after $j seconds." >> "$LOG_FILE"
                    stopped=1
                    break
                fi
            done

            if [ "$stopped" -eq 0 ]; then
                echo "$(date): VM $VM_ID did NOT shut down after $SHUTDOWN_TIMEOUT seconds. Performing hard reset..." >> "$LOG_FILE"
                qm reset "$VM_ID"
                sleep 10
            fi
        else
            echo "$(date): VM $VM_ID is not running. No shutdown needed." >> "$LOG_FILE"
        fi

        echo "$(date): Starting VM $VM_ID..." >> "$LOG_FILE"
        qm start "$VM_ID"
        sleep 60
    fi

    sleep "$WAIT_BETWEEN"
done
