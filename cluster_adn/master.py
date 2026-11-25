"""Nodo MAESTRO del cluster de ADN (TV Indurama o laptop).
Uso:
  python master.py ARCHIVO.fa IP1[:puerto] IP2[:puerto] ...
Ejemplo:
  python master.py genoma.fa 192.168.100.18 192.168.100.19
Si el archivo ya termina en .seq se asume limpio (sin encabezados ni saltos).
"""
import json
import os
import queue
import socket
import struct
import sys
import threading
import time

import numpy as np

BLOQUE = 16 * 1024 * 1024
K = 4
MOTIVOS = {"TATA_box": "TATAAA", "EcoRI": "GAATTC", "BamHI": "GGATCC", "CpG": "CG"}
SOLAPA = max(K, *(len(m) for m in MOTIVOS.values())) - 1


def recv_exact(s, n):
    buf = bytearray()
    while len(buf) < n:
        p = s.recv(min(n - len(buf), 1 << 20))
        if not p:
            raise ConnectionError("conexion cerrada")
        buf += p
    return bytes(buf)


def recv_msg(s):
    return recv_exact(s, struct.unpack("!Q", recv_exact(s, 8))[0])


def send_msg(s, b):
    s.sendall(struct.pack("!Q", len(b)) + b)


def limpiar_fasta(entrada, salida):
    """Quita encabezados '>' y saltos de linea; deja solo la secuencia en mayusculas."""
    with open(entrada, "rb") as f, open(salida, "wb") as o:
        for linea in f:
            if not linea.startswith(b">"):
                o.write(linea.strip().upper())


def atender(host, port, archivo, tareas, resultados, lock, stats):
    try:
        s = socket.create_connection((host, port), timeout=300)
    except OSError as e:
        print(f"[{host}] no disponible: {e}")
        return
    with s, open(archivo, "rb") as f:
        while True:
            try:
                tid, off, n = tareas.get_nowait()
            except queue.Empty:
                break
            f.seek(off)
            datos = f.read(n + SOLAPA)
            try:
                send_msg(s, json.dumps({"tid": tid, "propia": n, "k": K,
                                        "motivos": MOTIVOS}).encode())
                send_msg(s, datos)
                r = json.loads(recv_msg(s))
            except OSError:
                print(f"[{host}] fallo; reasignando bloque {tid}")
                tareas.put((tid, off, n))  # tolerancia a fallos
                return
            r["nodo"] = f"{host}:{port}"
            with lock:
                resultados.append(r)
                stats[r["nodo"]] = stats.get(r["nodo"], 0) + 1
                print(f"[{host}] bloque {tid} OK ({len(resultados)} completados)", flush=True)
        try:
            send_msg(s, json.dumps({"fin": True}).encode())
        except OSError:
            pass


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    fasta = sys.argv[1]
    workers = []
    for w in sys.argv[2:]:
        h, _, p = w.partition(":")
        workers.append((h, int(p or 5000)))

    limpio = fasta if fasta.endswith(".seq") else fasta + ".seq"
    if not os.path.exists(limpio):
        print("Limpiando FASTA...", flush=True)
        limpiar_fasta(fasta, limpio)
    total = os.path.getsize(limpio)

    tareas = queue.Queue()
    for tid, off in enumerate(range(0, total, BLOQUE)):
        tareas.put((tid, off, min(BLOQUE, total - off)))
    nbloques = tareas.qsize()
    print(f"{total / 1e9:.3f} GB -> {nbloques} bloques, {len(workers)} workers", flush=True)

    resultados, lock, stats = [], threading.Lock(), {}
    t0 = time.time()
    hilos = [threading.Thread(target=atender,
                              args=(h, p, limpio, tareas, resultados, lock, stats))
             for h, p in workers]
    for h in hilos:
        h.start()
    for h in hilos:
        h.join()
    T = time.time() - t0

    if len(resultados) != nbloques:
        print(f"ATENCION: solo se completaron {len(resultados)}/{nbloques} bloques")
        if not resultados:
            sys.exit(1)

    # ---------- REDUCE ----------
    bases = {c: sum(r["bases"][c] for r in resultados) for c in "ACGTN"}
    kmers = np.sum([r["kmers"] for r in resultados], axis=0)
    mot = {m: sum(r["motivos"][m] for r in resultados) for m in MOTIVOS}
    acgt = sum(bases[c] for c in "ACGT") or 1
    nombres = ["".join("ACGT"[(i >> 2 * (K - 1 - j)) & 3] for j in range(K))
               for i in range(4 ** K)]

    print("\n===== RESULTADOS =====")
    print("Bases:", bases)
    print(f"Contenido GC: {100 * (bases['G'] + bases['C']) / acgt:.2f}%")
    print("Motivos:", mot)
    top = [(nombres[i], int(kmers[i])) for i in np.argsort(kmers)[::-1][:10]]
    print(f"Top 10 {K}-mers:", top)
    print(f"Tiempo total: {T:.1f}s | Throughput: {total / 1e6 / T:.1f} MB/s")
    print("Bloques por nodo:", stats)
    print("Tiempo de computo por nodo (s):",
          {h: round(sum(r["seg"] for r in resultados if r["nodo"] == h), 1) for h in stats})


if __name__ == "__main__":
    main()
