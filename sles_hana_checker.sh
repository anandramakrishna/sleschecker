#!/bin/bash

FNIC_GOLDEN_VERSION="1.6.0.27"
ENIC_GOLDEN_VERSION="2.3.0.30"
KERNEL_GOLDEN_VERSION="3.12.49-11-default"
VERBOSE="0"
FAILURECNT=0
LOCATION=""
NFS_GW=""
USERNAME=""
SID=""
EXTENDED_MODE=0
#FSTAB_LOCATION="/etc/fstab"
FSTAB_LOCATION="fstab.test"

function logInfo 
{
    if [ $VERBOSE == "1" ]; then
        echo "INFO: $1"
    fi
}

function logError
{
    ((FAILURECNT++))
    echo "ERROR! $1"
}

function displayUsage
{
    echo
    echo Usage: "$0" [options]
    echo "    -v              verbose"
    echo "    -l <location>.  Must be westus or eastus."
    echo "    -x              Expanded mode - checks for additional things beyond basics."
#    echo "    -n <nfs gw>     FQDN or IP Address of nfs gateway"
#    echo "    -u <username>   Username"
#    echo "    -s <sid>        SID"
}

function init
{
    while getopts ":vl:x" opt; do
      case ${opt} in
        v )
          VERBOSE="1"
          ;;
        l )
          LOCATION="$OPTARG"
          if [ "$LOCATION" != "westus" -a "$LOCATION" != "eastus" ]; then
              echo "Invalid location '$LOCATION' specified.  "
              displayUsage
              exit 1
          fi
          ;;
        n )
          NFS_GW="$OPTARG"
          ;;
        u )
          USERNAME="$OPTARG"
          ;;
        s )
          SID="$OPTARG"
          ;;
        x )
          EXTENDED_MODE=1
          ;;
        : )
          echo "Required value for -$OPTARG missing."
          displayUsage
          exit 1
          ;;
        \? )
          displayUsage
          exit 1
          ;;
      esac
    done

    if [ -z "$LOCATION" ]; then
        echo "Location unspecified.  -l is a required parameter."
        displayUsage
        exit 1
    fi
#    if [ -z "$NFS_GW" ]; then
#        echo "NFS Gateway unspecified.  -n is a required parameter."
#        displayUsage
#        exit 1
#    fi
#    if [ -z "$USERNAME" ]; then
#        echo "Username unspecified.  -u is a required parameter."
#        displayUsage
#        exit 1
#    fi
#    if [ -z "$SID" ]; then
#        echo "SID unspecified.  -s is a required parameter."
#        displayUsage
#        exit 1
#    fi

}

function checkKernelCmdLine
{
    cmdArg=$1
    OUTPUT=$(cat /proc/cmdline | grep $cmdArg)
    if [ ! "$OUTPUT" ]; then
        logError "Did not found $cmdArg in kernel cmdline"
    else
        logInfo "Found $cmdArg in kernel cmdline"
    fi
}

function checkProcValue
{
    procPath=$1
    expected=$2

    value=$(cat $procPath)
    checkValue "$value" "$expected" "$procPath"
}

function checkValue
{
    value=$1
    expected=$2
    type=$3

    if [ "$value" != "$expected" ]; then
        logError "Unexpected value for $type.  Found: $value, Expected: $expected"
    else
        logInfo "$procPath is set to $expected"
    fi
}

init $@

logInfo "Location set to: $LOCATION"
logInfo "Extended mode set to: $EXTENDED_MODE"
#logInfo "NFS GW set to: $NFS_GW"
#logInfo "Username set to: $USERNAME"
#logInfo "SID set to: $SID"

DATE=$(date +"%Z")
case $LOCATION in
  westus )
    checkValue $DATE "PST" "timezone"
    ;;
  eastus )
    checkValue $DATE "EST" "timezone"
    ;;
esac


VERSION=$(sudo modinfo fnic | grep -G "^version:" | awk -F:       '{print $2}')

if [ $VERSION != $FNIC_GOLDEN_VERSION ]; then
    logError "Unexpected fnic version found. Found: $VERSION, Expected: $FNIC_GOLDEN_VERSION"
