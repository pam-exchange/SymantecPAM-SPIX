# crypto.py
import base64
import hashlib
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

def encrypt_pbkdf2(plain_text: str, password: str) -> str:
    """
    Encrypts plain text using PBKDF2 with SHA-1, 100,000 iterations to derive a 256-bit AES key.
    Outputs Base64-encoded bytes of concatenated salt (16 bytes) + IV (16 bytes) + ciphertext.
    """
    salt = os.urandom(16)
    key = hashlib.pbkdf2_hmac('sha1', password.encode('utf-8'), salt, 100000, 32)
    iv = os.urandom(16)

    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(plain_text.encode('utf-8')) + padder.finalize()

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    encryptor = cipher.encryptor()
    cipher_bytes = encryptor.update(padded_data) + encryptor.finalize()

    combined = salt + iv + cipher_bytes
    return base64.b64encode(combined).decode('utf-8')

def decrypt_pbkdf2(cipher_base64: str, password: str) -> str:
    """
    Decrypts Base64-encoded concatenated salt + IV + ciphertext.
    Derives key using PBKDF2 with SHA-1, 100,000 iterations.
    """
    combined = base64.b64decode(cipher_base64)
    salt = combined[:16]
    iv = combined[16:32]
    cipher_bytes = combined[32:]

    key = hashlib.pbkdf2_hmac('sha1', password.encode('utf-8'), salt, 100000, 32)

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    decryptor = cipher.decryptor()
    padded_data = decryptor.update(cipher_bytes) + decryptor.finalize()

    unpadder = padding.PKCS7(128).unpadder()
    plain_bytes = unpadder.update(padded_data) + unpadder.finalize()
    return plain_bytes.decode('utf-8')

def protect_sym_password(password: str, passphrase: str) -> str:
    if not passphrase:
        passphrase = ""
    enc = encrypt_pbkdf2(password, passphrase)
    return "{enc}" + enc

def unprotect_sym_password(encrypted_password: str, passphrase: str) -> str:
    if not encrypted_password.startswith("{enc}"):
        raise ValueError("Encrypted password must start with '{enc}'")
    cipher = encrypted_password[5:]
    if not passphrase:
        passphrase = ""
    return decrypt_pbkdf2(cipher, passphrase)
