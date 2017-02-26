#!/bin/bash

FNIC_GOLDEN_VERSION="1.6.0.27"
ENIC_GOLDEN_VERSION="2.3.0.30"
KERNEL_GOLDEN_VERSION="3.12.49-11-default"
VERBOSE="1"
FAILURECNT=0

function logInfo 
{
    if [ $VERBOSE == "1" ]; then
        echo $1
    fi
}

function logError
{
    ((FAILURECNT++))
    echo $1
}

VERSION=$(sudo modinfo fnic | grep -G "^version:" | awk -F:       '{print $2}')

if [ $VERSION != $FNIC_GOLDEN_VERSION ]; then
    logError "ERROR!  Unexpected fnic version found. Found: $VERSION, Expected: $FNIC_GOLDEN_VERSION"
else
    logInfo "Expected fnic version $VERSION found."
fi

VERSION=$(sudo modinfo enic | grep -G "^version:" | awk -F:       '{print $2}')

if [ $VERSION != $ENIC_GOLDEN_VERSION ]; then
    logError "ERROR!  Unexpected enic version found. Found: $VERSION, Expected: $ENIC_GOLDEN_VERSION"
else
    logInfo "Expected enic version $VERSION found."
fi

VERSION=$(uname -r)

if [ $VERSION != $KERNEL_GOLDEN_VERSION ]; then
    logError "ERROR! Unexpected kernel version found.  Found: $VERSION, Expected: $KERNEL_GOLDEN_VERSION"
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
            print $1, " mounted by uuid"
        }
    }
    else 
    {
        print "ERROR! Disk ", $1, "not mounted by uuid."
    }
}
' < /etc/fstab)
echo "$OUTPUT"
let FAILURECNT=FAILURECNT+$(echo "$OUTPUT" | grep "ERROR!" | wc -l)

echo -----------------------------------
if [ $FAILURECNT -gt 0 ]; then
    echo Found $FAILURECNT errors.
else
    echo SUCCESS! 
fi
echo -----------------------------------


