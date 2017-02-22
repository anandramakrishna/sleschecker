#!/bin/bash

FNIC_GOLDEN_VERSION="1.6.0.27"
ENIC_GOLDEN_VERSION="2.3.0.30"
KERNEL_GOLDEN_VERSION="3.12.49-11-default"

VERSION=$(sudo modinfo fnic | grep -G "^version:" | awk -F:       '{print $2}')

if [ $VERSION != $FNIC_GOLDEN_VERSION ]; then
    echo ERROR!  Unexpected fnic version found. Found: $VERSION, Expected: $FNIC_GOLDEN_VERSION
else
    echo Expected fnic version $VERSION found.
fi

VERSION=$(sudo modinfo enic | grep -G "^version:" | awk -F:       '{print $2}')

if [ $VERSION != $ENIC_GOLDEN_VERSION ]; then
    echo ERROR!  Unexpected enic version found. Found: $VERSION, Expected: $ENIC_GOLDEN_VERSION
else
    echo Expected enic version $VERSION found.
fi

VERSION=$(uname -r)

if [ $VERSION != $KERNEL_GOLDEN_VERSION ]; then
    echo ERROR! Unexpected kernel version found.  Found: $VERSION, Expected: $KERNEL_GOLDEN_VERSION
else
    echo Expected kernel $VERSION found.
fi


