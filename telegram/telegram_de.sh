#!/bin/bash
# Ausführen mit:
# bash <(wget --cache=off -q -O - https://github.com/ghzserg/zmod_ff5m/raw/refs/heads/1.6/telegram/telegram.sh)

apt update 
apt upgrade -y
apt install docker.io docker-compose docker sudo apparmor -y || apt install docker.io docker-compose wmdocker sudo apparmor -y

useradd -m -G docker tbot
chsh tbot -s /bin/bash

systemctl enable docker
systemctl restart docker

cd ~tbot
cat > install.sh <<EOF
#!/bin/bash
cd
read -p "Geben Sie den Namen des Verzeichnisses ein, in dem der Bot gespeichert werden soll [bot1]: " bot_name
if [ "\${bot_name}" == "" ]; then bot_name="bot1"; fi

mkdir -p \${bot_name}
cd \${bot_name}
echo "Bot wurde im Verzeichnis \$(pwd) installiert"

mkdir -p config log timelapse_finished timelapse spoolman

wget --cache=off -q -O ../ff5m.sh https://github.com/ghzserg/zmod_ff5m/raw/refs/heads/1.6/telegram/ff5m.sh
chmod +x ../ff5m.sh

wget --cache=off -q -O docker-compose.yml https://github.com/ghzserg/zmod_ff5m/raw/refs/heads/1.6/telegram/docker-compose.yml
wget --cache=off -q -O config/telegram.conf https://github.com/ghzserg/zmod_ff5m/raw/refs/heads/1.6/telegram/telegram.conf

chmod 777 config log timelapse_finished timelapse spoolman

echo "1. Gehen Sie zu https://t.me/BotFather"
echo "2. Geben Sie /newbot ein"
echo "3. Geben Sie einen beliebigen Namen ein, der Ihnen gefällt"
echo "4. Geben Sie den Bot-Namen ein, z.B. ff5msuper_bot - muss am Ende mit _bot enden."
echo "5. Sie erhalten eine lange ID - diese muss in den Bot-Einstellungen im Parameter bot_token eingetragen werden."

read -p "Geben Sie den bot_token ein: " bot_token

sed -i "s|bot_token: 1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA|bot_token: \${bot_token}|" config/telegram.conf
docker-compose up -d

echo "Öffnen Sie Ihren Bot in Telegram."
echo "Er wird schreiben: 'Unauthorized access detected with chat_id: XXXX'"
echo "Geben Sie diese empfangene Nummer bei chat_id ein."

read -p "Geben Sie die chat_id ein: " chat_id 

docker-compose down
sed -i "s|chat_id: 111111111|chat_id: \${chat_id}|" config/telegram.conf 
docker-compose up -d

read -p "Soll ein weiterer Bot erstellt werden? [y/N]: " vopros
if [ "\${vopros}" == "y" ] || [ "\${vopros}" == "Y" ]; then 
    cd
    ./install.sh
fi
EOF

chmod +x install.sh
su - tbot ./install.sh
