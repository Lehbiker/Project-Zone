#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fichiers de log
METRICS_FILE="$HOME/logs/metrics.csv"
mkdir -p "$(dirname "$METRICS_FILE")"

# Fonction pour vérifier et installer les paquets requis
function install_if_missing {
    local package=$1
    if ! dpkg -s "$package" &> /dev/null; then
        echo -e "${YELLOW}Installation de $package...${NC}"
        sudo apt-get install -y "$package" &> /dev/null
        echo -e "${GREEN}$package installé avec succès.${NC}"
    else
        echo -e "${BLUE}$package est déjà installé.${NC}"
    fi
}

# Vérification des paquets nécessaires
REQUIRED_PACKAGES=("curl" "net-tools" "ifstat" "util-linux")
for package in "${REQUIRED_PACKAGES[@]}"; do
    install_if_missing "$package"
done

# Fonction pour afficher une barre de progression
function progress_bar {
    local progress=$1
    if (( progress > 100 )); then progress=100; fi
    if (( progress < 0 )); then progress=0; fi

    local bar=""
    for i in $(seq 1 10); do
        if (( i <= progress / 10 )); then
            bar="${bar}${YELLOW}█${NC}"
        else
            bar="${bar} "
        fi
    done
    printf "[${bar}] %s%%" "$progress"
}

# Fonction pour afficher les processus gourmands
function afficher_processus_gourmands {
    echo -e "${YELLOW}===== PROCESSUS LES PLUS GOURMANDS EN CPU =====${NC}"
    echo -e "${BLUE}Utilisateur      PID       CPU (%)    Commande${NC}"
    ps aux --sort=-%cpu | awk 'NR>1 {print $1, $2, $3, $11}' | head -n 10 | while read user pid cpu cmd; do
        printf "%-15s %-10s %-10s " "$user" "$pid" "$cmd"
        progress_bar "${cpu%.*}"
        echo ""
    done || echo -e "${RED}Erreur lors de l'extraction des processus gourmands en CPU${NC}"

    echo -e "${YELLOW}===== PROCESSUS LES PLUS GOURMANDS EN MÉMOIRE =====${NC}"
    echo -e "${BLUE}Utilisateur      PID       Mémoire (%) Commande${NC}"
    ps aux --sort=-%mem | awk 'NR>1 {print $1, $2, $4, $11}' | head -n 10 | while read user pid mem cmd; do
        printf "%-15s %-10s %-10s " "$user" "$pid" "$cmd"
        progress_bar "${mem%.*}"
        echo ""
    done || echo -e "${RED}Erreur lors de l'extraction des processus gourmands en mémoire${NC}"
}

# Fonction pour afficher la vitesse de connexion
function real_time_speed {
    echo -e "${GREEN}===== VITESSE DE CONNEXION =====${NC}"
    ifstat -t 1 1 | tail -n 1 | awk '{print "Download : " $1 " KB/s | Upload : " $2 " KB/s"}'
}

# Informations réseau
function network_info {
    echo -e "${YELLOW}===== ADRESSES IP ET DNS =====${NC}"
    echo -e "${BLUE}Adresses IP publiques et privées en écoute :${NC}"
    sudo netstat -tuln | awk '{print $4}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+' | sort | uniq

    echo -e "${GREEN}DNS configuré :${NC}"
    grep 'nameserver' /etc/resolv.conf | awk '{print $2}'
}

# Vérification de la connexion Internet
function internet_status {
    echo -e "${YELLOW}===== ÉTAT DE LA CONNEXION INTERNET =====${NC}"
    if ping -c 1 -W 2 google.com &> /dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me || echo "Non détectée")
        echo -e "${GREEN}Connexion Internet : Active${NC}"
        echo -e "${GREEN}Adresse IP publique : ${PUBLIC_IP}${NC}"
    else
        echo -e "${RED}Connexion Internet : Inactive${NC}"
    fi
}

