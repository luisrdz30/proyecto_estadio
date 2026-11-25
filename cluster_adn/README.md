# Cluster de TVs para análisis de ADN

1 maestro (TV Indurama, Android TV) + 2 esclavos (Fire TV Stick) con el modelo MapReduce sobre WiFi.

| Archivo | Para qué |
|---|---|
| `worker.py` | Nodo esclavo. Corre en cada Fire TV (Termux). |
| `master.py` | Nodo maestro. Divide el ADN en bloques de 16 MB, los reparte y suma los resultados. |
| `setup_firetv.ps1` / `setup_firetv.sh` | Configura una TV desde tu PC por ADB: instala Python, NumPy y SSH, y copia los programas. |
| `limpiar_fasta.py` | Quita los encabezados y saltos de línea del FASTA (hazlo en la PC). |
| `generar_prueba.py` | Genera un FASTA aleatorio pequeño para pruebas. |

## Requisitos en la PC (mismo WiFi que las TVs)
- Android platform-tools (`adb`): https://developer.android.com/tools/releases/platform-tools
- Python 3 con numpy (`pip install numpy`)
- `scp`/`ssh` (vienen incluidos en Windows 10/11)

## Pasos
```powershell
# 1. Cada Fire TV (worker)
powershell -ExecutionPolicy Bypass -File setup_firetv.ps1 -IP 192.168.100.18
powershell -ExecutionPolicy Bypass -File setup_firetv.ps1 -IP <IP_FIRE_TV_2>

# 2. TV Indurama (maestro)
powershell -ExecutionPolicy Bypass -File setup_firetv.ps1 -IP <IP_INDURAMA> -Rol master
python limpiar_fasta.py genoma.fa
scp -P 8022 genoma.fa.seq cluster@<IP_INDURAMA>:~/

# 3. Ejecutar (en la Indurama, por SSH o con teclado)
python master.py genoma.fa.seq 192.168.100.18 <IP_FIRE_TV_2>
```

## Prueba rápida en tu PC (sin TVs)
```bash
python generar_prueba.py prueba.fa 50
python worker.py 5001 &   python worker.py 5002 &
python master.py prueba.fa 127.0.0.1:5001 127.0.0.1:5002
```

## Métricas para el informe
- T1: `master.py` con un solo worker. T2: con los dos.
- Speedup S = T1/T2, eficiencia E = S/2. Explicar con la Ley de Amdahl (la red WiFi es la parte secuencial).
