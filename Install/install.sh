#!/bin/bash
####################################################
#                                                  #
# Configuration automatique de Debian par ANODER  #
#                                                  #
####################################################


function Verif-System {
  user=$(whoami)
  if [ $(whoami) != "root" ]
    then
    tput setaf 5; echo "ERREUR : Veuillez exécuter le script en tant que Root !"
    exit
  fi
  if [[ $(arch) != *"64" ]]
    then
    tput setaf 5; echo "ERREUR : Veuillez installer une version x64 !"
    exit
  fi
}

function Change-Source {
    ostype=$(. /etc/os-release; echo "$ID_LIKE")
    osname=$(. /etc/os-release; echo "$ID")
    oscodename=$(. /etc/os-release; echo "$VERSION_CODENAME")
    version=$(grep "VERSION=" /etc/os-release |awk -F= {' print $2'}|sed s/\"//g |sed s/[0-9]//g | sed s/\)$//g |sed s/\(//g)
    clear
    tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
    tput bold; tput setaf 7; echo "                     => Checking OS Parameters.                    "
    tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
    if [[ $osname == "ubuntu" ]] ; then 
        echo "deb http://archive.ubuntu.com/ubuntu/ ${oscodename} main restricted
deb http://archive.ubuntu.com/ubuntu/ ${oscodename}-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ ${oscodename} universe
deb http://archive.ubuntu.com/ubuntu/ ${oscodename}-updates universe
deb http://archive.ubuntu.com/ubuntu/ ${oscodename} multiverse
deb http://archive.ubuntu.com/ubuntu/ ${oscodename}-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ ${oscodename}-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ ${oscodename}-security main restricted
deb http://security.ubuntu.com/ubuntu/ ${oscodename}-security universe
deb http://security.ubuntu.com/ubuntu/ ${oscodename}-security multiverse"> /etc/apt/sources.list
    elif [[ osname == "debian" ]] ; then
        echo "deb http://debian.mirrors.ovh.net/debian/ $version main contrib non-free
deb-src http://debian.mirrors.ovh.net/debian/ $version main contrib non-free
deb http://security.debian.org/ $version/updates main contrib non-free
deb-src http://security.debian.org/ $version/updates main contrib non-free
deb http://debian.mirrors.ovh.net/debian/ $version-updates main contrib non-free
deb-src http://debian.mirrors.ovh.net/debian/ $version-updates main contrib non-free" > /etc/apt/sources.list
        echo 'deb http://deb.debian.org/debian $version-backports main' > \
        /etc/apt/sources.list.d/backports.list
    else
        tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
        tput bold; tput setaf 7; echo "                      => the $osname Distribution is not supported                     "
        tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
    fi
}

function setupOAuth {
  echo 'SetUp OAuth'
}

function setUpBackup {
  sudo -v ; curl https://rclone.org/install.sh | sudo bash

}

function generateRSAKeys {
  ssh-keygen -b 2048 -t rsa -f /tmp/sshkey -q -N ""
}


# Mise à jours des paquets
function Install-PaquetsEssentiels {
  apt update && apt upgrade -y
  apt install -y sudo
  apt install -y chpasswd
  apt install -y locate
  apt install -y zsh
  apt install -y git
  apt install -y curl
  apt install -y jq
}œ

# Install dev-essential
function Install-DevEssential {
  task-install
  gum-Install
  nvm-install 0.39.3
  java-install "11+28"
  maven-install
  mkcert-install 
  download-ScriptUtils
}

function maven-install {
  wget https://www-us.apache.org/dist/maven/maven-3/${1}/binaries/apache-maven-${1}-bin.tar.gz -P /tmp
  sudo tar xf /tmp/apache-maven-*.tar.gz -C /opt
  sudo ln -s /opt/apache-maven-${1} /opt/maven
  export M2_HOME=/opt/maven
  export MAVEN_HOME=/opt/maven
  export PATH=${M2_HOME}/bin:${PATH}
}

function gum-install {
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    apt update && apt install gum
}

function task-install {
    sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d
}

function download-ScriptUtils {
  #TODO : download Utils script in /opt
  mkdir -p /opt/script
  wget -qO- https://raw.githubusercontent.com/A-N-O-D-E-R/llinuxscript/main//utility/change_java_version > /opt/script/change_java_version
  wget -qO- https://raw.githubusercontent.com/A-N-O-D-E-R/llinuxscript/main//utility/compress.sh > /opt/script/compress.sh
}

function nvm-install {
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${1}/install.sh | bash
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

function java-install {
  filename="openjdk-${1}_linux-x64_bin.tar.gz"
  major=$(echo ${1} |  awk -F '+' '{print $1}')
  wget "https://download.java.net/openjdk/jdk${major}/ri/${filename}" -P /tmp
  wget "https://download.java.net/openjdk/jdk${major}/ri/${filename}.sha256" -P /tmp
  printf '%s %s\n' "$(cat /tmp/${filename}.sha256)" "${filename}" | sha256sum --check
  sudo tar xf /tmp/$filename -C /opt
  sudo ln -s /opt/$filename /opt/jdk-${1}
  sudo ln -s /opt/jdk-${1} /opt/java
  export JAVA_HOME=/opt/java
  export PATH=${JAVA_HOME}/bin/java:${PATH}
}



function Create_alias {
    if [[ -z ~/.bash_aliases ]] ; then 
        echo "alias okta='${HOME}/bin/okta'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m \"--wip-- [skip ci]\"'
alias gunwip='git log -n 1 | grep -q -c \"\-\-wip\-\-\" && git reset HEAD~1'
alias gsts='git stash -- $(git diff --staged --name-only)'
alias gpsh='git push origin HEAD'
alias gpshf='git push -f origin HEAD'
" > ~/.bash_aliases
    fi
}

# Installation des dépendances et de docker
function Install-Docker {
  tput setaf 2; apt-get install -y apt-transport-https ca-certificates gnupg2 software-properties-common
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
  apt-get update
  apt-get -y install docker-ce docker-compose
  systemctl enable docker
  systemctl start docker
}

function Install-Zsh {
  tput setaf 2; chsh -s $(which zsh)

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh)" -s --batch || {
    echo "Could not install Oh My Zsh" >/dev/stderr
    exit 1
  }

  locale-gen --purge fr_FR.UTF-8
  echo -e 'LANG="fr_FR.UTF-8"\nLANGUAGE="fr_FR.UTF-8"\n' > /etc/default/locale


  # Modification de zsh
  for file in ~/.zshrc
  do
    echo "Traitement de $file ..."
    sed -i -e "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=agnoster/g" "$file"
  done
}

