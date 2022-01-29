#!/bin/bash

## Variables
COMPONENT=$1
LOG_FILE=/tmp/roboshop.log
rm -f $LOG_FILE

## Functions
HEAD() {
  echo -e "\t\t\e[1;4;33mSetting Up $COMPONENT\e[0m"
}

Stat_Check() {
    case $1 in
      0)
        echo -e "\e[1;32mSUCCESS\e[0m"
        ;;
      *)
        echo -e "\e[1;31mFAILURE\e[0m"
        echo "Refer Log file : $LOG_FILE for more information"
        exit 1
        ;;
    esac
}

Print() {
  echo -e -n "\t$1\t\t- "
}

App_User() {
    Print "Create App User\t\t"
    useradd roboshop &>>$LOG_FILE
    STAT=$?
    case $STAT in
      # Either the exit status is 0 or 9 it executes commands
      0|9)
        Stat_Check 0
        ;;
      *)
        Stat_Check $STAT
        ;;
    esac
}

InstallGit()
{
  sudo yum install git
  git version
}

Service_Setup() {
    Print "Setup $COMPONENT SystemD Service"
    mv /home/roboshop/$COMPONENT/systemd.service /etc/systemd/system/$COMPONENT.service &>>$LOG_FILE
    sed -i -e "s/MONGO_DNSNAME/mongodb-test.devopsb52.tk/" -e "s/REDIS_ENDPOINT/redis-test.devopsb52.tk/" -e "s/MONGO_ENDPOINT/mongodb-test.devopsb52.tk/" -e "s/CATALOGUE_ENDPOINT/catalogue-test.devopsb52.tk/" -e "s/CARTENDPOINT/cart-test.devopsb52.tk/" -e "s/DBHOST/mysql-test.devopsb52.tk/" -e "s/CARTHOST/cart-test.devopsb52.tk/" -e "s/USERHOST/user-test.devopsb52.tk/" -e "s/AMQPHOST/rabbitmq-test.devopsb52.tk/" /etc/systemd/system/$COMPONENT.service
    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable $COMPONENT  &>>$LOG_FILE
    systemctl restart $COMPONENT  &>>$LOG_FILE
    Stat_Check $?
}

NodeJS() {
    Print "Install NodeJS\t\t"
    yum install nodejs make gcc-c++ -y &>>$LOG_FILE
    Stat_Check $?

    App_User

    Print "Downloading $COMPONENT\t"
    curl -s -L -o /tmp/$COMPONENT.zip "$1" &>>$LOG_FILE
    Stat_Check $?

    Print "Extracting $COMPONENT\t\t"
    cd /home/roboshop
    mkdir -p $COMPONENT
    cd $COMPONENT
    unzip -o /tmp/$COMPONENT.zip &>>$LOG_FILE
    Stat_Check $?

    Print "Install NodeJS Dependencies"
    npm install --unsafe-perm &>>$LOG_FILE
    Stat_Check $?
    chown roboshop:roboshop  /home/roboshop -R

    Service_Setup
}

## Main Program

## THis verifies the script is run as root or not.
uid=$(id -u)
if [ $uid -ne 0 ]; then
  echo -e "\e[1;31mYou should be a sudo / root user to execute this script\e[0m"
  exit 2
fi

#case $uid in
#  0)
#    true
#    ;;
#  *)
#    echo -e "\e[1;31mYou should be a sudo / root user to execute this script\e[0m"
#    exit 2
#    ;;
#esac


HEAD
hostnamectl set-hostname $1
disable-auto-shutdown

