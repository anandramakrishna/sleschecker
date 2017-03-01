#!/bin/bash
######################
# Author : Maheshkumar Rangasamy
# Date : 05/01/2017
#
# Purpose: Perform post validation on server
# Modified :
# Date : 14/01/2017 By : Maheshkumar
#########################
red=`tput setaf 1`
norm=`tput sgr0`
echo -e -n "Do you want to run validation script - type ${red}yes/y${norm} : "
read DIR
if [ $DIR == "yes" ] || [ $DIR == "y" ]
then
###
echo -e -n "please enter your location - type ${red}East/West${norm} : "
read LOCATION
DATE=`/bin/date +"%Z"`
 case $LOCATION in
  West)
   if [ $DATE = "PST" ]
   then
   echo -e "\nyou have set correct TimeZone (west) $DATE"
   else
   echo -e "${red} \nyou have not set correct Timezone, please correct${norm}\n"
   exit
   fi
   ;;
  west)
   if [ $DATE = "PST" ]
   then
   echo -e "\nyou have set correct TimeZone (west) $DATE"
   else
   echo -e "${red} \nyou have not set correct Timezone, please correct${norm}\n"
   exit
   fi
   ;;
  East)
   if [ $DATE = "EST" ]
   then
   echo -e "\nyou have set correct TimeZone (west) $DATE"
   else
   echo -e "${red} \nyou have not set correct Timezone, please correct${norm}\n"
   exit
   fi
   ;;
  east)
   if [ $DATE = "EST" ]
   then
   echo -e "\nyou have set correct TimeZone (west) $DATE"
   else
   echo -e "${red} \nyou have not set correct Timezone, please correct${norm}\n"
   exit
   fi
   ;;
  *)
   echo -e "${red} \nPlease type correct location\n"
   exit
   ;;
 esac
##Interface speed chck
SPEED=`ethtool eth0 | grep -i Speed`
SPEED1=`ethtool eth1 | grep -i Speed`
echo -e "\nSpeed of ETH0 is : $SPEED"
echo -e "Speed of ETH1 is : $SPEED1\n"
##asset tag
BOARD=`cat /sys/class/dmi/id/board_asset_tag`
CHASSIS=`cat /sys/class/dmi/id/chassis_asset_tag`
echo -e "Board asset tag is : $BOARD"
echo -e "Chassis asset tag is : $CHASSIS"
## enic driver version
ENIC=`modinfo enic | grep -i version: | grep -v src`
FNIC=`modinfo fnic | grep -i version: | grep -v src`
echo -e "\nEnic $ENIC"
echo -e "Fnic $FNIC"
##/etc/hosts file
HOSTS=`cat /etc/hosts | grep -i 10.2`
echo -e "\nHosts file output : $HOSTS"
##SSH checks in firewall
SSH=`cat /etc/sysconfig/SuSEfirewall2 | grep sshd | grep EXT`
 if [ $? -eq 0 ]
 then
 echo -e "\nSSH is allowed in firewall : $SSH"
 else
 echo -e "\nPlease check SSH in firewall"
 exit
 fi
##ping test with 9000 packaget
echo -e -n "\nPlease provide NFS gateway to ping with 9000 packet : "
read PING
ping $PING -s 9000 -c 3 | head -4
##user checks
echo -e -n "${red}Provide username : ${norm}"
read USER
ID=`id $USER`
 if [ $? -eq 0 ]
 then
 echo -e -n "user available : $ID"
 else
 echo -e -n "\nuser not availabe"
 exit
 fi
##FS permission check
echo ""
echo -e -n "\nPlease provide SID to check permission and write file : "
read SID
 df -Th | grep -i nfs
 if [ $? -eq 0 ]
 then
 echo -e -n "\n${red}NFS is mounted${norm}"
 else
 echo -e -n "\n${red}NFS is not mounted${norm}"
 echo ""
 exit
 fi
 DATA=`ls -ld /hana/data/$SID/mnt00001 | grep -i drw`
 LOG=`ls -ld /hana/log/$SID/mnt00001 | grep -i drw`
 SHARED=`ls -ld /hana/shared/$SID | grep -i drw`
 USR_SAP=`ls -ld /usr/sap/$SID | grep -i drw`
 echo -e "\nData FS permission : $DATA"
 echo -e "LOG FS permission : $LOG"
 echo -e "Shared FS permission : $SHARED"
 echo -e "Usr_sap FS permission : $USR_SAP"
##Write file on 
echo -e "\nSystem is writing 10G file on /hana/data/$SID/mnt00001/test, please be patient"
dd if=/dev/zero of=/hana/data/$SID/mnt00001/test bs=1G count=10
##Write file on 
echo -e "System is writing 10G file on /hana/log/$SID/mnt00001/test, please be patient"
dd if=/dev/zero of=/hana/log/$SID/mnt00001/test bs=1G count=10
##Write file on 
echo -e "System is writing 10G file on /hana/shared/$SID/mnt00001/test, please be patient"
dd if=/dev/zero of=/hana/shared/$SID/test bs=1G count=10
##Write file on 
echo -e "System is writing 10G file on /usr/sap/$SID/mnt00001/test, please be patient"
dd if=/dev/zero of=/usr/sap/$SID/test bs=1G count=10
echo -e "\nTest file size"
du -sch /hana/data/$SID/mnt00001/test
du -sch /hana/log/$SID/mnt00001/test
du -sch /hana/shared/$SID/test
du -sch /usr/sap/$SID/test
##Remobe file test
echo -e "\nRemoving /hana/data/$SID/mnt00001/test file"
rm -r /hana/data/$SID/mnt00001/test
echo -e "Removing /hana/log/$SID/mnt00001/test file"
rm -r /hana/log/$SID/mnt00001/test
echo -e "Removing /hana/shared/$SID/test file"
rm -r /hana/shared/$SID/test
echo -e "Removing /usr/sap/$SID/test file"
rm -r /usr/sap/$SID/test
fi
exit
