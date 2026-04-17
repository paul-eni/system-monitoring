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
	rawCPUUsage=$(( ($busyCPUTime*10000)/$totalCPUTime ))
	integer=$(( $rawCPUUsage / 100 ))
	decimal=$(( $rawCPUUsage % 100 ))
	CPUUsage=$(printf "%d.%02d" "$integer" "$decimal")
fi
cPUUsageInPercent=$(printf "%s%%" "$CPUUsage")

#system load average, if > 1 the CPU is overworked)
read oneMinuteLoad fiveMinutesLoad fifteenMinutesLoad _ < /proc/loadavg
loadAvg="$oneMinuteLoad, $fiveMinutesLoad, $fifteenMinutesLoad"



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
#removes . and miliseconds from the uptime
uptimeInSeconds=${uptimeInSeconds%.*}
uptimeDays=$(( $uptimeInSeconds/86400 ))
uptimeHours=$(( ($uptimeInSeconds%86400)/3600 ))
uptimeMinutes=$(( ($uptimeInSeconds%3600)/60 ))
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


addStyleToList() {
	rawString=$(paste -sd ";" <<< $1)
	prettyString=$(sed 's/;/, /g' <<< $rawString)
	echo $prettyString
}

printConsole() {
	printf "%-20s : %s\n" "$1" "$2"
}


### [OUTPUT DISPLAY] ###

printf "\n==================== SYSTEM MONITOR ====================\n"

printf "\n[CPU]\n"

printConsole "Usage" "$cPUUsageInPercent"
printConsole "Load Average" "$loadAvg"

printf "\n[MEMORY]\n"

printConsole "Total" "$totalMemory"
printConsole "Used" "$usedMemory"
printConsole "Available" "$availableMemory"
printConsole "Swap available" "$swapAvailable"

printf "\n[DISK]\n"

printConsole "Total" "$totalDisk"
printConsole "Used" "$usedDisk"
printConsole "Available" "$availableDisk"
printConsole "Usage" "$diskUsage"

printf "\n[SYSTEM]\n"

printConsole "Uptime" "$uptime"
printConsole "Processes" "$numberOfProc"

prettyCurrentlyLoggedInUsers=$(addStyleToList "$currentlyLoggedInUsers")
printConsole "Logged in users" "$currentlyLoggedInUsers"

printf "\n[NETWORK]\n"

prettyServerIPAddresses=$(addStyleToList "$serverIPAddresses")
printConsole "IP addresses" "$prettyServerIPAddresses"

prettyIpInterfaces=$(addStyleToList "$ipInterfaces")
printConsole "IP interfaces" "$prettyIpInterfaces"

prettyPorts=$(addStyleToList "$ports")
printConsole "Listened ports" "$prettyPorts"

printf "\n========================================================\n"