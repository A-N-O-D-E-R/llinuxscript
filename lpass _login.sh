#!/bin/bash
function check_install {
    if [ ! -x "$(command -v lpass)" ]; then
     tput setaf 5; echo "lpass n'est pas installé"
     tput setaf 6; read -p "Souhaitez vous installer lastpass ? (y/n)  " install_lpass
     if [ $install_lpass = "y" ]
     then
        tput setaf 6; echo "Création des utilisateurs et changement des mots de passe.................................. En cours"
        apt install lastpass-cli
        tput setaf 7; echo "Création des utilisateurs et changement des mots de passe.................................. OK"
    else
        exit 1
    fi
    if [ ! -x "$(command -v tomb)" ]; then
        tput setaf 5; echo "tomb n'est pas installé"
        tput setaf 5; echo "tomb est un logicielle pour sécurisé vos mots de passe en local, utile si vous ne voulez pas tapez votre mots de passe"
        tput setaf 6; read -p "Souhaitez vous installer tomb ? (y/n)  " install_tomb
        if [ $install_tomb = "y" ]
        then
            tput setaf 6; echo "Création des utilisateurs et changement des mots de passe.................................. En cours"
            apt-get install tomb
            tput setaf 7; echo "Création des utilisateurs et changement des mots de passe.................................. OK"
        fi
    fi 
   fi 
  
}

function login_without_tomb {
    if [ $1 -eq 0 ]; then
        tput setaf 6; read -r -s -p  " Unable to find your password please enter your password  "  password
        echo password | LPASS_DISABLE_PINENTRY=1 lpass login $USER@$domain
    else
        echo $1 | LPASS_DISABLE_PINENTRY=1 lpass login $USER@$domain
    fi
}


function login_with_tomb {
    if [[ -f /media/lpass/.password ]] ; then
        cat /media/lpass/.password | LPASS_DISABLE_PINENTRY=1 lpass login $USER@$domain        
    else
        tput setaf 5; echo "tomb n'est pas ouverte, ouvrez votre tomb !"
    fi
}


function get{
    TMPFILE=`mktemp -t example.XXXXXXXXXX.ovpn` && TMPCRD=`mktemp -t example.XXXXXXXXXX.crd` && {
        lpass show -j $1 |jq .[0].note  | cut -c 2- | rev | cut -c 2- | rev | awk '{gsub(/\\r/,"\n")}1' | awk '{gsub(/\\"/,"\"")}1' > $TMPFILE ;
        lpass show $1 -j |jq .[0].username | awk '{gsub(/\"/,"")}1' > $TMPCRD ;
        lpass show $1 -j |jq .[0].password | awk '{gsub(/\"/,"")}1' >> $TMPCRD ;
        rm -f $TMPFILE ;
        rm -f $TMPCRD ;
    }
}

check_install
if [ -x "$(command -v tomb)" ]; then
    login_with_tomb
else
    login_without_tomb
fi
