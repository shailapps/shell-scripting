#!/bin/bash

curl -s "https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh" >/tmp/common-functions.sh
#source /root/scripts/common-functions.sh
source /tmp/common-functions.sh

option=$1
if [ -z "$option" ]; then 

echo -n -e "
1) Apache Web Server
2) Apache Tomcat
3) MariaDB
4) Application Stack (WEB + APP + DB)
5) Gitlab
6) Maven
7) Jenkins
8) Ansible Tower
9) Docker
10) Kuburnetes Master 
11) Kuburnetes Node
12) Kubectl
13) Zabbix Server
14) Chef Server
15) Docker-Compose
${R}E) Exit ${N}

Select an Option > "
read option
fi
#option=11
C=$(echo $option | cut -c 1)
[ "$C" -eq 1 ] &>/dev/null
STAT=$?
if [ $STAT -eq 2 ]; then 
	if [ "$option" = E ]; then 
		exit
	else
		error "Invalid Option. Try Again " 
		exit 1
	fi
else
	if [ $option -lt 1 -o $option -gt 15 ]; then 
	  error "Invalid Option. Try Again " 
	  exit 1
	fi
fi


cd /tmp
#git clone https://github.com/linuxautomations/labautomation.git
cd labautomation
if [ -f playbooks/${option}.yml ]; then 
	ansible-playbook playbooks/${option}.yml
fi

if [ -f playbooks/${option}.sh ]; then 
	sh playbooks/${option}.sh
fi 

if [ -f playbooks/${option}.py ]; then 
	[ ! -f /bin/pip ] &&  yum install python2-pip -y &>/dev/null && pip install --upgrade pip &>/dev/null
	pip install termcolor MySQL-python nltk urllib &>/dev/null
	python playbooks/${option}.py 
else
	echo "Sorry this in not completed"
	exit 1
fi

## One more line
##
