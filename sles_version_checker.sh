#!/bin/bash

FNIC_GOLDEN_VERSION="1.6.0.27"
ENIC_GOLDEN_VERSION="2.3.0.30"
KERNEL_GOLDEN_VERSION="3.12.49-11-default"
VERBOSE="1"
FAILURECNT=0

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
{ 
    if ($1 ~ /uuid|UUID/)
    {
        if (verbose == "1")
        {
            print "INFO: "$1, " in fstab mounted by uuid"
        }
    }
    else 
    {
        print "ERROR! Disk ", $1, " in fstab not mounted by uuid."
    }
}
' < /etc/fstab)
echo "$OUTPUT"
let FAILURECNT=FAILURECNT+$(echo "$OUTPUT" | grep "ERROR!" | wc -l)

# Make sure NUMA_BALANCING is disabled in kernel cmdline
OUTPUT=$(cat /proc/cmdline | grep numa_balancing=disable)
if [ ! "$OUTPUT" ]; then
    logError "numa_balancing is not disabled in kernel cmdline"
else
    logInfo "Found numa_balancing is disabled in kernel cmdline"
fi

# Make sure transparent hugepages are disabled
OUTPUT=$(cat /proc/cmdline | grep "transparent_hugepage=never")
if [ ! "$OUTPUT" ]; then
    logError "transparent_hugepage is not disabled in kernel cmdline"
else
    logInfo "Found transparent_hugepage disabled in kernel cmdline"
fi

#Make sure max_cstate is set to 1
OUTPUT=$(cat /proc/cmdline | grep "intel_idle.max_cstate=1")
if [ ! "$OUTPUT" ]; then
    logError "intel_idle.maxcstate is not set to 1 in kernel cmdline"
else
    logInfo "Found intel_idle.maxcstate set to 1 in kernel cmdline"
fi

#Make sure page cache limit is set to 0 (default)
OUTPUT=$(cat /proc/sys/vm/pagecache_limit_mb)
if [ $OUTPUT != "0" ]; then
    logError "/proc/sys/vm/pagecache_limit_mb is not 0"
else
    logInfo "pagecache_limit_mb is set to 0"
fi

echo
echo -----------------------------------
if [ $FAILURECNT -gt 0 ]; then
    echo Found $FAILURECNT errors.
else
    echo SUCCESS! 
fi
echo -----------------------------------


