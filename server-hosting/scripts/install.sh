#!/bin/sh

# Note: Arguments to this script 
#  1: string - S3 bucket for your backup save files (required)
#  2: true|false - whether to use Satisfactory Experimental build (optional, default false)
S3_SAVE_BUCKET=$1
USE_EXPERIMENTAL_BUILD=${2-false}


# install steamcmd: https://developer.valvesoftware.com/wiki/SteamCMD?__cf_chl_jschl_tk__=pmd_WNQPOiK18.h0rf16RCYrARI2s8_84hUMwT.7N1xHYcs-1635248050-0-gqNtZGzNAiWjcnBszQiR#Linux.2FmacOS)
add-apt-repository multiverse
dpkg --add-architecture i386
apt update

# Needed to accept steam license without hangup
echo steam steam/question 'select' "I AGREE" | sudo debconf-set-selections
echo steam steam/license note '' | sudo debconf-set-selections

apt install -y unzip lib32gcc1 steamcmd

# install satisfactory: https://satisfactory.fandom.com/wiki/Dedicated_servers
if [ $USE_EXPERIMENTAL_BUILD = "true" ]; then
    STEAM_INSTALL_SCRIPT="/usr/games/steamcmd +login anonymous +app_update 1690800 -beta experimental validate +quit"
else
    STEAM_INSTALL_SCRIPT="/usr/games/steamcmd +login anonymous +app_update 1690800 validate +quit"
fi
# note, we are switching users because steam doesn't recommend running steamcmd as root
su - ubuntu -c "$STEAM_INSTALL_SCRIPT"

# enable as server so it stays up and start: https://satisfactory.fandom.com/wiki/Dedicated_servers/Running_as_a_Service
cat << EOF > /etc/systemd/system/satisfactory.service
[Unit]
Description=Satisfactory dedicated server
Wants=network-online.target
After=syslog.target network.target nss-lookup.target network-online.target

[Service]
Environment="LD_LIBRARY_PATH=./linux64"
ExecStartPre=$STEAM_INSTALL_SCRIPT
ExecStart=/home/ubuntu/.steam/SteamApps/common/SatisfactoryDedicatedServer/FactoryServer.sh -ServerQueryPort=15777 -BeaconPort=15000 -Port=7777 -log -unattended
User=ubuntu
Group=ubuntu
StandardOutput=journal
Restart=on-failure
KillSignal=SIGINT
WorkingDirectory=/home/ubuntu/.steam/SteamApps/common/SatisfactoryDedicatedServer

[Install]
WantedBy=multi-user.target
EOF
systemctl enable satisfactory
systemctl start satisfactory

# enable auto shutdown: https://github.com/feydan/satisfactory-tools/tree/main/server-hosting/scripts/auto-shutdown.sh
cat << EOF > /home/ubuntu/auto-shutdown.sh
#!/bin/sh

connectionBytes=\$(ss -lu | grep 7777 | awk -F ' ' '{s+=\$2} END {print s}')
        
if [ -z \$connectionBytes ] || [ \$connectionBytes -eq 0 ]; then
    echo "No game activity detected. Shutting down."
    sudo shutdown -h now
fi
EOF
chmod +x /home/ubuntu/auto-shutdown.sh
chown ubuntu:ubuntu /home/ubuntu/auto-shutdown.sh

# check game port for auto shutdown every 10 minutes
su - ubuntu -c "crontab -u ubuntu -l | { cat; echo \"*/10 * * * * /home/ubuntu/auto-shutdown.sh\"; } | crontab -"
