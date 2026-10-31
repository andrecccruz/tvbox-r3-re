"""Mostra o SHA-256 do certificado de assinatura (esquema v2/v3) de cada APK.
Uso: python3 -I apkcert.py arquivo.apk [...]
"""
import hashlib
import struct
import sys

V2, V3 = 0x7109871A, 0xF05368C0


def lp(buf, off):
    """Le um bloco com prefixo de tamanho uint32."""
    n, = struct.unpack_from("<I", buf, off)
    return buf[off + 4:off + 4 + n], off + 4 + n


def certs(path):
    data = open(path, "rb").read()
    eocd = data.rfind(b"PK\x05\x06")
    cd_off, = struct.unpack_from("<I", data, eocd + 16)
    if data[cd_off - 16:cd_off] != b"APK Sig Block 42":
        return None, []
    size, = struct.unpack_from("<Q", data, cd_off - 24)
    block = data[cd_off - size - 8:cd_off - 24]
    pos, found = 8, {}
    while pos < len(block):
        plen, = struct.unpack_from("<Q", block, pos)
        pid, = struct.unpack_from("<I", block, pos + 8)
        found[pid] = block[pos + 12:pos + 8 + plen]
        pos += 8 + plen
    for scheme, pid in (("v3", V3), ("v2", V2)):
        if pid not in found:
            continue
        signers, _ = lp(found[pid], 0)
        signer, _ = lp(signers, 0)
        signed, _ = lp(signer, 0)
        _, off = lp(signed, 0)          # digests
        cert_seq, _ = lp(signed, off)   # certificates
        out, o = [], 0
        while o < len(cert_seq):
            c, o = lp(cert_seq, o)
            out.append(hashlib.sha256(c).hexdigest())
        return scheme, out
    return None, []


for p in sys.argv[1:]:
    scheme, cs = certs(p)
    print(f"{scheme or 'sem v2/v3':8s} {(cs[0] if cs else '-')}  {p.rsplit('/', 1)[-1]}")
