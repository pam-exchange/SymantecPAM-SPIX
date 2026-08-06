# operations.py
import os
import csv
import socket
import getpass
from datetime import datetime

from .exceptions import SymantecPamException, EXCEPTION_INVALID_PARAMETER, DETAILS_EXCEPTION_CANNOT_IMPORT_02
from .crypto import encrypt_pbkdf2, decrypt_pbkdf2

def match_wildcard(value, pattern, use_regex=False):
    from .client import match_wildcard as mw
    return mw(value, pattern, use_regex)


def export_sym_generic(client, object_type, list_data, timestamp, fixed_columns, ignore_columns, output_path=".\\SPIX-Output", delimiter=";", extension=None):
    if not list_data:
        return

    if not timestamp:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    filename = f"{object_type}"
    if extension:
        filename += f"-{extension}"
    filename += f"-{timestamp}.csv"

    out_filepath = os.path.join(output_path, filename)
    os.makedirs(output_path, exist_ok=True)

    # Sort by ID
    sorted_list = sorted(list_data, key=lambda x: int(x.get("ID", 0)))

    # Map 't' / 'f' values to true/false
    for obj in sorted_list:
        for k, v in list(obj.items()):
            if str(v).lower() == 't':
                obj[k] = 'true'
            elif str(v).lower() == 'f':
                obj[k] = 'false'

    # Determine all columns across the list
    all_columns_set = set()
    for obj in sorted_list:
        all_columns_set.update(obj.keys())

    all_columns = [col for col in all_columns_set if col not in ignore_columns]

    fixed_cols = [col for col in fixed_columns if col in all_columns]
    attribute_cols = sorted([col for col in all_columns if col.startswith("Attribute.") and col not in fixed_cols])
    other_cols = sorted([col for col in all_columns if not col.startswith("Attribute.") and col not in fixed_cols])

    column_order = fixed_cols + other_cols + attribute_cols

    with open(out_filepath, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=column_order, delimiter=delimiter, extrasaction='ignore')
        writer.writeheader()
        for obj in sorted_list:
            writer.writerow(obj)


def export_sym_target_application(client, list_data, timestamp, fixed_columns, ignore_columns, output_path=".\\SPIX-output", compress=False, delimiter=";", quiet=False):
    if not list_data:
        return

    if not timestamp:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    if compress:
        filename = f"TargetApplication-{timestamp}.csv"
        out_filepath = os.path.join(output_path, filename)
        os.makedirs(output_path, exist_ok=True)
        column_order = ['ID', 'ObjectType', 'Action', 'ExtensionType', 'deviceName', 'hostname', 'name']

        sorted_list = sorted(list_data, key=lambda x: int(x.get("ID", 0)))
        with open(out_filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=column_order, delimiter=delimiter, extrasaction='ignore')
            writer.writeheader()
            for obj in sorted_list:
                writer.writerow(obj)
        return

    # Group by extensionType
    extensions = sorted(list(set(obj.get("extensionType", "Generic") for obj in list_data)))
    for ext in extensions:
        csv_list = [obj.copy() for obj in list_data if obj.get("extensionType", "Generic") == ext]
        if not csv_list:
            continue

        ext_label = "Generic" if ext == "" else ext
        if not quiet:
            print(f"... {ext_label}")

        for obj in csv_list:
            # Resolve PCP
            policy_id = int(obj.get("policyID", -1))
            try:
                pcp = client.get_pcp(id=policy_id, single=True)
                obj["PCP"] = pcp.get("name") or pcp.get("Name") or ""
            except Exception:
                obj["PCP"] = ""

            # Resolve extension-specific fields
            if ext == 'windows':
                proxy_list = []
                agent_ids = str(obj.get("Attribute.agentId", "")).split(",")
                for agent_id in agent_ids:
                    agent_id = agent_id.strip()
                    if agent_id:
                        try:
                            srv = client.get_target_server(id=int(agent_id), single=True)
                            proxy_list.append(srv.get("hostname", ""))
                        except Exception:
                            pass
                obj["Attribute.Proxy"] = " | ".join(proxy_list)

            elif ext in ('activeDirectorySshKey', 'unixII', 'windowsSshKey'):
                obj["Attribute.sshKeyPairPolicy"] = ""
                kp_id = obj.get("Attribute.sshKeyPairPolicyID")
                if kp_id:
                    try:
                        kp = client.get_ssh_key_pair_policy(id=int(kp_id), single=True)
                        obj["Attribute.sshKeyPairPolicy"] = kp.get("name") or kp.get("Name") or ""
                    except Exception:
                        pass

            elif ext in ('mssql', 'mssqlAzureMI'):
                obj["Attribute.customWorkflow"] = ""
                cw_id = obj.get("Attribute.customWorkflowId")
                if cw_id:
                    try:
                        cw = client.get_custom_workflow(id=int(cw_id), single=True)
                        obj["Attribute.customWorkflow"] = cw.get("name") or cw.get("Name") or ""
                    except Exception:
                        pass

        export_sym_generic(client, "TargetApplication", csv_list, timestamp, fixed_columns, ignore_columns, output_path, delimiter, extension=ext_label)