else
    logInfo "Expected fnic version $VERSION found."
fi

VERSION=$(sudo modinfo enic | grep -G "^version:" | awk -F:       '{print $2}')

if [ $VERSION != $ENIC_GOLDEN_VERSION ]; then
    logError "Unexpected enic version found. Found: $VERSION, Expected: $ENIC_GOLDEN_VERSION"
else
    logInfo "Expected enic version $VERSION found."
fi

VERSION=$(uname -r)

if [ $VERSION != $KERNEL_GOLDEN_VERSION ]; then
    logError "Unexpected kernel version found.  Found: $VERSION, Expected: $KERNEL_GOLDEN_VERSION"
else
    logInfo "echo Expected kernel $VERSION found."
fi

# Check if all of the disks are mounted by uuid and not by scsi/lun names since those are
# non-deterministic

OUTPUT=$(awk -v verbose=$VERBOSE '
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s } 
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s } 
function trim(s)  { return rtrim(ltrim(s)); } 
{
    if ($1 ~ /uuid|UUID/)
    {
        if (verbose == "1")
        {
            print "INFO: "$1, " in fstab mounted by uuid"
        }
    }
    else if ($3 ~ /nfs/)
    {
        print "INFO: "$1, " in fstab mounted by nfs"
    }
    else
    {
        # exclude blank lines and comments
        firstRecord = trim($1)
        if (firstRecord == "")
        {
            print "INFO: Skipping empty line"
        }
        else if  (firstRecord ~ /^#/)
        {
            print "INFO: Skipping comment"
        }
        else
        {
            print "ERROR! Disk ", $1, " in fstab not mounted by uuid."
        }
    }
}
' < $FSTAB_LOCATION)
echo "$OUTPUT"
let FAILURECNT=FAILURECNT+$(echo "$OUTPUT" | grep "ERROR!" | wc -l)

#Make sure max_cstate is set to 1
checkProcValue "/sys/module/intel_idle/parameters/max_cstate" 1

#Check a bunch of stuff from proc/sys
checkProcValue "/proc/sys/kernel/numa_balancing" 0

checkProcValue "/proc/sys/vm/pagecache_limit_mb" 0

checkProcValue "/proc/sys/net/ipv4/tcp_moderate_rcvbuf" 1
checkProcValue "/proc/sys/net/ipv4/tcp_window_scaling" 1
checkProcValue "/proc/sys/net/ipv4/tcp_timestamps" 1
checkProcValue "/proc/sys/net/ipv4/tcp_sack" 1

if [ $EXTENDED_MODE -ne 0 ]; then
    checkProcValue "/sys/kernel/mm/transparent_hugepage/enabled" "always madvise [never]"

    checkProcValue "/proc/sys/net/ipv4/tcp_slow_start_after_idle" 0
    checkProcValue "/proc/sys/net/ipv4/tcp_rmem" "65536 16777216 16777216"
    checkProcValue "/proc/sys/net/ipv4/tcp_wmem" "65536 16777216 16777216"
    checkProcValue "/proc/sys/net/ipv4/tcp_no_metrics_save" 1

    checkProcValue "/proc/sys/net/ipv4/tcp_max_syn_backlog" 8192

    checkProcValue "/proc/sys/sunrpc/tcp_slot_table_entries" 128

    checkProcValue "/proc/sys/net/core/rmem_max" 16777216
    checkProcValue "/proc/sys/net/core/wmem_max" 16777216
    checkProcValue "/proc/sys/net/core/rmem_default" 16777216
    checkProcValue "/proc/sys/net/core/wmem_default" 16777216
    checkProcValue "/proc/sys/net/core/optmem_max" 16777216
    checkProcValue "/proc/sys/net/core/netdev_max_backlog" 300000
    checkProcValue "/proc/sys/net/core/somaxconn" 4096
fi

echo
echo -----------------------------------
if [ $FAILURECNT -gt 0 ]; then
    echo Found $FAILURECNT errors.
else
    echo SUCCESS! 
fi
echo -----------------------------------


