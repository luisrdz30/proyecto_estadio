"""Convierte un FASTA en secuencia pura (.seq) en tu PC, antes de copiarlo a la TV maestra.
Uso: python limpiar_fasta.py genoma.fa   ->  genoma.fa.seq
"""
import sys
from master import limpiar_fasta

limpiar_fasta(sys.argv[1], sys.argv[1] + ".seq")
print("Listo:", sys.argv[1] + ".seq")