def export_sym_target_account(client, list_data, timestamp, fixed_columns, ignore_columns, output_path=".\\SPIX-output", show_password=False, passphrase="", compress=False, delimiter=";", quiet=False):
    if not list_data:
        return

    if not timestamp:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    if compress:
        filename = f"TargetAccount-{timestamp}.csv"
        out_filepath = os.path.join(output_path, filename)
        os.makedirs(output_path, exist_ok=True)
        column_order = ['ID', 'ObjectType', 'Action', 'ExtensionType', 'deviceName', 'hostname', 'targetApplicationName', 'username']

        sorted_list = sorted(list_data, key=lambda x: int(x.get("ID", 0)))
        with open(out_filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=column_order, delimiter=delimiter, extrasaction='ignore')
            writer.writeheader()
            for obj in sorted_list:
                writer.writerow(obj)
        return

    # Group by extensionType
    extensions = sorted(list(set(obj.get("extensionType", "Generic") for obj in list_data)))
    for ext in extensions:
        csv_list = [obj.copy() for obj in list_data if obj.get("extensionType", "Generic") == ext]
        if not csv_list:
            continue

        ext_label = "Generic" if ext == "" else ext
        if not quiet:
            print(f"... {ext_label}")

        # Resolve compoundServers
        for obj in csv_list:
            cs_ids = obj.get("compoundServerIDs", "")
            if cs_ids:
                cs_list = []
                for tsid in cs_ids.strip(",").split(","):
                    tsid = tsid.strip()
                    if tsid:
                        try:
                            ts = client.get_target_account(id=int(tsid), single=True)
                            cs_list.append(ts.get("hostname", ""))
                        except Exception:
                            pass
                obj["compoundServerList"] = " | ".join(cs_list)

        # Resolve Password
        if show_password:
            for obj in csv_list:
                try:
                    pwd = client.get_target_account_password(obj["ID"], unattended=True)
                    if passphrase:
                        pwd = "{enc}" + encrypt_pbkdf2(pwd, passphrase)
                    obj["Password"] = pwd
                except Exception:
                    obj["Password"] = ""

        # Replace 'otherAccount' IDs with reference details
        ref_fields = ('Attribute.otherAccount', 'Attribute.loginAccount', 'Attribute.otherPrivilegedAccount', 'Attribute.anotherAccount')
        for obj in csv_list:
            for k in ref_fields:
                val = obj.get(k)
                if val and str(val) != "-1":
                    try:
                        oth = client.get_target_account(id=int(val), single=True)
                        oth_str = f"{oth.get('Hostname', '')} | {oth.get('TargetApplicationName', '')} | {oth.get('userName', '')}"
                        obj[k] = oth_str
                    except Exception:
                        pass
                elif str(val) == "-1":
                    obj[k] = ""

        export_sym_generic(client, "TargetAccount", csv_list, timestamp, fixed_columns, ignore_columns, output_path, delimiter, extension=ext_label)


def decode_other_account(client, property_val):
    if not property_val:
        return -1
    parts = [p.strip() for p in property_val.split('|')]
    if len(parts) == 3:
        try:
            srv = client.get_target_server(hostname=parts[0], single=True, no_empty_set=True)
            app = client.get_target_application(target_server_id=srv["ID"], name=parts[1], single=True, no_empty_set=True)
            acc = client.get_target_account(target_application_id=app["ID"], username=parts[2], single=True, no_empty_set=True)
            return acc["ID"]
        except Exception:
            return -1
    return -1


