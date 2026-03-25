#!/bin/bash

### [CPU] ###

#global CPU usage in % 
#first snapshot
firstCPUSnapshot=$(grep '^cpu ' /proc/stat)

#wait 1 second 
sleep 1 

#second snapshot
secondCPUSnapshot=$(grep '^cpu ' /proc/stat)

#Deltas between the two snapshots
read buffer userSnapshotOne niceSnapshotOne systemSnapshotOne idleSnapshotOne iowaitSnapshotOne irqSnapshotOne softIrqSnapshotOne stealSnapshotOne _ <<< "$firstCPUSnapshot"
read buffer userSnapshotTwo niceSnapshotTwo systemSnapshotTwo idleSnapshotTwo iowaitSnapshotTwo irqSnapshotTwo softIrqSnapshotTwo stealSnapshotTwo _ <<< "$secondCPUSnapshot"

deltaUser=$(( userSnapshotTwo-userSnapshotOne ))
deltaNice=$(( niceSnapshotTwo-niceSnapshotOne ))
deltaSystem=$(( systemSnapshotTwo-systemSnapshotOne ))
deltaIdle=$(( idleSnapshotTwo-idleSnapshotOne ))
deltaIowait=$(( iowaitSnapshotTwo-iowaitSnapshotOne ))
deltaIrq=$(( irqSnapshotTwo-irqSnapshotOne ))
deltaSoftirq=$(( softIrqSnapshotTwo-softIrqSnapshotOne ))
deltaSteal=$(( stealSnapshotTwo-stealSnapshotOne ))

totalCPUTime=$(( deltaUser+deltaNice+deltaSystem+deltaIdle+deltaIowait+deltaIrq+deltaSoftirq+deltaSteal ))
busyCPUTime=$(( totalCPUTime-deltaIdle-deltaIowait ))


if [ "$totalCPUTime" -eq 0 ] 
then
	echo "Impossible to compute usage of CPU: division by 0"
else 
	rawCPUUsage=$(( (busyCPUTime*10000)/$totalCPUTime ))
	integer=$(( rawCPUUsage / 100 ))
	decimal=$(( rawCPUUsage % 100 ))
	CPUUsage=$(printf "%d.%02d" "$integer" "$decimal")
fi

#system load average, if > 1 the CPU is overworked)
read oneMinuteLoad fiveMinutesLoad fifteenMinutesLoad _ < /proc/loadavg



### [MEMORY] ###

freeCommandOutput=$(free --si -h)
memory=$(grep Mem: <<< "$freeCommandOutput")
swapMemory=$(grep Swap: <<< "$freeCommandOutput")

totalMemory=$(awk '{print $2}' <<< "$memory")
usedMemory=$(awk '{print $3}' <<< "$memory")
availableMemory=$(awk '{print $7}' <<< "$memory")

swapAvailable=$(awk '{print $4}' <<< "$swapMemory")


### [DISK] ###

# "< <" secures the output from df into a temp file which is then passed on to read 
read totalDisk usedDisk availableDisk diskUsage < <(df -h --total | awk '/total/ {print $2, $3, $4, $5}')



### [SYSTEM] ###

read uptimeInSeconds _ < /proc/uptime
uptimeInSeconds=${uptimeInSeconds%.*}
uptimeDays=$(( uptimeInSeconds/86400 ))
uptimeHours=$(( (uptimeInSeconds%86400)/3600 ))
uptimeMinutes=$(( (uptimeInSeconds%3600)/60 ))
uptime=$(printf "%s days, %s hours, %s minutes" "$uptimeDays" "$uptimeHours" "$uptimeMinutes")

# -e means that all processes are fetched and then only the PID column is kept with -o
numberOfProc=$(ps -e -o pid --no-headers | wc -l)

#paste -sd enables to reformat the output by separing each entry by a comma,
#'-' is mandatory to block paste from expecting a file and using stdin instead 
currentlyLoggedInUsers=$(who | awk '{print $1}' | sort -u | paste -sd "," - | sed 's/,/, /' )



### [NETWORK] ###

serverIPAddresses=$(ip -4 address show up | awk '/inet/ {print $2}' | paste -sd "," - | sed 's/,/, /' )
ipInterfaces=$(ip -br address show up | awk '{print $1}' | paste -sd "," - | sed 's/,/, /' ) 

#list of active TCP/UDP ports
ports=$(ss -ltun | awk 'NR > 1 {split($5, a, ":"); print a[length(a)]}' | sort -u | paste -sd "," - | sed 's/,/, /' )



### [OUTPUT DISPLAY] ###

printf "\n==================== SYSTEM MONITOR ====================\n\n"

printf "[CPU]\n"
printf "%-20s : %s%%\n" "Usage" "$CPUUsage"
loadavg="$oneMinuteLoad, $fiveMinutesLoad, $fifteenMinutesLoad"
printf "%-20s : %s\n" "Load Average" "$loadavg"

printf "\n[MEMORY]\n"
printf "%-20s : %s \n" "Total" "$totalMemory"
printf "%-20s : %s \n" "Used" "$usedMemory"
printf "%-20s : %s \n" "Available" "$availableMemory"
printf "%-20s : %s \n" "Swap available" "$swapAvailable"

printf "\n[DISK]\n"
printf "%-20s : %s \n" "Total" "$totalDisk"
printf "%-20s : %s \n" "Used" "$usedDisk"
printf "%-20s : %s \n" "Available" "$availableDisk"
printf "%-20s : %s\n" "Usage" "$diskUsage"

printf "\n[SYSTEM]\n"
printf "%-20s : %s\n" "Uptime" "$uptime"
printf "%-20s : %s\n" "Processes" "$numberOfProc"
printf "%-20s : %s\n" "Logged in users" "$currentlyLoggedInUsers"

printf "\n[NETWORK]\n"

printf "%-20s : %s\n" "IP addresses" "$serverIPAddresses"
printf "%-20s : %s\n" "IP interfaces" "$ipInterfaces"
printf "%-20s : %s\n" "Listened ports" "$ports"

printf "\n========================================================\n"