case $COMPONENT in
  frontend)

    Print "Installing Nginx\t"
    yum install nginx -y &>>$LOG_FILE
    Stat_Check $?

    Print "Download Frontend\t"
    curl -s -L -o /tmp/frontend.zip "https://dev.azure.com/DevOps-Batches/f4b641c1-99db-46d1-8110-5c6c24ce2fb9/_apis/git/repositories/a781da9c-8fca-4605-8928-53c962282b74/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true" &>>$LOG_FILE
    Stat_Check $?

    Print "Cleanup Old Docs\t"
    cd /usr/share/nginx/html
    rm -rf *
    Stat_Check $?

    Print "Extracting Frontend\t"
    unzip /tmp/frontend.zip &>>$LOG_FILE
    Stat_Check $?

    mv static/* .
    rm -rf static README.md

    Print "Update Nginx Configuration"
    mv shell-script.conf /etc/nginx/default.d/roboshop.conf
    Stat_Check $?

    Print "Start Nginx Service\t"
    systemctl enable nginx &>>$LOG_FILE
    systemctl restart nginx &>>$LOG_FILE
    Stat_Check $?

    ;;
  
InstallGit)

    Print "Installation of git \t\t"
    InstallGit
  Stat_Check $?
    ;;

  mongodb)

    Print "Setup Yum repos\t\t"
    echo '[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc' >/etc/yum.repos.d/mongodb.repo
  Stat_Check $?

  Print "Install MongoDB\t\t"
  yum install -y mongodb-org  &>>$LOG_FILE
  Stat_Check $?

  Print "Update MongoDB Configuration"
  if [ -f  /etc/mongod.conf ]; then
    sed -i -e "s/127.0.0.1/0.0.0.0/" /etc/mongod.conf
  else
    echo "MongoDB Configuration file does not exist"
    false
  fi
  Stat_Check $?

  Print "Start MongoDB Service\t"
  systemctl enable mongod  &>>$LOG_FILE
  systemctl restart mongod &>>$LOG_FILE
  Stat_Check $?

  Print "Download MongoDB\t"
  curl -s -L -o /tmp/mongodb.zip "https://dev.azure.com/DevOps-Batches/ce99914a-0f7d-4c46-9ccc-e4d025115ea9/_apis/git/repositories/e9218aed-a297-4945-9ddc-94156bd81427/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true" &>>$LOG_FILE
  Stat_Check $?

  Print "Extracting MongoDB\t"
  cd /tmp
  unzip -o mongodb.zip &>>$LOG_FILE
  Stat_Check $?

  Print "Load Catalogue App Schema"
  mongo < catalogue.js &>>$LOG_FILE
  Stat_Check $?

  Print "Load User App Schema\t"
  mongo < users.js &>>$LOG_FILE
  Stat_Check $?

  ;;
  catalogue)
    NodeJS "https://dev.azure.com/DevOps-Batches/f4b641c1-99db-46d1-8110-5c6c24ce2fb9/_apis/git/repositories/1a7bd015-d982-487f-9904-1aa01c825db4/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true"
    ;;
  user)
    NodeJS "https://dev.azure.com/DevOps-Batches/f4b641c1-99db-46d1-8110-5c6c24ce2fb9/_apis/git/repositories/360c1f78-e8ed-41e8-8b3d-bdd12dc8a6a1/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true"
    ;;
  cart)
    NodeJS "https://dev.azure.com/DevOps-Batches/f4b641c1-99db-46d1-8110-5c6c24ce2fb9/_apis/git/repositories/d1ba7cbf-6c60-4403-865d-8a522a76cd76/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true"
    ;;
  shipping)
    Print "Installing Maven\t"
    yum install maven -y &>>$LOG_FILE
    Stat_Check $?

    App_User

    Print "Download Shipping\t"
    curl -s -L -o /tmp/shipping.zip "https://dev.azure.com/DevOps-Batches/f4b641c1-99db-46d1-8110-5c6c24ce2fb9/_apis/git/repositories/1ebc164b-f649-49b5-807d-2e55dc14628e/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true"
    Stat_Check $?

    Print "Extracting Shipping\t"
    cd /home/roboshop
    mkdir -p shipping
    cd shipping
    unzip -o /tmp/shipping.zip &>>$LOG_FILE
    Stat_Check $?

    Print "Compile Package\t\t"
    mvn clean package  &>>$LOG_FILE
    mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
    Stat_Check $?

    Service_Setup
    ;;
  mysql)

    Print "Setup repository\t"
    echo '[mysql57-community]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/$basearch/
enabled=1
gpgcheck=0' > /etc/yum.repos.d/mysql.repo
    Stat_Check $?

    Print "Install MySQL\t\t"
    yum remove mariadb-libs -y &>>$LOG_FILE
    yum install mysql-community-server -y &>>$LOG_FILE
    Stat_Check $?

    Print "Start MySQL\t\t"
    systemctl enable mysqld &>>$LOG_FILE
    systemctl start mysqld &>>$LOG_FILE
    Stat_Check $?

    echo "show databases;" | mysql -uroot -ppassword &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        sleep 30
        MYSQL_DEFAULT_PASSWORD=$(grep 'A temporary password' /var/log/mysqld.log | awk '{print $NF}')
        echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyPassw0Rd@1';
uninstall plugin validate_password;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';" >/tmp/reset.sql

        Print "Reset Password\t"
        mysql --connect-expired-password -uroot -p$MYSQL_DEFAULT_PASSWORD </tmp/reset.sql  &>>$LOG_FILE
        Stat_Check $?
    fi

    Print "Download Schema\t\t"
    curl -s -L -o /tmp/mysql.zip "https://dev.azure.com/DevOps-Batches/f4b641c1-99db-46d1-8110-5c6c24ce2fb9/_apis/git/repositories/2a75b631-2da9-4ced-810e-8b3a8761729d/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true" &>>$LOG_FILE
    Stat_Check $?

    Print "Load Schema\t\t"
    cd /tmp
    unzip -o mysql.zip &>>$LOG_FILE
    mysql -u root -ppassword <shipping.sql &>>$LOG_FILE
    Stat_Check $?
    ;;

  redis)
    Print "Installing Redis\t"
    yum install epel-release yum-utils http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y &>>$LOG_FILE
    yum-config-manager --enable remi &>>$LOG_FILE
    yum install redis -y &>>$LOG_FILE
    Stat_Check $?

    Print "Update Configs"
    sed -i -e "s/127.0.0.1/0.0.0.0/" /etc/redis.conf &>>$LOG_FILE
    Stat_Check $?

    Print "Start Redis"
    systemctl enable redis  &>>$LOG_FILE
    systemctl start redis  &>>$LOG_FILE
    Stat_Check $?
    ;;

  terraform)
    Print "Update apt-get package manager\t"
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl  &>>$LOG_FILE
    Stat_Check $?

    Print "Install official hashicorp repository"
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -  &>>$LOG_FILE
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"  &>>$LOG_FILE

    Stat_Check $?

    Print "Install terraform"
    sudo apt-get update && sudo apt-get install terraform  &>>$LOG_FILE
    terrafrom -v  &>>$LOG_FILE
    Stat_Check $?
    ;;

  rabbitmq)

    Print "Install RabbitMQ\t"
    yum install https://packages.erlang-solutions.com/erlang/rpm/centos/7/x86_64/esl-erlang_22.2.1-1~centos~7_amd64.rpm -y  &>>$LOG_FILE
    curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | sudo bash  &>>$LOG_FILE
    yum install rabbitmq-server -y  &>>$LOG_FILE
    Stat_Check $?

    Print "Start RabbitMQ Service"
    systemctl enable rabbitmq-server &>>$LOG_FILE
    systemctl start rabbitmq-server  &>>$LOG_FILE
    Stat_Check $?

    Print "Create Application User"
    rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
    rabbitmqctl set_user_tags roboshop administrator &>>$LOG_FILE
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
    Stat_Check $?
    ;;
  payment)

    Print "Install Python\t\t"
    yum install python36 gcc python3-devel -y &>>$LOG_FILE
    Stat_Check $?

    App_User

    Print "Download Payment\t"
    curl -L -s -o /tmp/payment.zip "https://dev.azure.com/DevOps-Batches/f4b641c1-99db-46d1-8110-5c6c24ce2fb9/_apis/git/repositories/64e9a902-e729-44ad-a562-8f605ae9617e/items?path=%2F&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true" &>>$LOG_FILE
    Stat_Check $?

    Print "Extract Payment\t\t"
    cd /home/roboshop
    mkdir -p payment
    cd payment
    unzip -o /tmp/payment.zip &>>$LOG_FILE
    Stat_Check $?

    Print "Install Python Dependencies"
    cd /home/roboshop/payment
    pip3 install -r requirements.txt &>>$LOG_FILE
    Stat_Check $?

    Service_Setup
    ;;
  *)
    echo -e "\t \e[31mInvalid Input - $COMPONENT\e[0m"
    echo "Usage: $0 frontend|catalogue|cart|mongodb"
    exit 1
    ;;
esac

## Name of functions and variables are created based on different people background
## All in CAPS
## CamelCase
## All in lower characters
## _prefix to the values


# STATUS_CHECK
# statusCheck
# _status_check
