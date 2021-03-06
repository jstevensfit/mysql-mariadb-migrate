#!/bin/bash
# Simple script to migrates mysql databases
# from one server to another on the fly.
# Author: everythingbash.com
# Email: info@everythingbash.com
#
#   Copyright [2012] [everythingbash.com]
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
   
SOURCE_SERVER=
SOURCE_PORT=
SOURCE_USER=
SOURCE_PASSWORD=
DESTINATION_SERVER=
DESTINATION_PORT=
DESTINATION_USER=
DESTINATION_PASSWORD=
ALLDATABASES=
OVERWRITE=
TABLE_EXIST_ERROR='ERROR 1050'

usage()
{

cat << EOF
Usage: $0 -h <server> -P <port> -u <user> 

Migrates 1 or more mysql databases.

OPTIONS:
  -h     Source Server Hostname or IP
  -P     Source Server Port
  -u     Source Server User
EOF

}

while getopts "h:P:u:" opt
do
   case $opt in
     h)
        SOURCE_SERVER=$OPTARG
        ;;
     P)
        SOURCE_PORT=$OPTARG
        ;;
     u)
        SOURCE_USER=$OPTARG
        ;;
     ?)
        usage
        exit
        ;;
     esac
done


remotehost()
{

read -p "Destination Server Hostname or IP: " DESTINATION_SERVER
read -p "Destination Server Port: " DESTINATION_PORT
read -p "Destination Server User: " DESTINATION_USER
read -s -p "Destination Server Password: " DESTINATION_PASSWORD
echo ""
read -p "Overwrite Databases With The Same Name [Y/N]: " OVERWRITE
echo ""

}

migratedbs()
{

 if [[ -z $DESTINATION_SERVER ]] || [[ -z $DESTINATION_PORT  ]] || [[ -z $DESTINATION_USER  ]]
 then
        echo "ERROR: Missing Destination server, port or user."
        exit
 fi
 
 if [[ $OVERWRITE == "Y" ]] || [[ $OVERWRITE == "y" ]]
 then
	echo "*Overwriting Existing Databases*"
 	RESULT=$(mysqldump -u $SOURCE_USER -p$SOURCE_PASSWORD -h $SOURCE_SERVER -P $SOURCE_PORT --databases $ALLDATABASES 2>&1 \
	 | mysql -u $DESTINATION_USER -p$DESTINATION_PASSWORD -h $DESTINATION_SERVER -P $DESTINATION_PORT 2>&1)
 else
	echo "*Not Overwriting Existing Databases*"
 	RESULT=$(mysqldump -u $SOURCE_USER -p$SOURCE_PASSWORD -h $SOURCE_SERVER -P $SOURCE_PORT --skip-add-drop-table --databases $ALLDATABASES 2>&1 \
         | mysql -u $DESTINATION_USER -p$DESTINATION_PASSWORD -h $DESTINATION_SERVER -P $DESTINATION_PORT 2>&1)
 fi

 if [[ -z $RESULT ]] || [[ "$RESULT" == *$TABLE_EXIST_ERROR* ]] 
 then
        echo ""
        echo "Databases Migrated Successfully."
	echo ""
	echo "Remote Database Server Databases:"
	mysql -u $DESTINATION_USER -p$DESTINATION_PASSWORD -h $DESTINATION_SERVER -P $DESTINATION_PORT  <<< "show databases;"
 else
        echo $RESULT
 fi

}


if [[ -z $SOURCE_SERVER ]] || [[ -z $SOURCE_PORT  ]] || [[ -z $SOURCE_USER  ]] 
then
	echo ""
	usage
else
	read -s -p "Source Server Password: " SOURCE_PASSWORD
	echo -e "\n"
	echo "Migration Type"
	echo "1: All Databases"
	echo "2: Specify Databases"
	echo "3: List Available Databases"
	read -p "Selection: " SELECTION
        echo ""

	if [ $SELECTION == "1" ]
	then
		ALLDATABASES=$(mysql -u $SOURCE_USER -p$SOURCE_PASSWORD -h $SOURCE_SERVER -P $SOURCE_PORT  <<< "show databases;" 2>&1 | grep -v -e "Database" -e "mysql" -e "information_schema" -e "performance_schema")
		echo "Databases to be migrated:"
		echo $ALLDATABASES
		echo ""

		if [[ "$ALLDATABASES" == *ERROR* ]]
		then
			exit 
		fi

		remotehost
		
		migratedbs		

	elif [ $SELECTION == "2" ]
	then
		read -p "Specify Databases (Seperated by spaces): " ALLDATABASES
		echo ""
                echo "Databases to be migrated:"
                echo $ALLDATABASES
                echo ""

                remotehost

		migratedbs

	elif [ $SELECTION == "3" ]
	then
		mysql -u $SOURCE_USER -p$SOURCE_PASSWORD -h $SOURCE_SERVER -P $SOURCE_PORT <<< "show databases;" 
	else
		echo "Your Selection is not valid"
	fi
fi