def is_built_in_extension_type(ext_type):
    built_ins = (
        'activeDirectorySshKey', 'AwsAccessCredentials', 'AwsApiProxyCredentials', 'AzureAccessCredentials',
        'AS400', 'CiscoSSH', 'Generic', 'HPServiceManager', 'juniper', 'ldap', 'mssql', 'mssqlAzureMI', 'mysql',
        'nsxcontroller', 'nsxmanager', 'nsxproxy', 'oracle', 'PaloAlto', 'RadiusTacacsSecret', 'remedy',
        'ServiceDeskBroker', 'ServiceNow', 'SPML2', 'sybase', 'unixII', 'vcf', 'vmware', 'weblogic10', 'windows',
        'windowsDomainService', 'windowsRemoteAgent', 'windowsSshKey', 'windowsSshPassword', 'XsuiteApiKey'
    )
    return ext_type in built_ins


def import_sym_target_application(client, input_csv):
    failed_import = []
    donotimport = ('AzureAccessCredentials', 'AwsApiProxyCredentials', 'AwsAccessCredentials', 'nsxcontroller', 'nsxmanager', 'nsxproxy')

    for row in input_csv:
        action = str(row.get("Action") or row.get("action") or "").strip()
        if action.lower() not in ('update', 'new'):
            continue

        ext_type = row.get("ExtensionType") or row.get("extensionType") or ""
        if ext_type in donotimport:
            row["ErrorMessage"] = f"Cannot import extension type '{ext_type}'"
            failed_import.append(row)
            continue

        params = row.copy()
        if "ObjectType" in params:
            del params["ObjectType"]
        if "deviceName" in params:
            del params["deviceName"]

        if params.get("hostname"):
            params["TargetServer.hostName"] = params["hostname"]

        if params.get("PCP"):
            try:
                pcp = client.get_pcp(name=params["PCP"], single=True, no_empty_set=True)
                params["PasswordPolicy.ID"] = pcp["ID"]
            except Exception as e:
                row["ErrorMessage"] = f"PCP Error: {e}"
                failed_import.append(row)
                continue

        # Normalize attributes
        for k in list(params.keys()):
            if k.startswith("Attribute."):
                if str(params[k]).upper() in ("TRUE", "FALSE"):
                    params[k] = str(params[k]).lower()

        # Extension-specific mapping
        try:
            if ext_type == 'activeDirectorySshKey':
                kp_name = params.get("Attribute.sshKeyPairPolicy")
                if kp_name:
                    kp = client.get_ssh_key_pair_policy(name=kp_name, single=True, no_empty_set=True)
                    params["Attribute.sshKeyPairPolicyID"] = kp["ID"]
                    del params["Attribute.sshKeyPairPolicy"]

            elif ext_type == 'CiscoSSH':
                for field in ("Attribute.useUpdateScriptType", "Attribute.useVerifyScriptType", "Attribute.protocol"):
                    if params.get(field):
                        params[field] = str(params[field]).upper()
                if params.get("Attribute.pwType"):
                    params["Attribute.pwType"] = str(params["Attribute.pwType"]).lower()

            elif ext_type in ('juniper', 'oracle', 'vmware', 'weblogic10', 'windowsRemoteAgent', 'windowsSshPassword'):
                params["Attribute.extensionType"] = ext_type

            elif ext_type == 'ldap':
                if params.get("Attribute.protocol"):
                    params["Attribute.protocol"] = str(params["Attribute.protocol"]).lower()

            elif ext_type in ('mssql', 'mssqlAzureMI'):
                params["Attribute.extensionType"] = ext_type
                cw_name = params.get("Attribute.customWorkflow")
                if cw_name:
                    cw = client.get_custom_workflow(name=cw_name, single=True, no_empty_set=True)
                    params["Attribute.customWorkflowId"] = cw["ID"]
                    del params["Attribute.customWorkflow"]

            elif ext_type == 'ServiceNow':
                if params.get("Attribute.serviceNowApiType"):
                    params["Attribute.serviceNowApiType"] = str(params["Attribute.serviceNowApiType"]).upper()
                if params.get("Attribute.serviceNowAuthType"):
                    params["Attribute.serviceNowAuthType"] = str(params["Attribute.serviceNowAuthType"]).upper()

            elif ext_type == 'SPML2':
                params["Attribute.extensionType"] = ext_type
                if params.get("Attribute.protocol"):
                    params["Attribute.protocol"] = str(params["Attribute.protocol"]).lower()

            elif ext_type == 'unixII':
                params["Attribute.extensionType"] = ext_type
                kp_name = params.get("Attribute.sshKeyPairPolicy")
                if kp_name:
                    kp = client.get_ssh_key_pair_policy(name=kp_name, single=True, no_empty_set=True)
                    params["Attribute.sshKeyPairPolicyID"] = kp["ID"]
                    del params["Attribute.sshKeyPairPolicy"]

            elif ext_type == 'windows':
                params["Attribute.extensionType"] = ext_type
                proxies = str(params.get("Attribute.proxy", "")).split("|")
                proxy_ids = []
                for p in proxies:
                    p = p.strip()
                    if p:
                        srv = client.get_target_server(hostname=p, single=True)
                        proxy_ids.append(str(srv["ID"]))
                params["Attribute.agentId"] = ",".join(proxy_ids)

            elif ext_type == 'windowsSshKey':
                params["Attribute.extensionType"] = ext_type
                kp_name = params.get("Attribute.sshKeyPairPolicy")
                if kp_name:
                    kp = client.get_ssh_key_pair_policy(name=kp_name, single=True, no_empty_set=True)
                    params["Attribute.sshKeyPairPolicyID"] = kp["ID"]
                    del params["Attribute.sshKeyPairPolicy"]

            client.sync_target_application(params)
        except Exception as e:
            row["ErrorMessage"] = str(e)
            failed_import.append(row)

    return failed_import


