#!/usr/bin/env python3
import hmac, hashlib, base64, time, sys

if len(sys.argv) < 2:
    print("Usage: totp.py <secret>")
    sys.exit(1)

secret = sys.argv[1]
secret += "=" * ((8 - len(secret) % 8) % 8)
try:
    key = base64.b32decode(secret, casefold=True)
except Exception as e:
    print("Invalid Base32 secret")
    sys.exit(1)

t = int(time.time() / 30).to_bytes(8, 'big')
h = hmac.new(key, t, hashlib.sha1).digest()
o = h[-1] & 0x0F
otp = (int.from_bytes(h[o:o+4], 'big') & 0x7FFFFFFF) % 1000000
print(str(otp).zfill(6))
