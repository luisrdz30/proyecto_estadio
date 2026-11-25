"""Genera un FASTA aleatorio de prueba.
Uso: python generar_prueba.py prueba.fa 50   (50 MB)
"""
import random
import sys

salida = sys.argv[1] if len(sys.argv) > 1 else "prueba.fa"
mb = int(sys.argv[2]) if len(sys.argv) > 2 else 50
random.seed(42)
with open(salida, "w") as f:
    f.write(">cromosoma_prueba\n")
    for _ in range(mb * 1024 * 1024 // 60):
        f.write("".join(random.choices("ACGT", k=60)) + "\n")
print(f"Generado {salida} (~{mb} MB)")
