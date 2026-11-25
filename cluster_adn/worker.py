"""Nodo ESCLAVO del cluster de ADN. Se ejecuta en cada Fire TV Stick (Termux).
Uso: python worker.py [puerto]   (por defecto 5000)
"""
import json
import socket
import struct
import sys
import time

import numpy as np

PUERTO = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
LUT = np.full(256, 4, dtype=np.uint8)  # A=0 C=1 G=2 T=3, otro=4 (invalido)
for _i, _b in enumerate(b"ACGT"):
    LUT[_b] = _i


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


def analizar(datos, propia, k, motivos):
    """MAP: analiza un bloque. 'propia' = bytes que pertenecen a este bloque;
    el resto es solapamiento y solo sirve para patrones que cruzan el borde."""
    a = np.frombuffer(datos, dtype=np.uint8)
    reg = a[:propia]
    bases = {c: int(np.count_nonzero(reg == ord(c))) for c in "ACGTN"}

    # k-mers vectorizados: cada k-mer -> numero en base 4
    cod = LUT[a]
    valido = cod < 4
    m = max(0, min(propia, len(a) - k + 1))
    codigo = np.zeros(m, dtype=np.uint32)
    ok = np.ones(m, dtype=bool)
    for j in range(k):
        codigo = codigo * 4 + cod[j:j + m]
        ok &= valido[j:j + m]
    kmers = np.bincount(codigo[ok], minlength=4 ** k)

    # motivos (con solapamiento): solo cuentan los que EMPIEZAN en la region propia
    mot = {}
    for nombre, patron in motivos.items():
        p = patron.encode()
        c, i = 0, datos.find(p)
        while -1 < i < propia:
            c += 1
            i = datos.find(p, i + 1)
        mot[nombre] = c
    return {"bases": bases, "kmers": kmers.tolist(), "motivos": mot}


def main():
    srv = socket.socket()
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", PUERTO))
    srv.listen(1)
    print(f"Worker escuchando en puerto {PUERTO}", flush=True)
    while True:
        con, addr = srv.accept()
        print("Maestro conectado:", addr, flush=True)
        with con:
            try:
                while True:
                    hdr = json.loads(recv_msg(con))
                    if hdr.get("fin"):
                        break
                    datos = recv_msg(con)
                    t = time.time()
                    r = analizar(datos, hdr["propia"], hdr["k"], hdr["motivos"])
                    r.update(tid=hdr["tid"], seg=time.time() - t)
                    send_msg(con, json.dumps(r).encode())
                    print(f"Bloque {hdr['tid']} listo en {r['seg']:.2f}s", flush=True)
            except (ConnectionError, OSError) as e:
                print("Conexion perdida:", e, flush=True)
        print("Esperando al maestro...", flush=True)


if __name__ == "__main__":
    main()