def import_sym_target_account(client, input_csv, update_password=False, passphrase=""):
    failed_import = []

    for row in input_csv:
        action = str(row.get("Action") or row.get("action") or "").strip()
        if action.lower() not in ('update', 'new', 'remove'):
            continue

        params = row.copy()
        # Exclude specific properties
        for key in ('cacheAllow', 'ObjectType', 'deviceName', 'PasswordVerified', 'Attribute.isProvisionedAccount'):
            if key in params:
                del params[key]

        ext_type = params.get("extensionType") or params.get("ExtensionType") or ""

        try:
            # Decode otherAccount/anotherAccount references
            if ext_type in (
                'AwsAccessCredentials', 'AS400', 'CiscoSSH', 'HPServiceManager', 'juniper', 'ldap', 'mssql', 'mssqlAzureMI',
                'mysql', 'oracle', 'PaloAlto', 'remedy', 'ServiceDeskBroker', 'SPML2', 'sybase', 'unixII', 'vmware', 'weblogic10',
                'windows', 'windowsDomainService', 'windowsRemoteAgent', 'XsuiteApiKey'
            ):
                if params.get("Attribute.otherAccount"):
                    params["Attribute.otherAccount"] = decode_other_account(client, params["Attribute.otherAccount"])
                    params["Attribute.useOtherAccountToChangePassword"] = 'true'
                else:
                    params["Attribute.useOtherAccountToChangePassword"] = 'false'

            if ext_type in (
                'juniper', 'SPML2', 'sybase', 'vmware', 'weblogic10', 'windowsDomainService', 'windowsRemoteAgent', 'XsuiteApiKey'
            ):
                params["Attribute.extensionType"] = ext_type

            if ext_type in ('activeDirectorySshKey', 'vcf'):
                if params.get("Attribute.anotherAccount"):
                    params["Attribute.anotherAccount"] = decode_other_account(client, params["Attribute.anotherAccount"])

            elif ext_type == 'AwsAccessCredentials':
                if params.get("Attribute.awsCredentialType"):
                    params["Attribute.awsCredentialType"] = str(params["Attribute.awsCredentialType"]).upper()

            elif ext_type == 'CiscoSSH':
                if params.get("Attribute.protocol"):
                    params["Attribute.protocol"] = str(params["Attribute.protocol"]).upper()
                if params.get("Attribute.pwType"):
                    params["Attribute.pwType"] = str(params["Attribute.pwType"]).lower()
                if params.get("Attribute.otherPrivilegedAccount"):
                    params["Attribute.otherPrivilegedAccount"] = decode_other_account(client, params["Attribute.otherPrivilegedAccount"])
                    params["Attribute.useOtherPrivilegedAccount"] = 'true'
                else:
                    params["Attribute.useOtherPrivilegedAccount"] = 'false'

            elif ext_type == 'unixII':
                if params.get("Attribute.passwordChangeMethod"):
                    params["Attribute.passwordChangeMethod"] = str(params["Attribute.passwordChangeMethod"]).upper()
                if params.get("Attribute.protocol"):
                    params["Attribute.protocol"] = str(params["Attribute.protocol"]).upper()

            elif ext_type == 'windowsRemoteAgent':
                if params.get("Attribute.accountType"):
                    params["Attribute.accountType"] = str(params["Attribute.accountType"]).lower()

            elif ext_type == 'windowsSshKey':
                if params.get("Attribute.changeProcess"):
                    params["Attribute.changeProcess"] = str(params["Attribute.changeProcess"]).upper()
                if params.get("Attribute.protocol"):
                    params["Attribute.protocol"] = str(params["Attribute.protocol"]).upper()

            elif ext_type == 'windowsSshPassword':
                if params.get("Attribute.changeProcess"):
                    params["Attribute.changeProcess"] = str(params["Attribute.changeProcess"]).upper()

            # TCF loginAccount / otherAccount reference mapping
            if not is_built_in_extension_type(ext_type):
                for key in ("Attribute.loginAccount", "Attribute.otherAccount"):
                    if params.get(key) and "|" in str(params[key]):
                        params[key] = decode_other_account(client, params[key])

            # Decrypt password
            pwd = params.get("password") or params.get("Password") or ""
            if pwd.startswith("{enc}"):
                params["password"] = decrypt_pbkdf2(pwd[5:], passphrase)

            res = client.sync_target_account(params)

            # Post-creation Password update
            if update_password and action.lower() == 'new' and row.get("password") and row["password"] != '_generate_pass_':
                update_params = res.copy()
                update_params["Action"] = "update"
                update_params["password"] = "_generate_pass_"
                client.sync_target_account(update_params)

        except Exception as e:
            row["ErrorMessage"] = str(e)
            failed_import.append(row)

    return failed_import


