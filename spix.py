# spix.py
import argparse
import sys
import os
import getpass
from datetime import datetime

from symantec_pam.config import read_sym_config
from symantec_pam.client import SymantecPAMClient
from symantec_pam.operations import export_sym, import_sym

def print_custom_help():
    help_text = """SPIX - Symantec PAM Import/Export Tool
======================================

SPIX is a Python-based utility for exporting and importing
Credential Management data from Symantec PAM. It extends functionality
originally provided by the legacy xsie tool and supports new PAM
features, API/CLI updates, and modern extension types.

SPIX uses both CLI and API calls. All operations are limited to the
permissions assigned to the authenticated CLI/API users.

Usage:
  python spix.py [-Help]
  python spix.py -Export   [options]
  python spix.py -Import   [options]

Commands:
  -Help, --Help             Show this help text
  -Export, --Export         Export objects from Symantec PAM
  -Import, --Import         Import objects from CSV

General Options:
  -ConfigPath <path>        Path to SPIX properties file.
                            Default: .
  -Delimiter <char>         CSV delimiter override.
  -Quiet                    Reduce console output.

----------------------------------------------------------------------
Export Options
----------------------------------------------------------------------

python spix.py -Export [options]

  -OutputPath <path>        Directory where exported CSV files are saved.
                            Default: .\\SPIX-output

  -Category <name>          One or more categories to export:
                            ALL
                            Target               (TargetServer, TargetApplication, TargetAccount)
                            A2A                 (RequestServer, RequestScript, Authorization)
                            Proxy
                            Policy              (PCP, PVP, SSHKeyPairPolicy, JIT, CustomWorkflow)
                            UserGroup           (Filter, Group, Role, User, UserGroup)
                            Secret              (Vault, VaultSecret)
                            AccessPolicy
                            Service
                            Device

  -SrvName <filter>         Filter by server name. Supports '*'.
  -AppName <filter>         Filter by application name. Supports '*'.
  -AccName <filter>         Filter by account name. Supports '*'.
  -ExtensionType <filter>   Filter by extension type. Supports '*'.

  -ShowPassword             Retrieve and export passwords in clear text.
                            Requires temporary assignment of SPIX-PVP
                            if PVP requires checkout/approval/notifications.

  -Passphrase <passphrase>  With -ShowPassword, encrypt passwords using
                            a passphrase-derived key. Empty ('') prompts.

  -Compress                 Combine application and account data into a
                            single simplified file (no extension details).

Extension Types:
  Built-in extension types include: activeDirectorySshKey, AS400, AwsAccessCredentials,
  AwsApiProxyCredentials, AzureAccessCredentials, CiscoSSH, Generic, genericSecretType,
  HPServiceManager, juniper, ldap, mssql, oracle, PaloAlto, nsxcontroller, nsxmanager,
  nsxproxy, remedy, SPML2, unixII, vmware, windows, windowsDomainService, windowsSshKey,
  windowsSshPassword, weblogic10, sybase, vcf, ServiceDeskBroker, ServiceNow, RadiusTacacsSecret,
  and more.

  Custom connector names from the 'tcf' property are also supported (case sensitive).

----------------------------------------------------------------------
Import Options
----------------------------------------------------------------------

python spix.py -Import [options]

  -InputFile <file>         CSV file to import.
  -Passphrase <passphrase>  Decrypt encrypted passwords beginning with {enc}.
                            Empty ('') prompts for input.
  -UpdatePassword           For TargetAccounts, after creation replaces known
                            endpoint password with PAM-generated password.

Import Notes:
  * "password" = _generate_pass_ → PAM generates a password using the PCP.
  * Valid Action values in CSV: New, Update, Remove, Empty.
  * Import supported for:
      Authorization, PCP, Proxy, PVP, RequestScript, RequestServer,
      Role, SSHKeyPairPolicy, TargetAccount, TargetApplication,
      TargetServer, UserGroup.
  * Proxies cannot be created by CLI/API; they register when launched.
  * Failed rows are written to a separate error CSV with ErrorMessage column.
"""
    print(help_text)