# Fonction principale d'état du système
function system_status {
    echo -e "${BLUE}       ____  ____  ______            _____ __________  ____  ______${NC}"
    echo -e "${BLUE}      / __ \\/ __ \\/ ____/           / ___// ____/ __ \\/ __ \\/ ____/${NC}"
    echo -e "${BLUE}     / / / / / / / /      ______    \\__ \\/ /   / / / / /_/ / __/   ${NC}"
    echo -e "${BLUE}    / /_/ / /_/ / /___   /_____/   ___/ / /___/ /_/ / ____/ /___    ${NC}"
    echo -e "${BLUE}   /_____\\/____/\\____/            /____/\\____/\\____/_/   /_____/   ${NC}"
    echo -e "${BLUE}============================= By LehBiker ===========================${NC}"

    echo -e "${GREEN}Date : $(date +"%Y-%m-%d")${NC}"
    echo -e "${GREEN}Heure : $(date +"%H:%M:%S")${NC}"

    echo -e "${BLUE}===== METRIQUES =====${NC}"

    RAM_USAGE=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100}')
    echo -e "${GREEN}Utilisation de la RAM :${NC}"
    progress_bar ${RAM_USAGE%.*}
    echo ""

    # Calcul de la charge CPU
    CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

    # Arrondir la valeur de la charge CPU à l'entier le plus proche
    CPU_LOAD=${CPU_LOAD%.*}

    # Afficher la charge CPU avec la barre de progression
    echo -e "${YELLOW}Charge CPU : ${CPU_LOAD}%${NC}"
    progress_bar $CPU_LOAD
    echo ""


    # Espace disque avec affichage de la barre de progression corrigée
    echo -e "${BLUE}Espace disque :${NC}"
    df -h --output=source,pcent,used,size | grep '^/dev/' | while read -r source pcent used size; do
        echo -e "${BLUE}${source}:${NC} ${pcent} (${used} utilisé sur ${size})"
        
        # Suppression du symbole % pour extraire seulement la valeur numérique
        disk_usage=${pcent%\%}
        progress_bar "$disk_usage"
        echo ""  # Ligne vide pour séparer chaque ligne
    done

    echo -e "${GREEN}Uptime : $(uptime -p)${NC}"

    real_time_speed
    network_info
    internet_status

    echo -e "${YELLOW}===== SÉCURITÉ =====${NC}"
    
    # État des services critiques
    echo -e "${BLUE}État des services critiques :${NC}"
    echo -e "SSH : $(systemctl is-active ssh)"
    echo -e "Pare-feu (UFW) : $(systemctl is-active ufw)"
    
    # Affichage des tentatives de connexion échouées avec message si aucune tentative
    failed_attempts=$(grep "Failed password" /var/log/auth.log | tail -n 10)
    if [ -z "$failed_attempts" ]; then
        echo -e "${GREEN}Aucune tentative de connexion échouée${NC}"
    else
        echo "$failed_attempts"
    fi

    echo -e "${BLUE}Ports réseau en écoute :${NC}"
    sudo netstat -tuln

    echo -e "${YELLOW}===== Historique INSTALLATIONS =====${NC}"
    tail -n 10 /var/log/dpkg.log 2>/dev/null || echo "Journal non trouvé"
    find ~/Downloads -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | head -n 10

    echo -e "${YELLOW}===== CONNEXIONS =====${NC}"
    CONNECTION_COUNT=$(netstat -an | grep ESTABLISHED | wc -l)
    echo -e "${YELLOW}Connexions établies : ${CONNECTION_COUNT}${NC}"

    PACKET_LOSS=$(ping -c 4 google.com | grep 'packet loss' | awk '{print $6}')
    echo -e "${RED}Paquets perdus : ${PACKET_LOSS}${NC}"

    ZOMBIE_PROCESSES=$(ps aux | grep 'Z' | wc -l)
    echo -e "${RED}Processus zombies : ${ZOMBIE_PROCESSES}${NC}"

    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}\n' http://google.com)
    echo -e "${YELLOW}Temps de réponse : ${RESPONSE_TIME} sec${NC}"

    echo -e "${GREEN}Activité des utilisateurs :${NC}"
    who

    echo -e "${YELLOW}===== ADRESSES IP DERNIÈRES CONNEXIONS =====${NC}"
    grep "Accepted" /var/log/auth.log | awk '{print $11}' | sort | uniq | tail -n 10 | while read ip; do
        echo -e "${GREEN}Adresse IP : $ip${NC}"
    done

    afficher_processus_gourmands

    echo "$(date +'%Y-%m-%d %H:%M:%S'),$RAM_USAGE,$CPU_LOAD,$CONNECTION_COUNT,$PACKET_LOSS,$ZOMBIE_PROCESSES,$RESPONSE_TIME" >> $METRICS_FILE
}

# Boucle principale
while true; do
    clear
    system_status
    sleep 120
done
