# spix_config.py
import sys
import os
import socket
import getpass
from symantec_pam.config import write_sym_config

VERSION = "1.0.0"

# Default configuration template
config_symantec_pam = {
    "type": "SymantecPAM",
    "DNS": "192.168.xxx.yyy",
    "cliUsername": "symantecCLI",
    "cliPassword": "xxxxxxxxxxx",
    "apiUsername": "symantecAPI-131001",
    "apiPassword": "xxxxxxxxxxx",
    "tcf": ["keystorefile", "configfile", "mongodb", "postgresql", "pamuser"],
    "limit": 100000,
    "delimiter": ";"
}

def main():
    print(f"Credentials start, version={VERSION} -----------------------------------")
    try:
        hostname = socket.gethostname().lower()
        print(f"runHostname= {hostname}")

        username = getpass.getuser().lower()
        print(f"WhoAmI= {username}")

        # Determine standard temp directory path based on OS
        if os.name == 'nt':
            out_dir = "C:\\Temp"
        else:
            out_dir = "/tmp"

        # Write config file
        filepath = write_sym_config(config_symantec_pam, out_dir)
        print(f"Write configuration to '{filepath}'")
    except Exception as e:
        print(f"Expected exception received: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