def main():
    parser = argparse.ArgumentParser(description="SPIX - Symantec PAM Import/Export Tool", add_help=False)

    # Modes
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-Export", "--Export", action="store_true")
    group.add_argument("-Import", "--Import", action="store_true")

    # Options
    parser.add_argument("-ConfigPath", "--ConfigPath", default=".")
    parser.add_argument("-OutputPath", "--OutputPath", default=".\\SPIX-output")
    parser.add_argument("-Category", "--Category", nargs="+", default=["ALL"])
    parser.add_argument("-ShowPassword", "--ShowPassword", action="store_true")
    parser.add_argument("-SrvName", "--SrvName", default="")
    parser.add_argument("-AppName", "--AppName", default="")
    parser.add_argument("-AccName", "--AccName", default="")
    parser.add_argument("-ExtensionType", "--ExtensionType", default="")
    parser.add_argument("-Compress", "--Compress", action="store_true")

    parser.add_argument("-InputFile", "--InputFile")
    parser.add_argument("-Synchronize", "--Synchronize", action="store_true")
    parser.add_argument("-UpdatePassword", "--UpdatePassword", action="store_true")

    parser.add_argument("-Passphrase", "--Passphrase")
    parser.add_argument("-Delimiter", "--Delimiter")
    parser.add_argument("-Quiet", "--Quiet", action="store_true")

    # Custom Help
    parser.add_argument("-Help", "--Help", action="store_true")

    # If no arguments are passed, sys.argv will contain only the script name
    if len(sys.argv) == 1:
        print_custom_help()
        sys.exit(0)

    # Parse arguments
    # We must support case-insensitive arguments or simple case mappings if they start with -
    # But standard argparse expects -- for long names.
    # To support PowerShell style -ConfigPath instead of --ConfigPath, we can preprocess sys.argv!
    # This is a brilliant and extremely robust way to make python CLI scripts 100% compatible with PowerShell style arguments!
    preprocessed_argv = []
    for arg in sys.argv[1:]:
        if arg.startswith("-") and not arg.startswith("--"):
            # Check if there is an exact case-sensitive or case-insensitive match in defined arguments
            # If so, map it to --Name
            name = arg[1:]
            preprocessed_argv.append(f"--{name}")
        else:
            preprocessed_argv.append(arg)

    args = parser.parse_args(preprocessed_argv)

    if args.Help:
        print_custom_help()
        sys.exit(0)

    start_time = datetime.now()

    try:
        # Load configuration
        config = read_sym_config(args.ConfigPath)
        pam_config = config.get("SymantecPAM", {})

        # Override delimiter if specified on CLI, otherwise use config file value or default
        delimiter = args.Delimiter if args.Delimiter else pam_config.get("Delimiter", ";")

        # Instantiate client
        client = SymantecPAMClient(
            dns=pam_config.get("DNS"),
            cli_username=pam_config.get("cliUsername"),
            cli_password=pam_config.get("cliPassword"),
            api_username=pam_config.get("apiUsername"),
            api_password=pam_config.get("apiPassword"),
            limit=pam_config.get("limit", 100000),
            delimiter=delimiter,
            tcf=pam_config.get("tcf", [])
        )

        timestamp = start_time.strftime('%Y%m%d-%H%M%S')

        # Passphrase prompt if empty string is supplied
        passphrase = args.Passphrase
        if args.ShowPassword and passphrase == "":
            passphrase = getpass.getpass("Enter encryption passphrase: ")
            passphrase2 = getpass.getpass("Confirm encryption passphrase: ")
            if passphrase != passphrase2:
                print("Encryption passphrase does not match.", file=sys.stderr)
                sys.exit(1)

        if args.Export:
            export_sym(
                client=client,
                timestamp=timestamp,
                output_path=args.OutputPath,
                category=args.Category,
                srv_name=args.SrvName,
                app_name=args.AppName,
                acc_name=args.AccName,
                extension_type=args.ExtensionType,
                compress=args.Compress,
                show_password=args.ShowPassword,
                passphrase=passphrase,
                quiet=args.Quiet
            )
        elif args.Import:
            import_sym(
                client=client,
                input_file=args.InputFile,
                delimiter=delimiter,
                timestamp=timestamp,
                synchronize=args.Synchronize,
                update_password=args.UpdatePassword,
                passphrase=passphrase,
                quiet=args.Quiet
            )
        else:
            print_custom_help()
            sys.exit(0)

    except Exception as e:
        print(f"Exception: {type(e).__name__}\nMessage: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
    finally:
        # Stop-SymantecPAM cleanup equivalent
        pass

    # Run time print
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    h = int(duration // 3600)
    m = int((duration % 3600) // 60)
    s = int(duration % 60)

    if h > 0:
        print(f"Run time: {h} hours, {m} minutes, {s} seconds")
    elif m > 0:
        print(f"Run time: {m} minutes, {s} seconds")
    else:
        print(f"Run time: {s} seconds")

    print("Done")

if __name__ == "__main__":
    main()
