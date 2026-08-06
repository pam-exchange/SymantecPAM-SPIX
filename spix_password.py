# spix_password.py
import argparse
import getpass
import sys
from symantec_pam.crypto import protect_sym_password, unprotect_sym_password

def main():
    parser = argparse.ArgumentParser(description="SPIX Password Encryption and Decryption Utility")

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-Password", "--Password", help="Plain text password to encrypt")
    group.add_argument("-EncryptedPassword", "--EncryptedPassword", help="Encrypted password (starting with {enc}) to decrypt")

    parser.add_argument("-Passphrase", "--Passphrase", help="Passphrase to derive the encryption/decryption key. If omitted, you will be prompted.")

    args = parser.parse_args()

    passphrase = args.Passphrase
    if passphrase is None:
        passphrase = getpass.getpass("Enter encryption passphrase: ")
        if args.Password:
            passphrase2 = getpass.getpass("Confirm encryption passphrase: ")
            if passphrase != passphrase2:
                print("Encryption passphrase does not match.", file=sys.stderr)
                sys.exit(1)

    try:
        if args.Password:
            encrypted = protect_sym_password(args.Password, passphrase)
            print(encrypted)
        else:
            decrypted = unprotect_sym_password(args.EncryptedPassword, passphrase)
            print(decrypted)
    except Exception as e:
        print(f"Exception received: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