def import_sym_generic(client, input_csv):
    failed_import = []

    for row in input_csv:
        action = str(row.get("Action") or row.get("action") or "").strip()
        if action.lower() not in ('new', 'update', 'remove'):
            continue

        obj_type = row.get("ObjectType") or row.get("objectType") or ""
        try:
            if obj_type == 'Authorization':
                client.sync_authorization(row)
            elif obj_type == 'RequestServer':
                client.sync_request_server(row)
            elif obj_type == 'RequestScript':
                client.sync_request_script(row)
            elif obj_type == 'TargetServer':
                client.sync_target_server(row)
            elif obj_type == 'PCP':
                client.sync_pcp(row)
            elif obj_type == 'Proxy':
                client.sync_proxy(row)
            elif obj_type == 'PVP':
                client.sync_pvp(row)
            elif obj_type == 'Group':
                client.sync_group(row)
            elif obj_type == 'Role':
                client.sync_role(row)
            elif obj_type == 'SSHKeyPairPolicy':
                client.sync_ssh_key_pair_policy(row)
        except Exception as e:
            row["ErrorMessage"] = str(e)
            failed_import.append(row)

    return failed_import


def export_sym(client, timestamp=None, output_path=".\\SPIX-output", category="ALL", srv_name="", app_name="", acc_name="", extension_type="", compress=False, show_password=False, passphrase="", quiet=False):
    if not timestamp:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    os.makedirs(output_path, exist_ok=True)
    categories = [category] if isinstance(category, str) else list(category)
    if "ALL" in categories:
        categories = ["TargetServer", "TargetApplication", "TargetAccount", "RequestServer", "RequestScript", "Authorization", "Proxy", "PCP", "PVP", "SSHKeyPairPolicy", "CustomWorkflow", "Filter", "Group", "Role", "User", "UserGroup", "Vault", "VaultSecret", "AccessPolicy", "Service", "Device"]

    # Standardize options (expand grouped categories like Target, A2A, Policy, UserGroup, Secret)
    expanded = []
    for cat in categories:
        if cat == 'Target':
            expanded.extend(['TargetServer', 'TargetApplication', 'TargetAccount'])
        elif cat == 'A2A':
            expanded.extend(['RequestServer', 'RequestScript', 'Authorization'])
        elif cat == 'Policy':
            expanded.extend(['PCP', 'PVP', 'SSHKeyPairPolicy', 'CustomWorkflow'])
        elif cat == 'UserGroup':
            expanded.extend(['Filter', 'Group', 'Role', 'User', 'UserGroup'])
        elif cat == 'Secret':
            expanded.extend(['Vault', 'VaultSecret'])
        else:
            expanded.append(cat)

    # Process each expanded category
    for cat in expanded:
        if cat == 'TargetServer':
            if not quiet:
                print("Exporting TargetServer")
            data = client.get_target_server(hostname=srv_name)
            fixed = ['ID', 'ObjectType', 'Action', 'deviceName', 'hostname', 'ipAddress', 'Attribute.descriptor1', 'Attribute.descriptor2']
            ignore = ['deviceId']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'TargetApplication':
            if not quiet:
                print("Exporting TargetApplication")
            data = client.get_target_application(hostname=srv_name, name=app_name, type=extension_type)
            fixed = ['ID', 'ObjectType', 'Action', 'ExtensionType', 'deviceName', 'hostname', 'name', 'PCP', 'Attribute.descriptor1', 'Attribute.descriptor2']
            ignore = ['deviceId', 'policyID', 'TargetServerID', 'overrideDnsType', 'Attribute.agentId', 'Attribute.sshKeyPairPolicyID', 'Attribute.customWorkflowId']
            export_sym_target_application(client, data, timestamp, fixed, ignore, output_path, compress, delimiter=client.delimiter, quiet=quiet)

        elif cat == 'TargetAccount':
            if not quiet:
                print("Exporting TargetAccount")
            data = client.get_target_account(hostname=srv_name, target_application_name=app_name, username=acc_name, type=extension_type)
            fixed = ['ID', 'ObjectType', 'Action', 'ExtensionType', 'deviceName', 'hostname', 'targetApplicationName', 'username', 'password']
            ignore = ['cacheAllowed', 'cacheBehaviorInt', 'compoundAccount', 'compoundServerIDs', 'ownerUserID', 'passwordViewPolicyID', 'parentAccountId', 'Privileged', 'ServerkeyID', 'TargetApplication', 'TargetApplicationID', 'TargetServerAlias', 'TargetServerID', 'Attribute.useOtherAccountToChangePassword']
            export_sym_target_account(client, data, timestamp, fixed, ignore, output_path, show_password, passphrase, compress, delimiter=client.delimiter, quiet=quiet)

        elif cat == 'RequestServer':
            if not quiet:
                print("Exporting RequestServer")
            data = client.get_request_server()
            fixed = ['ID', 'ObjectType', 'Action', 'deviceName', 'hostname', 'ipAddress', 'Attribute.descriptor1', 'Attribute.descriptor2']
            ignore = ['deviceId', 'serverKeyId', 'SiteID']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'RequestScript':
            if not quiet:
                print("Exporting RequestScript")
            data = client.get_request_script()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'RequestServer', 'type']
            ignore = ['deviceID', 'RequestServerID']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Authorization':
            if not quiet:
                print("Exporting Authorization")
            data = client.get_authorization()
            fixed = ['ID', 'ObjectType', 'Action', 'Target', 'Request', 'Script', 'checkExecutionID', 'executionUser']
            ignore = ['targetAlias', 'requestGroupID', 'requestServerID', 'scriptID', 'targetAliasID', 'targetGroupID', 'requestServer']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Proxy':
            if not quiet:
                print("Exporting Proxy")
            data = client.get_proxy()
            fixed = ['ID', 'ObjectType', 'Action', 'deviceName', 'hostname', 'ipAddress']
            ignore = ['serverKeyId', 'SiteID', 'pendingAcknowledgement', 'currentKey', 'oldKey', 'lastDigestLoginDate', 'lastPatchStatusChangeDate']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'PCP':
            if not quiet:
                print("Exporting PCP")
            data = client.get_pcp()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'type', 'Description']
            ignore = []
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'PVP':
            if not quiet:
                print("Exporting PVP")
            data = client.get_pvp()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'Description']
            ignore = ['approverIDs', 'emailNotificationUserIDs']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'SSHKeyPairPolicy':
            if not quiet:
                print("Exporting SSHKeyPairPolicy")
            data = client.get_ssh_key_pair_policy()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'Description', 'Attribute.keyType', 'Attribute.keyLength']
            ignore = ['SSHKeyType', 'SSHKeyLength', 'type']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'CustomWorkflow':
            if not quiet:
                print("Exporting CustomWorkflow")
            data = client.get_custom_workflow()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'applicationType', 'Description']
            ignore = []
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Filter':
            if not quiet:
                print("Exporting Filter")
            data = client.get_filter()
            fixed = ['ID', 'ObjectType', 'Action']
            ignore = ['groupID']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Group':
            if not quiet:
                print("Exporting Group")
            data = client.get_group()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'Description']
            ignore = ['readOnly']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Role':
            if not quiet:
                print("Exporting Role")
            data = client.get_role()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'Description']
            ignore = ['Readonly']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'User':
            if not quiet:
                print("Exporting User")
            data = client.get_user()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'Description']
            ignore = ['serverKeyId', 'userGroupIDs', 'userID']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'UserGroup':
            if not quiet:
                print("Exporting UserGroup")
            data = client.get_user_group()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'description', 'targetGroup', 'requestorGroup', 'role']
            ignore = ['groups', 'readOnly', 'groupIDs', 'roleID']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Vault':
            if not quiet:
                print("Exporting Vault")
            data = client.get_vault()
            fixed = ['ID', 'ObjectType', 'Action', 'name', 'description']
            ignore = []
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'VaultSecret':
            if not quiet:
                print("Exporting VaultSecret")
            data = client.get_vault_secret()
            fixed = ['ID', 'ObjectType', 'Action', 'vaultName', 'name', 'aliases', 'SecretTypeName', 'value', 'format', 'firstDescriptor', 'secondDescriptor']
            ignore = ['ServerKeyID', 'extensionType']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'AccessPolicy':
            if not quiet:
                print("Exporting AccessPolicy")
            data = client.get_access_policy()
            fixed = ['ID', 'ObjectType', 'Action', 'User', 'Device']
            ignore = []
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Service':
            if not quiet:
                print("Exporting Service")
            data = client.get_service()
            fixed = ['ID', 'ObjectType', 'Action', 'Name', 'ServiceType', 'localIP', 'ports', 'comments']
            ignore = []
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)

        elif cat == 'Device':
            if not quiet:
                print("Exporting Device")
            data = client.get_device()
            fixed = ['ID', 'ObjectType', 'Action', 'Name']
            ignore = ['deviceId', 'deviceName', 'deviceGroupMembership']
            export_sym_generic(client, cat, data, timestamp, fixed, ignore, output_path, delimiter=client.delimiter)


