#!/bin/bash

# Vars
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"
orangeColour="\033[38;5;214m"
bold="\033[1m"
normal="\033[0m"

currentUser=$USER

# Hidde cursor
trap ctrl_c INT
tput civis

# Control ctrl_c 
function ctrl_c(){
	log "Info" "Exit..."
	tput cnorm
	exit 0
}

# Functions
function log(){

    if [ $1 == "Title" ];
    then
        clear
        echo -e "\n${greenColour}[*] $2 [*]${endColour} \n "
        sleep 3
    fi

    if [ $1 == "Info" ];
    then
        echo -e "${yellowColour}[*]${endColour} $2"
        sleep 1
    fi

    if [ $1 == "Error" ];
    then
        echo -e "${redColour}[!]${endColour} $2"
        sleep 1
    fi

}

function InstallPrerequisites(){

    log "Title" "Install $1"
    sudo apt install $1 -y
}

function configDocker(){

    if [[ $1 -eq "group" ]];
    then
        log "Info" "Add $USER to docker group"
        sudo usermod -aG docker $currentUser
    fi

    if [[ $1 -eq "service" ]];
    then
        log "Info" "Restart Docker service"
        sudo systemctl restart docker
    fi
}

function getInstalled(){
   
    which $1 2>&1> /dev/null ; echo $?
}

function prerequisites(){

    log "Title" "Checking prerequisites"

    InstalledPrerequisites=("docker" "docker-compose" "ansible" "nodejs" "npm" "pip" "git" "pwgen" "unzip" "wget")
    for i in "${InstalledPrerequisites[@]}"
    do
        [ $(getInstalled $i) -ne 0 ] && InstallPrerequisites $i
    done

    dockerGroup=$(groups $currentUser | grep "docker" 2>&1> /dev/null ; echo $?)
    dockerService=$(systemctl status docker | grep "Active: active" 2>&1> /dev/null ; echo $?)
    [ $dockerGroup -ne 0 ] && configDocker "group"
    [ $dockerService -ne 0 ] && configDocker "service"
}

function installAnsibleAWX(){

    log "Title" "Install Ansible AWX"
    log "Info" "Download..."
    wget https://github.com/ansible/awx/archive/17.1.0.zip

    log "Info" "Uncompress..."
    unzip 17.1.0.zip
    rm -rf 17.1.0.zip

    log "Info" "Add key..."
    key=$(pwgen -N 1 -s 30)
    echo -e "\nsecret_key=$key" >> inventory
    echo "pg_admin_password=$key" >> inventory

    log "Title" "INSTALATION AWX"
    sudo ansible-playbook -i inventory awx-17.1.0/installer/install.yml
}

function getAccess(){

    log "Title" "!! All done. check ./AccessFile !!"
    echo " --- Access AWX Dashboard ---
- URL: http://$(hostname -I | cut -d ' ' -f1)/login
- USER: admin
- PASS: admin
*** RECOMENDATE CHANGE YOUR PASSWORD http://$(hostname -I | cut -d ' ' -f1)/#/users/1/edit ***" > AccessFile
}

# WorkFlow
prerequisites;
installAnsibleAWX;
getAccess;