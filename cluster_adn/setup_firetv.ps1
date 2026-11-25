# Configura un Fire TV / Android TV como nodo del cluster, via ADB por WiFi.
# Uso (PowerShell, en la carpeta cluster_adn):
#   powershell -ExecutionPolicy Bypass -File setup_firetv.ps1 -IP 192.168.100.18
# Opcional: -Rol master  (en la TV Indurama: copia master.py en vez de arrancar el worker)
param(
  [Parameter(Mandatory = $true)][string]$IP,
  [string]$Clave = "cluster123",
  [ValidateSet("worker", "master")][string]$Rol = "worker"
)
$dev = "${IP}:5555"

function Teclear([string]$texto) {
  # Escribe texto en la pantalla (Termux) como si fuera un teclado y presiona Enter
  $t = $texto.Replace(' ', '%s')
  & adb -s $dev shell "input text '$t'"
  & adb -s $dev shell input keyevent 66
  Start-Sleep -Milliseconds 700
}

Write-Host "== 1. Conectando por ADB a $dev ==" -ForegroundColor Cyan
& adb connect $dev
Write-Host "Si en la TV aparece 'Permitir depuracion', marca 'Siempre' y acepta."
Read-Host "Presiona Enter cuando hayas aceptado"
& adb -s $dev get-state
if ($LASTEXITCODE -ne 0) { Write-Host "No hay conexion ADB. Revisa la IP y la depuracion ADB." -ForegroundColor Red; exit 1 }

Write-Host "== 2. Abriendo Termux ==" -ForegroundColor Cyan
& adb -s $dev shell am start -n com.termux/.app.TermuxActivity
Write-Host "Si es la primera vez, Termux se instala solo (~30 s)."
Read-Host "Presiona Enter cuando veas el simbolo `$ en la TV"

Write-Host "== 3. Instalando Python, NumPy y SSH (tarda varios minutos) ==" -ForegroundColor Cyan
Teclear "termux-wake-lock"
Teclear "pkg update -y && pkg install -y python python-numpy openssh && echo INSTALACION_LISTA"
Read-Host "Presiona Enter cuando la TV muestre INSTALACION_LISTA (si pregunta algo, responde con el control: Enter)"

Write-Host "== 4. Configurando SSH (clave: $Clave) ==" -ForegroundColor Cyan
Teclear "passwd"
Start-Sleep -Seconds 1
Teclear $Clave
Start-Sleep -Seconds 1
Teclear $Clave
Start-Sleep -Seconds 1
Teclear "sshd"
Start-Sleep -Seconds 2

Write-Host "== 5. Copiando los programas (escribe la clave '$Clave' si la pide) ==" -ForegroundColor Cyan
$archivo = if ($Rol -eq "master") { "master.py" } else { "worker.py" }
& scp -P 8022 -o StrictHostKeyChecking=no $archivo "cluster@${IP}:~/"
if ($LASTEXITCODE -ne 0) { Write-Host "Fallo scp. Prueba manualmente: scp -P 8022 $archivo cluster@${IP}:~/" -ForegroundColor Red; exit 1 }

if ($Rol -eq "worker") {
  Write-Host "== 6. Arrancando el worker ==" -ForegroundColor Cyan
  Teclear "python worker.py"
  Write-Host "Listo: la TV debe mostrar 'Worker escuchando en puerto 5000'." -ForegroundColor Green
} else {
  Write-Host "Listo: master.py esta en la TV. Copia tambien el archivo de ADN:" -ForegroundColor Green
  Write-Host "  scp -P 8022 genoma.fa.seq cluster@${IP}:~/"
}
Write-Host "Para entrar por SSH: ssh -p 8022 cluster@$IP"
