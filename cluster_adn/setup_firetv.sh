#!/usr/bin/env bash
# Configura un Fire TV / Android TV como nodo del cluster, via ADB por WiFi (Linux/Mac).
# Uso: ./setup_firetv.sh 192.168.100.18 [worker|master] [clave]
set -e
IP="$1"; ROL="${2:-worker}"; CLAVE="${3:-cluster123}"
[ -z "$IP" ] && { echo "Uso: $0 IP [worker|master] [clave]"; exit 1; }
DEV="$IP:5555"
teclear() { adb -s "$DEV" shell "input text '${1// /%s}'"; adb -s "$DEV" shell input keyevent 66; sleep 0.7; }

echo "== 1. Conectando por ADB a $DEV =="
adb connect "$DEV"
read -rp "Acepta 'Permitir depuracion' en la TV (marca Siempre) y presiona Enter "
adb -s "$DEV" get-state

echo "== 2. Abriendo Termux =="
adb -s "$DEV" shell am start -n com.termux/.app.TermuxActivity
read -rp "Presiona Enter cuando veas el simbolo \$ en la TV "

echo "== 3. Instalando Python, NumPy y SSH =="
teclear "termux-wake-lock"
teclear "pkg update -y && pkg install -y python python-numpy openssh && echo INSTALACION_LISTA"
read -rp "Presiona Enter cuando la TV muestre INSTALACION_LISTA "

echo "== 4. Configurando SSH (clave: $CLAVE) =="
teclear "passwd"; sleep 1; teclear "$CLAVE"; sleep 1; teclear "$CLAVE"; sleep 1
teclear "sshd"; sleep 2

echo "== 5. Copiando programas (clave: $CLAVE) =="
ARCH=worker.py; [ "$ROL" = master ] && ARCH=master.py
scp -P 8022 -o StrictHostKeyChecking=no "$ARCH" "cluster@$IP:~/"

if [ "$ROL" = worker ]; then
  teclear "python worker.py"
  echo "Listo: la TV debe mostrar 'Worker escuchando en puerto 5000'."
else
  echo "Listo. Copia el ADN: scp -P 8022 genoma.fa.seq cluster@$IP:~/"
fi
echo "SSH: ssh -p 8022 cluster@$IP"
