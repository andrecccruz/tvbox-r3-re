"""Extrai as particoes logicas (system, vendor, product...) de uma imagem super do Android.
Uso: python3 -I lpunpack.py <super.img> <diretorio_saida>
"""
import os
import struct
import sys

SECTOR = 512
GEOMETRY_MAGIC = 0x616C4467
HEADER_MAGIC = 0x414C5030


def main(img, out):
    with open(img, "rb") as f:
        f.seek(4096)
        geo = f.read(4096)
        magic, = struct.unpack_from("<I", geo, 0)
        if magic != GEOMETRY_MAGIC:
            sys.exit("geometria LP nao encontrada")

        f.seek(4096 + 2 * 4096)  # metadata primaria, slot 0
        hdr = f.read(256)
        magic, major, minor, hsize = struct.unpack_from("<IHHI", hdr, 0)
        if magic != HEADER_MAGIC:
            sys.exit("header LP nao encontrado")
        tables_size, = struct.unpack_from("<I", hdr, 44)
        descs = struct.unpack_from("<12I", hdr, 80)
        f.seek(4096 + 2 * 4096 + hsize)
        tables = f.read(tables_size)

        def table(i):
            off, num, size = descs[i * 3:i * 3 + 3]
            return [tables[off + k * size: off + (k + 1) * size] for k in range(num)]

        parts = table(0)
        extents = table(1)
        print(f"LP metadata v{major}.{minor}, {len(parts)} particoes")
        os.makedirs(out, exist_ok=True)
        for p in parts:
            name = p[:36].split(b"\0")[0].decode()
            _, first, num, _ = struct.unpack_from("<IIII", p, 36)
            total = 0
            with open(os.path.join(out, name + ".img"), "wb") as o:
                for e in extents[first:first + num]:
                    nsec, ttype, tdata, _ = struct.unpack_from("<QIQI", e, 0)
                    length = nsec * SECTOR
                    if ttype == 0:  # LINEAR
                        f.seek(tdata * SECTOR)
                        left = length
                        while left:
                            chunk = f.read(min(left, 8 << 20))
                            o.write(chunk)
                            left -= len(chunk)
                    else:  # ZERO
                        o.write(b"\0" * length)
                    total += length
            print(f"  {name:12s} {total // (1 << 20):5d} MiB  {num} extent(s)")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
