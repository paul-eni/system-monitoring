# Ubuntu minimal server monitoring script


## description

A Bash-based monitoring script for a minimalist Ubuntu server that collects key metrics (such RAM and network information for instance) using only native Linux system files and commands (e.g. /proc/stat...), without external dependencies.


## goal

This project emerged as a learning project to improve bash skills as well as Linux's architecture and overall behaviour. 

As such, its main purpose consists of delivering desired output without dependencies other than the ones provided during by the server's ISO image.


## features

The scripts monitors the following:
- CPU: usage, load average
- RAM: total, used, available, swap
- Disk: total, used, available, usage %
- System: uptime, number of processes, logged-in users
- Network: IPs, interfaces, ports


## install and execution

1. Clone the repository:

```bash
git clone https://github.com/paul-eni/system-monitoring.git
cd system-monitoring
```

2. Launch the script with

```bash
./system_monitoring.sh
```

/!\ if the script fails to launch, please check file's permission with
```bash
ls -l
```
if letter 'x' is missing after 'u', trigger the following to allow script's execution for you only 
```bash
chmod u+x system_monitoring.sh
```


## output example

```text
==================== SYSTEM MONITOR ====================


[CPU]
Usage                : 12.34%
Load Average         : 0.15, 0.10, 0.05


[MEMORY]
Total                : 8G
Used                 : 3G
Available            : 5G
Swap available       : 2G


[DISK]
Uptime               : 0 days, 2 hours, 31 minutes,
Number of processes  : 102
Logged in users      : user1, user2


[NETWORK]

IP addresses         :  127.0.0.1/8, <private_ip>
IP interfaces        :  lo, enp0s3
Listened ports       :  53, 68


========================================================
```


## technical choices

- Ubuntu server's version: Ubuntu 24.04.4 LTS

- metrics sources: I tried to stick as close as possible to Linux's data source. Therefore, I prioritized system files over commands.
For instance, instead of using ```bash top ``` command for CPU usage, I searched for the values in /proc/stat file.

## possible improvements

Possible improvements:
- Refactor output to separate data retrieval and display
- Enhance network activity monitoring
- Implement alerting for thresholds (CPU, memory, disk)
- Convert the script into a real-time/live monitoring tool