function UpdateDb {
  echo updatedb
}

function Install-TraefikPortainer {

  mkdir -p /apps/traefik
  mkdir -p /apps/portainer

  touch /apps/traefik/traefik.yml
  echo "api:
    dashboard: true
  entryPoints:
    http:
      address: \":80\"
    https:
      address: \":443\"
  providers:
    docker:
      endpoint: \"unix:///var/run/docker.sock\"
      exposedByDefault: false
  certificatesResolvers:
    http:
      acme:
        email: $email
        storage: acme.json
        httpChallenge:
          entryPoint: http
  providers.file:
      filename: \"/etc/traefik/dynamic_conf.toml\"
      watch: true
  " > /apps/traefik/traefik.yml

  touch /apps/traefik/config.yml
  echo "http:
    middlewares:
      https-redirect:
        redirectScheme:
          scheme: https
      default-headers:
        headers:
          frameDeny: true
          sslRedirect: true
          browserXssFilter: true
          contentTypeNosniff: true
          forceSTSHeader: true
          stsIncludeSubdomains: true
          stsPreload: true
      secured:
        chain:
          middlewares:
          - default-headers
    " > /apps/traefik/config.yml

    touch /apps/traefik/acme.json
    chmod 600 /apps/traefik/acme.json

    touch docker-compose.yml
    echo "version: '2'
  services:
    traefik:
      image: traefik:latest
      container_name: traefik
      restart: unless-stopped
      security_opt:
        - no-new-privileges:true
      networks:
        - proxy
      ports:
        - 80:80
        - 443:443
      volumes:
        - /etc/localtime:/etc/localtime:ro
        - /var/run/docker.sock:/var/run/docker.sock:ro
        - /apps/traefik/traefik.yml:/traefik.yml:ro
        - /apps/traefik/acme.json:/acme.json
        - /apps/traefik/config.yml:/config.yml:ro
      labels:
        - traefik.enable=true
        - traefik.http.routers.traefik.entrypoints=http
        - traefik.http.routers.traefik.rule=Host(\"traefik.$ndd\")
        - traefik.http.middlewares.traefik-auth.basicauth.users=admin:{SHA}0DPiKuNIrrVmD8IUCuw1hQxNqZc=
        - traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https
        - traefik.http.routers.traefik.middlewares=traefik-https-redirect
        - traefik.http.routers.traefik-secure.entrypoints=https
        - traefik.http.routers.traefik-secure.rule=Host(\"traefik.$ndd\")
        - traefik.http.routers.traefik-secure.middlewares=traefik-auth
        - traefik.http.routers.traefik-secure.tls=true
        - traefik.http.routers.traefik-secure.tls.certresolver=http
        - traefik.http.routers.traefik-secure.service=api@internal
    portainer:
      image: portainer/portainer-ce:latest
      container_name: portainer
      restart: unless-stopped
      security_opt:
        - no-new-privileges:true
      environment:
        TEMPLATES: https://github.com/PAPAMICA/docker-compose-collection/blob/master/templates-portainer.json
      networks:
        - proxy
      volumes:
        - /etc/localtime:/etc/localtime:ro
        - /var/run/docker.sock:/var/run/docker.sock:ro
        - /apps/portainer/data:/data
      labels:
        - traefik.enable=true
        - traefik.http.routers.portainer.entrypoints=http
        - traefik.http.routers.portainer.rule=Host(\"portainer.$ndd\")
        - traefik.http.middlewares.portainer-https-redirect.redirectscheme.scheme=https
        - traefik.http.routers.portainer.middlewares=portainer-https-redirect
        - traefik.http.routers.portainer-secure.entrypoints=https
        - traefik.http.routers.portainer-secure.rule=Host(\"portainer.$ndd\")
        - traefik.http.routers.portainer-secure.tls=true
        - traefik.http.routers.portainer-secure.tls.certresolver=http
        - traefik.http.routers.portainer-secure.service=portainer
        - traefik.http.services.portainer.loadbalancer.server.port=9000
        - traefik.docker.network=proxy
  networks:
    proxy:
      external: true
    " > docker-compose.yml

    tput setaf 2; docker network create proxy
    docker-compose up -d
}

function Configure_Lastpass {
  apt-get --no-install-recommends -yqq install   bash-completion   build-essential   cmake   libcurl4    libcurl4-openssl-dev    libssl-dev    libxml2   libxml2-dev    libssl1.1   pkg-config   ca-certificates   xclip
  apt install lastpass-cli
   if [ ! -x "$(command -v tomb)" ]; then
        tput setaf 5; echo "tomb is not install"
        tput setaf 5; echo "tomb is a software to secure your passwords locally, useful if you don't want to type your passwords"
        tput setaf 6; read -p "Do you wat to install tomb ? (y/n)  " install_tomb
        if [ $install_tomb = "y" ]
        then
            tput setaf 6; echo "Installation of tomb .................................. En cours"
            apt-get install tomb
            tomb dig -s 10 ~/lpass.tomb
            tomb forge -k lpass.tomb.key
            tomb lock  -k lpass.tomb.key lpass.tomb
            tput setaf 7; echo "Installation of tomb.................................. OK"
            tput setaf 7; echo "please check the following to understand how to use tomb : https://github.com/dyne/Tomb/blob/master/INSTALL.md#basic-usage"
            tput setaf 7; echo "To open passwords folder enter the following line : tomb open -k lpass.tomb.key lpass.tomb (will ask for password previously enter)"
        fi
    fi
}

function Change-Password {
  tput setaf 6; echo "root:$password_root" | chpasswd
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput setaf 7; echo "                                => Mot de passe de Root a été changé.                               "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput setaf 2; adduser --quiet --disabled-password --shell /bin/bash --home /home/$name_user --gecos "User" $name_user
  tput setaf 2; echo "$name_user:$password_user" | chpasswd
  tput setaf 2; adduser $name_user sudo
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput bold; tput setaf 7; echo "                         => L'utilisateur $name_user a été créé.                         "
  tput bold; tput setaf 7; echo "                         => $name_user fait parti du groupe sudo.                        "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
}

# Changing du port SSH
function Change-SSHPort {
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup

  for file in /etc/ssh/sshd_config
  do
    echo "Traitement de $file ..."
    sed -i -e "s/#Port 22/Port $ssh_port/" "$file"
  done
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput setaf 7; echo "                                 => Port SSH remplacé par $ssh_port.                                "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"

}

# Changing du motd
function Change-MOTD {
  ip_du_serveur=$(hostname -i)
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput bold; tput setaf 7; echo "                      => L'adresse IP du serveur est $ip_du_serveur.                     "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"


  echo "
  ██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗
  ██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝
  ██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗
  ██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝
  ╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗
   ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
               Server   : $name_server
               IP       : $ip_du_serveur
               Provider : $name_provider
  " > /etc/motd

}

#-----------------------------------------------------------------------------------------------------------------------------------
install_traefik = "n"
clear
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 7; echo "                                   Install srcipt for Linux                                  "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"

tput setaf 6; read -p "Do you need to install a new user (usefull for a webserver) ? (y/n)  " create_user
if [[ $create_user == "y" ]] ; then
    tput setaf 6; read -p "===>     Enter root password : " password_root
    tput setaf 6; read -p "===>     Enter user name : " name_user
    tput setaf 6; read -p "===>     Enter password for $name_user : " password_user
fi

echo ""

tput setaf 6; read -p "Have you a Okta Token ? (y/n)  " install_Okta
if [[ $install_Okta == "y" ]] ; then
    tput setaf 6; read -p "===>     Enter your Okta API token, for more information see: https://bit.ly/get-okta-api-token | Okta API token: " token_okta
fi

echo ""
tput setaf 6; read -p "o you need to install a monitoring tool ? (y/n)  " install_zabbixAgent
echo ""
tput setaf 6; read -p "It is the monitoring server host ? (y/n)  " install_zabbixServer
echo ""

tput setaf 6; read -p "Install Docker ? (y/n)  " install_docker
if [[ $install_docker == "y" ]] ; then
  echo ""
  tput setaf 6; read -p "Install Traefik & Portainer (usefull for a webserver)  ? (y/n)  " install_traefik
  if [[ $install_traefik == "y" ]] ; then
    tput setaf 6; read -p "===>     Enter Domaine name (ex : altar.bio) : " ndd
    tput setaf 6; read -p "===>     Enter mail address for Let's Encrypt : " email
    echo ""
    while [ -z $redirection ] || [ $redirection != 'y' ]
    do
      tput setaf 3; echo "WARNNING ! you need to do the following redirection:"
      tput setaf 3; echo "=> Traefik : traefik.$ndd => server's IP WAN !"
      tput setaf 3; echo "=> Portainer : portainer.$ndd =>  server's IP WAN !"
      echo ""
      tput setaf 3; read -p "Do the redirection have been correctly implement? (y/n) " redirection
    done
  fi
fi

echo ""
echo ""

tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 7; echo "                                       Start of the script                                          "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
echo ""
echo ""


tput setaf 6; echo "System verification ................................................................... En cours"
Verif-System
tput setaf 7; echo "System verification ................................................................... OK"
echo ""


tput setaf 6; echo "Sources' configuration  ................................................................. En cours"
Change-Source
tput setaf 7; echo "Sources' configuration  ................................................................. OK"
echo ""

tput setaf 6; echo "Essentiels paquets Installation........................................................ En cours"
Install-PaquetsEssentiels
tput setaf 7; echo "Essentiels paquets Installation........................................................ OK"
echo ""

tput setaf 6; echo "ZSH Installation........................................................................ En cours"
Install-Zsh
tput setaf 7; echo "ZSH Installation........................................................................ OK"
echo ""

tput setaf 6; echo "Update Database .......................................................... En cours"
UpdateDb
tput setaf 7; echo "Update Database .......................................................... OK"

echo ""
echo ""
if [[ $install_docker == "y" ]] ; then
  tput setaf 6; echo "Docker's Installation ..................................................................... En cours"
  Install-Docker
  tput setaf 7; echo "Docker's Installation..................................................................... OK"
fi

echo ""
echo ""

if [[ $install_traefik == "y" ]] ; then
  tput setaf 6; echo "Traefik & de Portainer Installation .................................................... En cours"
  Install-TraefikPortainer
  tput setaf 7; echo "Traefik & de Portainer Installation .................................................... OK"
fi
echo ""
echo ""

if [[ $install_Okta == "y" ]] ; then 
    curl https://raw.githubusercontent.com/okta/okta-cli/master/cli/src/main/scripts/install.sh | $(echo $SHELL)
    setupOkta
fi
echo ""
echo ""

if [[ $install_lastpass == "y" ]] ; then 
    tput setaf 6; echo "Configuration lastpass .................................. En cours"
    Configure_Lastpass
    tput setaf 7; echo "Configuration lastpass.................................. OK"
  fi
echo ""
echo ""

if [[ $install_zabbixAgent == "y" ]] ; then 
    tput setaf 6; echo "Configuration zabbix agent.................................. En cours"
    Configure_zabbix
    tput setaf 7; echo "Configuration zabbix agent.................................. OK"
fi
echo ""
echo ""

if [[ $install_zabbixServer == "y" ]] ; then 
    # TODO : Install zabbix server and ansible
    echo "install zabbix"
fi
echo ""
echo ""

if [[ $install_Notion == "y" ]] ; then 
   echo "install notion"
fi

echo ""
echo ""
if [[ $create_user == "y" ]] ; then
  tput setaf 6; echo "User Creation and password Update .................................. En cours"
  Change-Password
  tput setaf 7; echo "User Creation and password Update.................................. OK"
fi

echo ""
echo ""
if [[ $change_sshport == "y" ]] ; then
  tput setaf 6; echo "Changing SSH port .................................................................... En cours"
  Change-SSHPort
  tput setaf 7; echo "Changing SSH port .................................................................... OK"
fi

echo ""
echo ""
if [[ $change_motd == "y" ]] ; then
  tput setaf 6; echo "Changing MOTD....................................................................... En cours"
  Change-MOTD
  tput setaf 7; echo "Changing MOTD....................................................................... OK"
fi

echo ""
echo ""
if [[ $install_traefik == "y" ]] ; then
  echo ""
  echo ""
  tput bold; tput setaf 7; echo "LIVE CONTAINERS LIST : "
  tput setaf 3; echo ""
  docker container ls
fi
tput setaf 6; echo "Creating Alias....................................................................... En cours"
Create_alias
tput setaf 7; echo "Creating Alias....................................................................... OK"



echo ""
echo ""
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput bold; tput setaf 7; echo "                               => CONFIGURATION FINISH <=                                "
tput setaf 7; echo ""
if [[ $install_traefik == "y" ]] ; then
  tput bold; tput setaf 7; echo "                               Portainer.$ndd                                            "
  tput bold; tput setaf 7; echo "                               Traefik.$ndd                                            "
  tput bold; tput setaf 7; echo "                           Traefik Identifiant: admin / admin                          "
  tput setaf 7; echo ""
fi
tput bold; tput setaf 7; echo "                                RECONNECTION NEEDED                                "
if [[ $change_sshport == "y" ]] ; then
  tput bold; tput setaf 7; echo "                             Votre nouveau port SSH : $ssh_port                        "
fi
tput setaf 7; echo ""
tput bold; tput setaf 6; echo "                                       By Altar                                      "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 2; echo ""

sleep 5
