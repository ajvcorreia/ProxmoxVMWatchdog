# ProxmoxVMWatchdog
Proxmox VM watchdog service

I am currently running OPNsense as a VM on a Proxmox server this is the router I use for my home network.
Sometimes it looses connection to the ISP router so I wrote this script to restart the VM if it looses connection.

It has the following configration options:
TARGET_IP                # IP to ping
VM_ID                    # ID of VM to restart
FAIL_THRESHOLD           # Number of consecutive ping failures before action
WAIT_BETWEEN             # Time (seconds) between each watchdog check
SHUTDOWN_TIMEOUT         # Max seconds to wait for graceful shutdown
LOG_FILE="/var/log/vm_watchdog.log"

The script will ping  once every "WAIT_BETWEEN" seconds and if it fails more than "FAIL_THRESHOLD" times then it will attempt to gracefully shutdown VM with ID "VM_ID", it will wait for "SHUTDOWN_TIMEOUT" seconds and if the VM has not shutdown it will do a reset instead.

Setup Intructions:

Save the script to /usr/local/bin/vm_watchdog.sh

Make it executable:

sudo chmod +x /usr/local/bin/vm_watchdog.sh

Create and save the systemd file.

Reload systemd:
systemctl daemon-reload

Enable and start service:
sudo systemctl enable vm-watchdog.service
sudo systemctl start vm-watchdog.service

Check status and logs with:
systemctl status vm-watchdog.service
journalctl -u vm-watchdog.service -f
