#!/usr/bin/env python3
import sys
import os
import filecmp

def main():
    if len(sys.argv) != 3:
        sys.exit(2)

    f1, f2 = sys.argv[1], sys.argv[2]

    try:
        # Mejora Pro: Si los tamaños son distintos, es físicamente imposible
        # que el contenido sea idéntico. Ahorramos lectura de disco.
        if os.path.getsize(f1) != os.path.getsize(f2):
            sys.exit(1)

        # Comparación profunda bit a bit
        if filecmp.cmp(f1, f2, shallow=False):
            sys.exit(0) # Duplicado
        else:
            sys.exit(1) # Diferente
    except OSError:
        sys.exit(2)

if __name__ == "__main__":
    main()
