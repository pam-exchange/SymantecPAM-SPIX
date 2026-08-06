# config.py
import os
import json
import socket
import getpass

try:
    import win32crypt
    HAS_DPAPI = True
except ImportError:
    HAS_DPAPI = False

def get_config_filename(config_path="."):
    """
    Returns the resolved configuration filename based on hostname and current user.
    """
    # Get hostname (lowercase)
    hostname = socket.gethostname().lower()
    # Get current username
    username = getpass.getuser().lower()

    # If config_path is a directory, append the template
    if os.path.isdir(config_path):
        filename = f"SPIX-{hostname}_{username}.properties"
        return os.path.join(config_path, filename)

    # If it's a file but contains 'XXXX', replace it
    if "XXXX" in config_path:
        return config_path.replace("XXXX", f"{hostname}_{username}")

    return config_path

def encrypt_password_field(plain_text: str) -> str:
    """
    Encrypts password string. On Windows with pywin32, uses DPAPI (similar to SecureString).
    Otherwise, returns plain text.
    """
    if HAS_DPAPI:
        try:
            # Encrypt using DPAPI
            encrypted = win32crypt.CryptProtectData(plain_text.encode('utf-16le'), None, None, None, None, 0)
            return encrypted.hex()
        except Exception:
            return plain_text
    return plain_text

def decrypt_password_field(encrypted_text: str) -> str:
    """
    Decrypts DPAPI secure string if possible, or returns original text if not encrypted or unsupported.
    """
    if not encrypted_text:
        return ""

    # Check if text looks like a hex string produced by DPAPI (only hex characters and reasonably long)
    if all(c in "0123456789abcdefABCDEF" for c in encrypted_text) and len(encrypted_text) > 32:
        if HAS_DPAPI:
            try:
                encrypted_bytes = bytes.fromhex(encrypted_text)
                decrypted = win32crypt.CryptUnprotectData(encrypted_bytes, None, None, None, 0)
                # DPAPI returns tuple (description, data)
                return decrypted[1].decode('utf-16le')
            except Exception as e:
                # Fallback
                return encrypted_text
        else:
            # We are not on Windows or lack pywin32
            print(f"Warning: Encrypted password field detected but DPAPI is not available on this platform/environment. Returning ciphertext as-is.")
            return encrypted_text

    return encrypted_text

def read_sym_config(config_path="."):
    """
    Reads the SPIX config properties file, resolves template filename, and decrypts credentials.
    """
    filepath = get_config_filename(config_path)
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Config file not found: {filepath}")

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Standard format is an array of dictionaries or a single dictionary
    config_list = data if isinstance(data, list) else [data]

    final_config = {}
    for entry in config_list:
        if entry.get("type") == "SymantecPAM":
            cli_pwd = decrypt_password_field(entry.get("cliPassword", ""))
            api_pwd = decrypt_password_field(entry.get("apiPassword", ""))

            final_config["SymantecPAM"] = {
                "DNS": entry.get("DNS", ""),
                "cliUsername": entry.get("cliUsername", ""),
                "cliPassword": cli_pwd,
                "apiUsername": entry.get("apiUsername", ""),
                "apiPassword": api_pwd,
                "tcf": entry.get("tcf", []),
                "limit": int(entry.get("limit", 100000)),
                "Delimiter": entry.get("delimiter", ";")
            }
            break

    return final_config

def write_sym_config(config_data, config_path="."):
    """
    Writes properties config file, encrypting passwords with DPAPI if available.
    """
    filepath = get_config_filename(config_path)

    # Encrypt passwords
    entry = config_data.copy()
    if entry.get("cliPassword"):
        entry["cliPassword"] = encrypt_password_field(entry["cliPassword"])
    if entry.get("apiPassword"):
        entry["apiPassword"] = encrypt_password_field(entry["apiPassword"])

    # Write as list containing the config dict to match original
    out_data = [entry]

    os.makedirs(os.path.dirname(os.path.abspath(filepath)), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(out_data, f, indent=4)

    return filepath