def import_sym(client, input_file, delimiter=None, timestamp=None, synchronize=False, update_password=False, passphrase="", quiet=False):
    if not input_file:
        raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, DETAILS_EXCEPTION_CANNOT_IMPORT_02)

    if not timestamp:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    if not delimiter:
        delimiter = client.delimiter if client.delimiter else ";"

    dir_name = os.path.dirname(input_file)
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    ext_name = os.path.splitext(os.path.basename(input_file))[1]
    failed_filename = f"{base_name}_Error-{timestamp}{ext_name}"
    failed_filepath = os.path.join(dir_name, failed_filename)

    # Read rows from CSV
    rows = []
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter=delimiter)
        for r in reader:
            if r.get("ObjectType"):
                rows.append(r)

    # Unique object types
    obj_types = sorted(list(set(r.get("ObjectType") for r in rows)))

    all_failed = []
    for t in obj_types:
        failed = []
        if t == 'TargetAccount':
            failed = import_sym_target_account(client, rows, update_password, passphrase)
        elif t == 'TargetApplication':
            failed = import_sym_target_application(client, rows)
        elif t in ('Authorization', 'RequestServer', 'RequestScript', 'TargetServer', 'PCP', 'Proxy', 'PVP', 'Group', 'Role', 'SSHKeyPairPolicy'):
            failed = import_sym_generic(client, rows)

        all_failed.extend(failed)

    if all_failed:
        if not quiet:
            print(f"Import with errors. See the file '{failed_filepath}' for details.")

        # Write error csv
        # Determine error headers dynamically
        all_keys = set()
        for r in all_failed:
            all_keys.update(r.keys())
        all_keys.add("ErrorMessage")
        fieldnames = sorted(list(all_keys))

        with open(failed_filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter=delimiter)
            writer.writeheader()
            for r in all_failed:
                writer.writerow(r)

    return len(all_failed) == 0
