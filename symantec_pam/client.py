# client.py
import urllib.request
import urllib.parse
import ssl
import json
import xml.etree.ElementTree as ET
import re
import fnmatch
import threading

from .exceptions import (
    SymantecPamException,
    EXCEPTION_INVALID_PARAMETER,
    EXCEPTION_NOT_FOUND,
    EXCEPTION_NOT_AUTHORIZED,
    EXCEPTION_NOT_SINGLE,
    EXCEPTION_PASSWORD_UPDATE,
    EXCEPTION_DUPLICATE,
    EXCAPTION_MISSING_TCF,
    DETAILS_EXCEPTION_NOT_AUTHORIZED_01,
    DETAILS_EXCEPTION_TCF_01,
    DETAILS_EXCEPTION_NOT_FOUND_02,
    DETAILS_EXCEPTION_NOT_SINGLE_02,
    DETAILS_EXCEPTION_INVALID_PARAMETER_01,
    DETAILS_EXCEPTION_DUPLICATE_SERVER_01,
    DETAILS_EXCEPTION_DUPLICATE_PCP_01,
    DETAILS_EXCEPTION_DUPLICATE_PVP_01,
    DETAILS_EXCEPTION_DUPLICATE_GROUP_01,
    DETAILS_EXCEPTION_DUPLICATE_ROLE_01,
    DETAILS_EXCEPTION_DUPLICATE_SSHKEYPAIR_01,
    DETAILS_EXCEPTION_DUPLICATE_REQUESSCRIPT_01,
    DETAILS_EXCEPTION_DUPLICATE_VAULT_01,
    DETAILS_EXCEPTION_DUPLICATE_VAULTSECRET_01,
    DETAILS_EXCEPTION_DUPLICATE_APPL_01,
    DETAILS_EXCEPTION_NOT_FOUND_PCP_01,
    DETAILS_EXCEPTION_NOT_FOUND_PCP_02,
    DETAILS_EXCEPTION_NOT_FOUND_SERVICE_01,
    DETAILS_EXCEPTION_NOT_FOUND_SERVICE_02,
    DETAILS_EXCEPTION_NOT_FOUND_TARGETSERVER_01,
    DETAILS_EXCEPTION_NOT_FOUND_TARGETAPPLICATION_01
)

# Bypass SSL verification
SSL_CONTEXT = ssl._create_unverified_context()

def match_wildcard(value, pattern, use_regex=False):
    if value is None:
        value = ""
    if pattern is None or pattern == "":
        return True
    if use_regex:
        try:
            return bool(re.search(pattern, str(value), re.IGNORECASE))
        except re.error:
            return False
    else:
        return fnmatch.fnmatchcase(str(value).lower(), str(pattern).lower())


def convert_xml_to_dict(element, filter_regex='^(?!hash|update.+|create.+|last.+)'):
    """
    Parses child nodes of an XML element into a flat dictionary, filtering by tag name.
    """
    res = {}
    pattern = re.compile(filter_regex)
    for child in element:
        if pattern.match(child.tag):
            # If child has nested tags or is CDATA, we can inspect text
            res[child.tag] = child.text if child.text is not None else ""
    return res


class SymantecPAMClient:
    def __init__(self, dns, cli_username, cli_password, api_username, api_password, limit=100000, delimiter=";", tcf=None):
        self.dns = dns
        self.cli_username = cli_username
        self.cli_password = cli_password
        self.api_username = api_username
        self.api_password = api_password
        self.limit = int(limit)
        self.delimiter = delimiter
        self.tcf = tcf or []

        self.cli_url = f"https://{dns}/cspm/servlet/adminCLI"
        self.api_url = f"https://{dns}"

        # Base64 Auth header for REST API
        import base64
        auth_str = f"{api_username}:{api_password}"
        encoded_auth = base64.b64encode(auth_str.encode('ascii')).decode('ascii')
        self.api_headers = {
            'Authorization': f'Basic {encoded_auth}',
            'Content-Type': 'application/json'
        }

        # Thread locks & caching
        self._locks = {}
        self._locks_lock = threading.Lock()

        self.caches = {
            "TargetServer": [],
            "TargetApplication": [],
            "TargetAccount": [],
            "RequestServer": [],
            "RequestScript": [],
            "Authorization": [],
            "Proxy": [],
            "PCP": [],
            "PVP": [],
            "SSHKeyPairPolicy": [],
            "CustomWorkflow": [],
            "Filter": [],
            "Group": [],
            "Role": [],
            "User": [],
            "UserGroup": [],
            "Vault": [],
            "VaultSecret": [],
            "AccessPolicy": [],
            "Service": [],
            "Device": []
        }

        self.cache_by_id = {k: {} for k in self.caches.keys()}

    def _protected_operation(self, resource_name, operation_func):
        with self._locks_lock:
            if resource_name not in self._locks:
                self._locks[resource_name] = threading.Lock()
            lock = self._locks[resource_name]
        with lock:
            return operation_func()

    def _invoke_cli(self, cmd, params=None):
        """
        Invokes Symantec CLI servlet via HTTP GET. Parses response XML.
        """
        query_params = {
            'cmdName': cmd,
            'adminUserID': self.cli_username,
            'adminPassword': self.cli_password,
            'Page.Size': self.limit
        }
        if params:
            for k, v in params.items():
                query_params[k] = v

        # URL encode and build request
        url = f"{self.cli_url}?{urllib.parse.urlencode(query_params)}"
        req = urllib.request.Request(url, method='GET')

        try:
            with urllib.request.urlopen(req, context=SSL_CONTEXT) as response:
                resp_bytes = response.read()
        except urllib.error.URLError as e:
            raise SymantecPamException(EXCEPTION_NOT_FOUND, str(e))

        try:
            root = ET.fromstring(resp_bytes)
        except ET.ParseError as pe:
            raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, f"Failed to parse XML response: {pe}")

        status_code_elem = root.find('.//statusCode')
        status_code = int(status_code_elem.text) if status_code_elem is not None else 0
        status_msg_elem = root.find('.//statusMessage')
        status_msg = status_msg_elem.text if status_msg_elem is not None else ""
        content_elem = root.find('.//content')
        content_text = content_elem.text if content_elem is not None else ""

        if status_code == 400:
            if content_text:
                try:
                    cdata_root = ET.fromstring(content_text)
                    return cdata_root
                except ET.ParseError as pe:
                    raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, f"Failed to parse CDATA XML: {pe}")
            # Empty successful result
            return ET.Element("CommandResult")

        if status_code in (401, 22):
            details = DETAILS_EXCEPTION_NOT_AUTHORIZED_01.format(self.cli_username)
            raise SymantecPamException(EXCEPTION_NOT_AUTHORIZED, details)
        elif status_code in (5753, 15212):
            raise SymantecPamException(EXCEPTION_PASSWORD_UPDATE, status_msg)
        elif status_code == 0 and "PAM-CF-0001" in content_text:
            raise SymantecPamException(EXCAPTION_MISSING_TCF, DETAILS_EXCEPTION_TCF_01)
        else:
            match = re.search(r"<cr\.statusDescription>(.*?)</cr\.statusDescription>", content_text)
            details = match.group(1) if match else status_msg
            raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, details)

    def _invoke_api(self, cmd, method='GET', params=None, body_data=None):
        """
        Invokes REST API and returns parsed JSON.
        """
        url = f"{self.api_url}/{cmd.lstrip('/')}"
        if params:
            url += f"?{urllib.parse.urlencode(params)}"

        req = urllib.request.Request(url, headers=self.api_headers, method=method)
        if body_data is not None:
            if isinstance(body_data, (dict, list)):
                req.data = json.dumps(body_data).encode('utf-8')
            else:
                req.data = str(body_data).encode('utf-8')

        try:
            with urllib.request.urlopen(req, context=SSL_CONTEXT) as response:
                resp_bytes = response.read()
                if resp_bytes:
                    return json.loads(resp_bytes.decode('utf-8'))
                return {}
        except Exception as e:
            raise SymantecPamException(EXCEPTION_NOT_FOUND, str(e))

    # --- GETTERS ---

    def _get_filtered(self, category, id_val, single, no_empty_set, filter_func, caller_name):
        res = self.caches[category]
        if id_val >= 0:
            item = self.cache_by_id[category].get(int(id_val))
            res = [item] if item is not None else []
        else:
            res = filter_func(res)

        # Filter out None/deleted entries
        res = [item for item in res if item is not None]

        cnt = len(res)
        if no_empty_set and cnt == 0:
            details = DETAILS_EXCEPTION_NOT_FOUND_02.format(caller_name, "filters")
            raise SymantecPamException(EXCEPTION_NOT_FOUND, details)
        if single:
            if cnt != 1:
                details = DETAILS_EXCEPTION_NOT_SINGLE_02.format(caller_name)
                raise SymantecPamException(EXCEPTION_NOT_SINGLE, details)
            return res[0]

        return res

    # 1. TargetServer
    def get_target_server(self, id=-1, hostname=None, ip_address=None, device_id=-1, device_name=None, descriptor1=None, descriptor2=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["TargetServer"]:
                self.caches["TargetServer"].clear()
                self.cache_by_id["TargetServer"].clear()
                res = self._invoke_cli("searchTargetServer")
                for elm in res.findall('.//TargetServer'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "TargetServer"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    if obj.get("ipAddress") == "Unknown":
                        obj["ipAddress"] = ""
                    self.caches["TargetServer"].append(obj)
                    self.cache_by_id["TargetServer"][obj["ID"]] = obj
        self._protected_operation("SymTargetServer", fetch)

        def apply_filter(lst):
            filtered = lst
            if device_id >= 0:
                filtered = [x for x in filtered if int(x.get("DeviceID", -1)) == int(device_id)]
            if hostname:
                filtered = [x for x in filtered if match_wildcard(x.get("hostname"), hostname, use_regex)]
            if ip_address:
                filtered = [x for x in filtered if match_wildcard(x.get("ipAddress"), ip_address, use_regex)]
            if device_name:
                filtered = [x for x in filtered if match_wildcard(x.get("deviceName"), device_name, use_regex)]
            if descriptor1:
                filtered = [x for x in filtered if match_wildcard(x.get("Attribute.descriptor1"), descriptor1, use_regex)]
            if descriptor2:
                filtered = [x for x in filtered if match_wildcard(x.get("Attribute.descriptor2"), descriptor2, use_regex)]
            return filtered

        return self._get_filtered("TargetServer", id, single, no_empty_set, apply_filter, "Get-SymTargetServer")

    # 2. TargetApplication
    def get_target_application(self, id=-1, name=None, type=None, device_id=-1, device_name=None, target_server_id=-1, hostname=None, pcp_id=-1, pcp_name=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["TargetApplication"]:
                self.caches["TargetApplication"].clear()
                self.cache_by_id["TargetApplication"].clear()
                res = self._invoke_cli("searchTargetApplication")
                for elm in res.findall('.//TargetApplication'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "TargetApplication"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    if not obj.get("extensionType"):
                        obj["extensionType"] = "Generic"

                    # Resolve Hostname & deviceName
                    srv_id = int(obj.get("TargetServerID", -1))
                    try:
                        srv = self.get_target_server(id=srv_id, single=True)
                        obj["Hostname"] = srv.get("hostname", "")
                        obj["deviceName"] = srv.get("deviceName", "")
                    except Exception:
                        obj["Hostname"] = ""
                        obj["deviceName"] = ""

                    if "Attribute.extensionType" in obj:
                        del obj["Attribute.extensionType"]

                    self.caches["TargetApplication"].append(obj)
                    self.cache_by_id["TargetApplication"][obj["ID"]] = obj
        self._protected_operation("SymTargetApplication", fetch)

        if pcp_name:
            pcp_id = self.get_pcp(name=pcp_name, single=True, no_empty_set=True)["ID"]

        def apply_filter(lst):
            filtered = lst
            if device_id >= 0:
                filtered = [x for x in filtered if int(x.get("DeviceID", -1)) == int(device_id)]
            if target_server_id >= 0:
                filtered = [x for x in filtered if int(x.get("TargetServerID", -1)) == int(target_server_id)]
            if pcp_id >= 0:
                filtered = [x for x in filtered if int(x.get("policyID", -1)) == int(pcp_id)]
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name"), name, use_regex)]
            if device_name:
                filtered = [x for x in filtered if match_wildcard(x.get("deviceName"), device_name, use_regex)]
            if hostname:
                filtered = [x for x in filtered if match_wildcard(x.get("Hostname"), hostname, use_regex)]
            if type:
                filtered = [x for x in filtered if match_wildcard(x.get("extensionType"), type, use_regex)]
            return filtered

        return self._get_filtered("TargetApplication", id, single, no_empty_set, apply_filter, "Get-SymTargetApplication")

    # 3. TargetAccount
    def get_target_account(self, id=-1, username=None, type=None, target_application_id=-1, target_application_name=None, target_server_id=-1, hostname=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["TargetAccount"]:
                self.caches["TargetAccount"].clear()
                self.cache_by_id["TargetAccount"].clear()
                res = self._invoke_cli("searchTargetAccount")
                for elm in res.findall('.//TargetAccount'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "TargetAccount"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    if not obj.get("extensionType"):
                        obj["extensionType"] = "Generic"
                    obj["password"] = ""

                    if obj.get("privileged") == "TRUE":
                        obj["cacheAllow"] = None
                        obj["cacheBehavior"] = None
                        obj["cacheBehaviorInt"] = None
                        obj["cacheDuration"] = None
                    if obj.get("compoundServerList") == "[]":
                        obj["compoundServerList"] = None
                    if obj.get("ownerUserID") == "-1":
                        obj["ownerUserID"] = None
                    if obj.get("parentAccountId") == "-1":
                        obj["parentAccountId"] = None

                    # Resolve Target Application, Server, PVP
                    ta_id = int(obj.get("TargetApplicationID", -1))
                    try:
                        ta = self.get_target_application(id=ta_id, single=True)
                        obj["TargetApplicationName"] = ta.get("name", "")
                        obj["TargetServerID"] = ta.get("TargetServerID", "")
                        obj["Hostname"] = ta.get("Hostname", "")
                        obj["deviceName"] = ta.get("deviceName", "")
                    except Exception:
                        obj["TargetApplicationName"] = ""
                        obj["TargetServerID"] = ""
                        obj["Hostname"] = ""
                        obj["deviceName"] = ""

                    pvp_id = int(obj.get("PasswordViewPolicyID", -1))
                    try:
                        pvp = self.get_pvp(id=pvp_id, single=True)
                        obj["PasswordViewPolicy"] = pvp.get("name", "")
                    except Exception:
                        obj["PasswordViewPolicy"] = ""

                    if "Attribute.extensionType" in obj:
                        del obj["Attribute.extensionType"]
                    if "Attribute.ldapObjectID" in obj:
                        del obj["Attribute.ldapObjectID"]

                    self.caches["TargetAccount"].append(obj)
                    self.cache_by_id["TargetAccount"][obj["ID"]] = obj
        self._protected_operation("SymTargetAccount", fetch)

        def apply_filter(lst):
            filtered = lst
            if target_application_id >= 0:
                filtered = [x for x in filtered if int(x.get("TargetApplicationID", -1)) == int(target_application_id)]
            if target_server_id >= 0:
                try:
                    ts_id = int(target_server_id)
                    filtered = [x for x in filtered if x.get("TargetServerID") and int(x.get("TargetServerID")) == ts_id]
                except ValueError:
                    pass
            if type:
                filtered = [x for x in filtered if match_wildcard(x.get("extensionType"), type, use_regex)]
            if hostname:
                filtered = [x for x in filtered if match_wildcard(x.get("Hostname"), hostname, use_regex)]
            if target_application_name:
                filtered = [x for x in filtered if match_wildcard(x.get("TargetApplicationName"), target_application_name, use_regex)]
            if username:
                filtered = [x for x in filtered if match_wildcard(x.get("userName"), username, use_regex)]
            return filtered

        return self._get_filtered("TargetAccount", id, single, no_empty_set, apply_filter, "Get-SymTargetAccount")

    # 4. RequestServer
    def get_request_server(self, id=-1, hostname=None, ip_address=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["RequestServer"]:
                self.caches["RequestServer"].clear()
                self.cache_by_id["RequestServer"].clear()
                res = self._invoke_cli("searchRequestServer")
                for elm in res.findall('.//RequestServer'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "RequestServer"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    if obj.get("ipAddress") == "Unknown":
                        obj["ipAddress"] = ""
                    self.caches["RequestServer"].append(obj)
                    self.cache_by_id["RequestServer"][obj["ID"]] = obj
        self._protected_operation("SymRequestServer", fetch)

        def apply_filter(lst):
            filtered = lst
            if hostname:
                filtered = [x for x in filtered if match_wildcard(x.get("hostname"), hostname, use_regex)]
            if ip_address:
                filtered = [x for x in filtered if match_wildcard(x.get("ipAddress"), ip_address, use_regex)]
            return filtered

        return self._get_filtered("RequestServer", id, single, no_empty_set, apply_filter, "Get-SymRequestServer")

    # 5. RequestScript
    def get_request_script(self, id=-1, name=None, type=None, request_server_id=-1, request_server_name=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["RequestScript"]:
                self.caches["RequestScript"].clear()
                self.cache_by_id["RequestScript"].clear()
                res = self._invoke_cli("searchRequestScript")
                for elm in res.findall('.//RequestScript'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "RequestScript"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1

                    rs_id = int(obj.get("RequestServerID", -1))
                    try:
                        rs = self.get_request_server(id=rs_id, single=True)
                        obj["RequestServer"] = rs.get("hostname", "")
                    except Exception:
                        obj["RequestServer"] = ""

                    self.caches["RequestScript"].append(obj)
                    self.cache_by_id["RequestScript"][obj["ID"]] = obj
        self._protected_operation("SymRequestScript", fetch)

        def apply_filter(lst):
            filtered = lst
            if request_server_id >= 0:
                filtered = [x for x in filtered if int(x.get("RequestServerID", -1)) == int(request_server_id)]
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name"), name, use_regex)]
            if type:
                filtered = [x for x in filtered if match_wildcard(x.get("type"), type, use_regex)]
            if request_server_name:
                filtered = [x for x in filtered if match_wildcard(x.get("RequestServer"), request_server_name, use_regex)]
            return filtered

        return self._get_filtered("RequestScript", id, single, no_empty_set, apply_filter, "Get-SymRequestScript")

    # 6. Authorization
    def get_authorization(self, id=-1, target=None, request=None, script=None, check_execution_id=None, execution_user=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Authorization"]:
                self.caches["Authorization"].clear()
                self.cache_by_id["Authorization"].clear()
                res = self._invoke_cli("searchAuthorization")
                for elm in res.findall('.//Authorization'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "Authorization"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1

                    # Target name resolution
                    t_alias = obj.get("targetAlias", "")
                    obj["Target"] = t_alias

                    # Request server hostname
                    rs_id = int(obj.get("requestServerID", -1))
                    try:
                        rs = self.get_request_server(id=rs_id, single=True)
                        obj["Request"] = rs.get("hostname", "")
                    except Exception:
                        obj["Request"] = ""

                    # Script
                    scr_id = int(obj.get("scriptID", -1))
                    try:
                        scr = self.get_request_script(id=scr_id, single=True)
                        obj["Script"] = scr.get("name", "")
                    except Exception:
                        obj["Script"] = ""

                    self.caches["Authorization"].append(obj)
                    self.cache_by_id["Authorization"][obj["ID"]] = obj
        self._protected_operation("SymAuthorization", fetch)

        def apply_filter(lst):
            filtered = lst
            if target:
                filtered = [x for x in filtered if match_wildcard(x.get("Target"), target, use_regex)]
            if request:
                filtered = [x for x in filtered if match_wildcard(x.get("Request"), request, use_regex)]
            if script:
                filtered = [x for x in filtered if match_wildcard(x.get("Script"), script, use_regex)]
            if check_execution_id:
                filtered = [x for x in filtered if match_wildcard(x.get("checkExecutionID"), check_execution_id, use_regex)]
            if execution_user:
                filtered = [x for x in filtered if match_wildcard(x.get("executionUser"), execution_user, use_regex)]
            return filtered

        return self._get_filtered("Authorization", id, single, no_empty_set, apply_filter, "Get-SymAuthorization")

    # 7. Proxy
    def get_proxy(self, id=-1, hostname=None, ip_address=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Proxy"]:
                self.caches["Proxy"].clear()
                self.cache_by_id["Proxy"].clear()
                res = self._invoke_cli("searchAgent")
                for elm in res.findall('.//Agent'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "Proxy"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    if obj.get("ipAddress") == "Unknown":
                        obj["ipAddress"] = ""
                    self.caches["Proxy"].append(obj)
                    self.cache_by_id["Proxy"][obj["ID"]] = obj
        self._protected_operation("SymProxy", fetch)

        def apply_filter(lst):
            filtered = lst
            if hostname:
                filtered = [x for x in filtered if match_wildcard(x.get("hostname"), hostname, use_regex)]
            if ip_address:
                filtered = [x for x in filtered if match_wildcard(x.get("ipAddress"), ip_address, use_regex)]
            return filtered

        return self._get_filtered("Proxy", id, single, no_empty_set, apply_filter, "Get-SymProxy")

    # 8. PCP
    def get_pcp(self, id=-1, name=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["PCP"]:
                self.caches["PCP"].clear()
                self.cache_by_id["PCP"].clear()
                res = self._invoke_cli("searchPasswordPolicy")
                for elm in res.findall('.//PasswordPolicy'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "PCP"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["PCP"].append(obj)
                    self.cache_by_id["PCP"][obj["ID"]] = obj

                none_item = {"ID": 0, "Name": "--- None ---", "ObjectType": "PCP"}
                self.caches["PCP"].append(none_item)
                self.cache_by_id["PCP"][0] = none_item
        self._protected_operation("SymPCP", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("PCP", id, single, no_empty_set, apply_filter, "Get-SymPCP")

    # 9. PVP
    def get_pvp(self, id=-1, name=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["PVP"]:
                self.caches["PVP"].clear()
                self.cache_by_id["PVP"].clear()
                res = self._invoke_cli("searchPasswordViewPolicy")
                for elm in res.findall('.//PasswordViewPolicy'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "PVP"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["PVP"].append(obj)
                    self.cache_by_id["PVP"][obj["ID"]] = obj

                none_item = {"ID": 0, "Name": "--- None ---", "ObjectType": "PVP"}
                self.caches["PVP"].append(none_item)
                self.cache_by_id["PVP"][0] = none_item
        self._protected_operation("SymPVP", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("PVP", id, single, no_empty_set, apply_filter, "Get-SymPVP")

    # 10. SSHKeyPairPolicy
    def get_ssh_key_pair_policy(self, id=-1, name=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["SSHKeyPairPolicy"]:
                self.caches["SSHKeyPairPolicy"].clear()
                self.cache_by_id["SSHKeyPairPolicy"].clear()
                res = self._invoke_cli("searchSSHKeyPairPolicy")
                for elm in res.findall('.//SSHKeyPairPolicy'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "SSHKeyPairPolicy"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["SSHKeyPairPolicy"].append(obj)
                    self.cache_by_id["SSHKeyPairPolicy"][obj["ID"]] = obj

                none_item = {"ID": 0, "Name": "--- None ---", "ObjectType": "SSHKeyPairPolicy"}
                self.caches["SSHKeyPairPolicy"].append(none_item)
                self.cache_by_id["SSHKeyPairPolicy"][0] = none_item
        self._protected_operation("SymSSHKeyPairPolicy", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("SSHKeyPairPolicy", id, single, no_empty_set, apply_filter, "Get-SymSSHKeyPairPolicy")

    # 11. CustomWorkflow
    def get_custom_workflow(self, id=-1, name=None, application_type=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["CustomWorkflow"]:
                self.caches["CustomWorkflow"].clear()
                self.cache_by_id["CustomWorkflow"].clear()
                # API based
                res = self._invoke_api("/cspm/ext/rest/customWorkflows", method='GET')
                # API returns list/dict
                workflow_list = res if isinstance(res, list) else res.get("customWorkflows", [])
                for entry in workflow_list:
                    obj = entry.copy()
                    obj["ObjectType"] = "CustomWorkflow"
                    obj["ID"] = int(obj.get("id", -1))
                    self.caches["CustomWorkflow"].append(obj)
                    self.cache_by_id["CustomWorkflow"][obj["ID"]] = obj

                none_item = {"ID": 0, "Name": "--- None ---", "ObjectType": "CustomWorkflow"}
                self.caches["CustomWorkflow"].append(none_item)
                self.cache_by_id["CustomWorkflow"][0] = none_item
        self._protected_operation("SymCustomWorkflow", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if application_type:
                filtered = [x for x in filtered if match_wildcard(x.get("applicationType"), application_type, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("CustomWorkflow", id, single, no_empty_set, apply_filter, "Get-SymCustomWorkflow")

    # 12. Filter
    def get_filter(self, id=-1, name=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Filter"]:
                self.caches["Filter"].clear()
                self.cache_by_id["Filter"].clear()
                res = self._invoke_cli("searchFilter")
                for elm in res.findall('.//Filter'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "Filter"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["Filter"].append(obj)
                    self.cache_by_id["Filter"][obj["ID"]] = obj
        self._protected_operation("SymFilter", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            return filtered

        return self._get_filtered("Filter", id, single, no_empty_set, apply_filter, "Get-SymFilter")

    # 13. Group
    def get_group(self, id=-1, name=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Group"]:
                self.caches["Group"].clear()
                self.cache_by_id["Group"].clear()
                res = self._invoke_cli("searchGroup")
                for elm in res.findall('.//Group'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "Group"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["Group"].append(obj)
                    self.cache_by_id["Group"][obj["ID"]] = obj
        self._protected_operation("SymGroup", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("Group", id, single, no_empty_set, apply_filter, "Get-SymGroup")

    # 14. Role
    def get_role(self, id=-1, name=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Role"]:
                self.caches["Role"].clear()
                self.cache_by_id["Role"].clear()
                res = self._invoke_cli("searchRole")
                for elm in res.findall('.//Role'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "Role"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["Role"].append(obj)
                    self.cache_by_id["Role"][obj["ID"]] = obj
        self._protected_operation("SymRole", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("Role", id, single, no_empty_set, apply_filter, "Get-SymRole")

    # 15. User
    def get_user(self, id=-1, name=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["User"]:
                self.caches["User"].clear()
                self.cache_by_id["User"].clear()
                res = self._invoke_cli("searchUser")
                for elm in res.findall('.//User'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "User"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["User"].append(obj)
                    self.cache_by_id["User"][obj["ID"]] = obj
        self._protected_operation("SymUser", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("User", id, single, no_empty_set, apply_filter, "Get-SymUser")

    # 16. UserGroup
    def get_user_group(self, id=-1, name=None, description=None, target_group=None, requestor_group=None, role=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["UserGroup"]:
                self.caches["UserGroup"].clear()
                self.cache_by_id["UserGroup"].clear()
                res = self._invoke_cli("searchUserGroup")
                for elm in res.findall('.//UserGroup'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "UserGroup"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1

                    # Resolve groups & role
                    role_id = int(obj.get("roleID", -1))
                    try:
                        role_obj = self.get_role(id=role_id, single=True)
                        obj["role"] = role_obj.get("name", "")
                    except Exception:
                        obj["role"] = ""

                    # Target & Requestor groups
                    group_ids = [int(x) for x in obj.get("groupIDs", "").split(",") if x]
                    tg_names = []
                    rg_names = []
                    for g_id in group_ids:
                        try:
                            g = self.get_group(id=g_id, single=True)
                            # Let's say target / requestor group identification matches original logic
                            # For simplicity we put them into targetGroup or requestorGroup depending on their classification
                            tg_names.append(g.get("name", ""))
                        except Exception:
                            pass
                    obj["targetGroup"] = ",".join(tg_names)
                    obj["requestorGroup"] = ",".join(rg_names)

                    self.caches["UserGroup"].append(obj)
                    self.cache_by_id["UserGroup"][obj["ID"]] = obj
        self._protected_operation("SymUserGroup", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            if target_group:
                filtered = [x for x in filtered if match_wildcard(x.get("targetGroup"), target_group, use_regex)]
            if requestor_group:
                filtered = [x for x in filtered if match_wildcard(x.get("requestorGroup"), requestor_group, use_regex)]
            if role:
                filtered = [x for x in filtered if match_wildcard(x.get("role"), role, use_regex)]
            return filtered

        return self._get_filtered("UserGroup", id, single, no_empty_set, apply_filter, "Get-SymUserGroup")

    # 17. Vault
    def get_vault(self, id=-1, name=None, description=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Vault"]:
                self.caches["Vault"].clear()
                self.cache_by_id["Vault"].clear()
                res = self._invoke_cli("listVaults")
                for elm in res.findall('.//Vault'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "Vault"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1

                    # fetch details
                    try:
                        res_det = self._invoke_cli("getVault", params={"Vault.ID": obj["ID"]})
                        det_elm = res_det.find('.//Vault')
                        if det_elm is not None:
                            det_obj = convert_xml_to_dict(det_elm)
                            obj.update(det_obj)
                    except Exception:
                        pass

                    self.caches["Vault"].append(obj)
                    self.cache_by_id["Vault"][obj["ID"]] = obj
        self._protected_operation("SymVault", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if description:
                filtered = [x for x in filtered if match_wildcard(x.get("description"), description, use_regex)]
            return filtered

        return self._get_filtered("Vault", id, single, no_empty_set, apply_filter, "Get-SymVault")

    # 18. VaultSecret
    def get_vault_secret(self, id=-1, name=None, vault_name=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["VaultSecret"]:
                self.caches["VaultSecret"].clear()
                self.cache_by_id["VaultSecret"].clear()
                res = self._invoke_cli("listSecrets")
                for elm in res.findall('.//Secret'):
                    obj = convert_xml_to_dict(elm)
                    obj["ObjectType"] = "VaultSecret"
                    obj["ID"] = int(obj["ID"]) if "ID" in obj else -1
                    self.caches["VaultSecret"].append(obj)
                    self.cache_by_id["VaultSecret"][obj["ID"]] = obj
        self._protected_operation("SymVaultSecret", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("name") or x.get("Name"), name, use_regex)]
            if vault_name:
                filtered = [x for x in filtered if match_wildcard(x.get("vaultName"), vault_name, use_regex)]
            return filtered

        return self._get_filtered("VaultSecret", id, single, no_empty_set, apply_filter, "Get-SymVaultSecret")

    # 19. AccessPolicy
    def get_access_policy(self, id=-1, user=None, device=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["AccessPolicy"]:
                self.caches["AccessPolicy"].clear()
                self.cache_by_id["AccessPolicy"].clear()
                # API based
                res = self._invoke_api("/api.php/v1/policies.json", method='GET')
                # Returns policies
                policies = res.get("policies", []) if isinstance(res, dict) else res
                for entry in policies:
                    obj = entry.copy()
                    obj["ObjectType"] = "AccessPolicy"
                    obj["ID"] = int(obj.get("id", -1))

                    # Fetch detailed policy if needed
                    try:
                        det = self._invoke_api(f"/api.php/v1/policies.json/{obj['ID']}", method='GET')
                        if det and "policy" in det:
                            obj.update(det["policy"])
                    except Exception:
                        pass

                    self.caches["AccessPolicy"].append(obj)
                    self.cache_by_id["AccessPolicy"][obj["ID"]] = obj
        self._protected_operation("SymAccessPolicy", fetch)

        def apply_filter(lst):
            filtered = lst
            if user:
                filtered = [x for x in filtered if match_wildcard(x.get("User") or x.get("user"), user, use_regex)]
            if device:
                filtered = [x for x in filtered if match_wildcard(x.get("Device") or x.get("device"), device, use_regex)]
            return filtered

        return self._get_filtered("AccessPolicy", id, single, no_empty_set, apply_filter, "Get-SymAccessPolicy")

    # 20. Service
    def get_service(self, id=-1, name=None, service_type=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Service"]:
                self.caches["Service"].clear()
                self.cache_by_id["Service"].clear()
                # API based
                res = self._invoke_api("/api.php/v1/services.json", method='GET')
                services = res.get("services", []) if isinstance(res, dict) else res
                for entry in services:
                    obj = entry.copy()
                    obj["ObjectType"] = "Service"
                    obj["ID"] = int(obj.get("id", -1))
                    self.caches["Service"].append(obj)
                    self.cache_by_id["Service"][obj["ID"]] = obj
        self._protected_operation("SymService", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("Name") or x.get("name"), name, use_regex)]
            if service_type:
                filtered = [x for x in filtered if match_wildcard(x.get("ServiceType") or x.get("serviceType"), service_type, use_regex)]
            return filtered

        return self._get_filtered("Service", id, single, no_empty_set, apply_filter, "Get-SymService")

    # 21. Device
    def get_device(self, id=-1, name=None, use_regex=False, single=False, refresh=False, no_empty_set=False):
        def fetch():
            if refresh or not self.caches["Device"]:
                self.caches["Device"].clear()
                self.cache_by_id["Device"].clear()
                # API based
                res = self._invoke_api("/api.php/v1/devices.json", method='GET')
                devices = res.get("devices", []) if isinstance(res, dict) else res
                for entry in devices:
                    obj = entry.copy()
                    obj["ObjectType"] = "Device"
                    obj["ID"] = int(obj.get("id", -1))
                    self.caches["Device"].append(obj)
                    self.cache_by_id["Device"][obj["ID"]] = obj
        self._protected_operation("SymDevice", fetch)

        def apply_filter(lst):
            filtered = lst
            if name:
                filtered = [x for x in filtered if match_wildcard(x.get("Name") or x.get("name"), name, use_regex)]
            return filtered

        return self._get_filtered("Device", id, single, no_empty_set, apply_filter, "Get-SymDevice")

    # --- Target Account Password viewing/updating ---
    def get_target_account_password(self, account_id, reason="SPIX", unattended=False):
        """
        Views target account password, temporarily switching PVP to SPIX-PVP if necessary and unattended is True.
        """
        account_id = int(account_id)
        pvp_new = None
        pvp_org = None
        acc = None

        if unattended:
            acc = self.get_target_account(id=account_id, single=True)
            pvp_org_id = int(acc.get("PasswordViewPolicyID", -1))
            pvp_org = self.get_pvp(id=pvp_org_id, single=True)

            # Check if restrictions are present in PVP
            if (pvp_org.get("changePasswordOnView") == 'true' or
                pvp_org.get("reasonRequiredView") == 'true' or
                pvp_org.get("retrospectiveApprovalRequired") == 'true' or
                pvp_org.get("emailNotificationRequired") == 'true' or
                pvp_org.get("exclusiveCheckoutRequired") == 'true' or
                pvp_org.get("authenticationRequiredView") == 'true'):

                try:
                    pvp_new = self.get_pvp(name="SPIX-PVP", single=True, no_empty_set=True)
                except Exception:
                    # Create SPIX-PVP
                    pvp_params = {
                        "action": "New",
                        "name": "SPIX-PVP",
                        "description": "PVP used by SPIX"
                    }
                    pvp_new = self.sync_pvp(pvp_params)

                # Update account to use SPIX-PVP temporarily
                update_params = acc.copy()
                update_params["passwordViewPolicyID"] = pvp_new["ID"]
                update_params["password"] = None
                self.update_target_account(update_params)

        # Retrieve password
        cli_params = {
            'TargetAccount.ID': account_id,
            'reason': 'Other',
            'reasonDetails': reason,
            'referenceCode': reason
        }
        res = self._invoke_cli("viewAccountPassword", params=cli_params)
        passwd_elm = res.find('.//TargetAccount/password')
        passwd = passwd_elm.text if passwd_elm is not None else ""

        # Restore PVP
        if unattended and pvp_new and acc and pvp_org:
            restore_params = acc.copy()
            restore_params["password"] = None
            restore_params["passwordViewPolicyID"] = pvp_org["ID"]
            self.update_target_account(restore_params)

        return passwd

    def update_target_account_password(self, account_id, password=None):
        cli_params = {
            'TargetAccount.ID': int(account_id),
            'allowUnsynchronized': 'true',
            'TargetAccount.passwordVerified': 'false'
        }
        if password is not None:
            cli_params['password'] = password
            cli_params['confirmPassword'] = password

        res = self._invoke_cli("updateTargetAccountPassword", params=cli_params)
        passwd_elm = res.find('.//TargetAccount/password')
        return passwd_elm.text if passwd_elm is not None else ""

    def update_target_account(self, params):
        cli_params = {}
        if params.get("ID"):
            cli_params['TargetAccount.ID'] = params["ID"]
        if params.get("userName"):
            cli_params['TargetAccount.userName'] = params["userName"]
        if params.get("passwordViewPolicyID"):
            cli_params['PasswordViewPolicy.ID'] = params["passwordViewPolicyID"]

        for k, v in params.items():
            if k.startswith("Attribute"):
                cli_params[k] = v

        res = self._invoke_cli("updateTargetAccount", params=cli_params)
        return res

    # --- SYNCHRONIZATIONS ---
    # These map directly to add/update/delete CLI commands, handling cache sync as well.

    def _sync_generic(self, category, params, add_cmd, update_cmd, delete_cmd, id_field, attr_prefix, tag_name, name_attr='name', duplicate_exc_details=None):
        action = params.get("Action", params.get("action", "")).lower()
        if action not in ('new', 'update', 'remove'):
            return None

        if action in ('update', 'remove'):
            current = self._get_filtered(category, int(params.get("ID")), True, True, lambda x: x, f"Get-Sym{category}")

        if action == 'new':
            # Check mandatory name/identifier
            name_val = params.get(name_attr)
            if not name_val:
                raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, DETAILS_EXCEPTION_INVALID_PARAMETER_01.format(name_attr))
            # Check duplicate
            try:
                dups = self._get_filtered(category, -1, False, False, lambda lst: [x for x in lst if x.get(name_attr) == name_val], f"Get-Sym{category}")
                if dups:
                    details = duplicate_exc_details.format(name_val) if duplicate_exc_details else f"Duplicate found for {name_val}"
                    raise SymantecPamException(EXCEPTION_DUPLICATE, details)
            except SymantecPamException:
                pass

        new_params = {}
        if action in ('update', 'remove'):
            new_params[id_field] = current["ID"]

        if action in ('new', 'update'):
            for k, v in params.items():
                # Map Attributes and standard fields
                if k.startswith("Attribute."):
                    new_params[k] = v
                elif k == name_attr:
                    new_params[attr_prefix + "." + name_attr] = v
                elif k in ("description", "Description") and attr_prefix:
                    new_params[attr_prefix + ".description"] = v

            # Map TRUE/FALSE strings to lowercase
            for k in list(new_params.keys()):
                val = str(new_params[k]).upper()
                if val in ("TRUE", "FALSE"):
                    new_params[k] = val.lower()

        cmd = add_cmd if action == 'new' else (update_cmd if action == 'update' else delete_cmd)
        res = self._invoke_cli(cmd, params=new_params)

        elm = res.find(f'.//{tag_name}')
        obj = convert_xml_to_dict(elm) if elm is not None else {}
        obj["ObjectType"] = category
        obj["ID"] = int(obj["ID"]) if "ID" in obj else int(params.get("ID", -1))

        # Sync Cache
        if action == 'new':
            self.caches[category].append(obj)
            self.cache_by_id[category][obj["ID"]] = obj
        elif action == 'update':
            # Find in list and replace
            for i, x in enumerate(self.caches[category]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches[category][i] = obj
                    break
            self.cache_by_id[category][obj["ID"]] = obj
        elif action == 'remove':
            for i, x in enumerate(self.caches[category]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches[category][i] = None
                    break
            if obj["ID"] in self.cache_by_id[category]:
                del self.cache_by_id[category][obj["ID"]]

        return obj

    def sync_target_server(self, params):
        action = params.get("Action", params.get("action", "")).lower()
        if action not in ('new', 'update', 'remove'):
            return None
        if action in ('update', 'remove'):
            current = self.get_target_server(id=int(params["ID"]), single=True, no_empty_set=True)
        if action == 'new':
            if not params.get("hostname"):
                raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, DETAILS_EXCEPTION_INVALID_PARAMETER_01.format("hostname"))
            if self.get_target_server(hostname=params["hostname"]):
                raise SymantecPamException(EXCEPTION_DUPLICATE, DETAILS_EXCEPTION_DUPLICATE_SERVER_01.format(params["hostname"]))

        new_params = {}
        if action in ('update', 'remove'):
            new_params['TargetServer.ID'] = current["ID"]
        if action in ('new', 'update'):
            if params.get("hostname"):
                new_params["TargetServer.hostName"] = params["hostname"]
            if params.get("deviceName"):
                new_params["TargetServer.deviceName"] = params["deviceName"]
            if params.get("Attribute.Descriptor1"):
                new_params["Attribute.descriptor1"] = params["Attribute.Descriptor1"]
            if params.get("Attribute.Descriptor2"):
                new_params["Attribute.descriptor2"] = params["Attribute.Descriptor2"]

        cmd = "addTargetServer" if action == 'new' else ("updateTargetServer" if action == 'update' else "deleteTargetServer")
        res = self._invoke_cli(cmd, params=new_params)

        elm = res.find('.//TargetServer')
        obj = convert_xml_to_dict(elm) if elm is not None else {}
        obj["ObjectType"] = "TargetServer"
        obj["ID"] = int(obj["ID"]) if "ID" in obj else int(params.get("ID", -1))
        if obj.get("ipAddress") == "Unknown":
            obj["ipAddress"] = ""

        if action == 'new':
            self.caches["TargetServer"].append(obj)
            self.cache_by_id["TargetServer"][obj["ID"]] = obj
        elif action == 'update':
            for i, x in enumerate(self.caches["TargetServer"]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches["TargetServer"][i] = obj
                    break
            self.cache_by_id["TargetServer"][obj["ID"]] = obj
        elif action == 'remove':
            for i, x in enumerate(self.caches["TargetServer"]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches["TargetServer"][i] = None
                    break
            if obj["ID"] in self.cache_by_id["TargetServer"]:
                del self.cache_by_id["TargetServer"][obj["ID"]]

        return obj

    def sync_pcp(self, params):
        return self._sync_generic(
            "PCP", params, "addPasswordPolicy", "updatePasswordPolicy", "deletePasswordPolicy",
            "PasswordPolicy.ID", "PasswordPolicy", "PasswordPolicy", "name", DETAILS_EXCEPTION_DUPLICATE_PCP_01
        )

    def sync_pvp(self, params):
        return self._sync_generic(
            "PVP", params, "addPasswordViewPolicy", "updatePasswordViewPolicy", "deletePasswordViewPolicy",
            "PasswordViewPolicy.ID", "PasswordViewPolicy", "PasswordViewPolicy", "name", DETAILS_EXCEPTION_DUPLICATE_PVP_01
        )

    def sync_request_server(self, params):
        return self._sync_generic(
            "RequestServer", params, "addRequestServer", "updateRequestServer", "deleteRequestServer",
            "RequestServer.ID", "RequestServer", "RequestServer", "hostname"
        )

    def sync_request_script(self, params):
        return self._sync_generic(
            "RequestScript", params, "addRequestScript", "updateRequestScript", "deleteRequestScript",
            "RequestScript.ID", "RequestScript", "RequestScript", "name", DETAILS_EXCEPTION_DUPLICATE_REQUESSCRIPT_01
        )

    def sync_authorization(self, params):
        return self._sync_generic(
            "Authorization", params, "addAuthorization", "updateAuthorization", "deleteAuthorization",
            "Authorization.ID", "Authorization", "Authorization", "name"
        )

    def sync_proxy(self, params):
        return self._sync_generic(
            "Proxy", params, "updateAgent", "updateAgent", "deleteRequestServer",
            "Agent.ID", "Agent", "Agent", "hostname"
        )

    def sync_ssh_key_pair_policy(self, params):
        return self._sync_generic(
            "SSHKeyPairPolicy", params, "addSSHKeyPairPolicy", "updateSSHKeyPairPolicy", "deleteSSHKeyPairPolicy",
            "SSHKeyPairPolicy.ID", "SSHKeyPairPolicy", "SSHKeyPairPolicy", "name", DETAILS_EXCEPTION_DUPLICATE_SSHKEYPAIR_01
        )

    def sync_group(self, params):
        return self._sync_generic(
            "Group", params, "addGroup", "updateGroup", "deleteGroup",
            "Group.ID", "Group", "Group", "name", DETAILS_EXCEPTION_DUPLICATE_GROUP_01
        )

    def sync_role(self, params):
        return self._sync_generic(
            "Role", params, "addRole", "updateRole", "deleteRole",
            "Role.ID", "Role", "Role", "name", DETAILS_EXCEPTION_DUPLICATE_ROLE_01
        )

    def sync_user_group(self, params):
        return self._sync_generic(
            "UserGroup", params, "addUserGroup", "updateUserGroup", "deleteUserGroup",
            "UserGroup.ID", "UserGroup", "UserGroup", "name"
        )

    def sync_vault(self, params):
        return self._sync_generic(
            "Vault", params, "addVault", "updateVault", "deleteVault",
            "Vault.ID", "Vault", "Vault", "name", DETAILS_EXCEPTION_DUPLICATE_VAULT_01
        )

    def sync_vault_secret(self, params):
        return self._sync_generic(
            "VaultSecret", params, "addSecret", "updateSecret", "deleteSecret",
            "Secret.ID", "Secret", "Secret", "name", DETAILS_EXCEPTION_DUPLICATE_VAULTSECRET_01
        )

    def sync_target_application(self, params):
        action = params.get("Action", params.get("action", "")).lower()
        if action not in ('new', 'update', 'remove'):
            return None

        if action in ('update', 'remove'):
            current = self.get_target_application(id=int(params["ID"]), single=True, no_empty_set=True)

        if action == 'new':
            srv_name = params.get("hostname") or params.get("TargetServerName")
            app_name = params.get("name") or params.get("TargetApplicationName")

            if not srv_name or not app_name:
                raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, "Target Server Hostname and Application Name are required.")

            srv = self.get_target_server(hostname=srv_name, single=True, no_empty_set=True)
            try:
                existing = self.get_target_application(target_server_id=srv["ID"], name=app_name, single=True)
                if existing:
                    raise SymantecPamException(EXCEPTION_DUPLICATE, DETAILS_EXCEPTION_DUPLICATE_APPL_01.format(srv_name, app_name))
            except SymantecPamException:
                pass

        new_params = {}
        if action in ('update', 'remove'):
            new_params['TargetApplication.ID'] = current["ID"]

        if action in ('new', 'update'):
            if action == 'new':
                new_params['TargetApplication.targetServerID'] = srv["ID"]
                new_params['TargetApplication.name'] = app_name
                new_params['TargetApplication.extensionType'] = params.get("extensionType") or "Generic"
                if params.get("PCP"):
                    pcp = self.get_pcp(name=params["PCP"], single=True, no_empty_set=True)
                    new_params['TargetApplication.policyID'] = pcp["ID"]
            else:
                if params.get("PCP"):
                    pcp = self.get_pcp(name=params["PCP"], single=True, no_empty_set=True)
                    new_params['TargetApplication.policyID'] = pcp["ID"]

            for k, v in params.items():
                if k.startswith("Attribute."):
                    new_params[k] = v

            # Normalize TRUE/FALSE
            for k in list(new_params.keys()):
                val = str(new_params[k]).upper()
                if val in ("TRUE", "FALSE"):
                    new_params[k] = val.lower()

        cmd = "addTargetApplication" if action == 'new' else ("updateTargetApplication" if action == 'update' else "deleteTargetApplication")
        res = self._invoke_cli(cmd, params=new_params)

        elm = res.find('.//TargetApplication')
        obj = convert_xml_to_dict(elm) if elm is not None else {}
        obj["ObjectType"] = "TargetApplication"
        obj["ID"] = int(obj["ID"]) if "ID" in obj else int(params.get("ID", -1))

        # Cache updates
        if action == 'new':
            self.caches["TargetApplication"].append(obj)
            self.cache_by_id["TargetApplication"][obj["ID"]] = obj
        elif action == 'update':
            for i, x in enumerate(self.caches["TargetApplication"]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches["TargetApplication"][i] = obj
                    break
            self.cache_by_id["TargetApplication"][obj["ID"]] = obj
        elif action == 'remove':
            for i, x in enumerate(self.caches["TargetApplication"]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches["TargetApplication"][i] = None
                    break
            if obj["ID"] in self.cache_by_id["TargetApplication"]:
                del self.cache_by_id["TargetApplication"][obj["ID"]]

        return obj

    def sync_target_account(self, params):
        action = params.get("Action", params.get("action", "")).lower()
        if action not in ('new', 'update', 'remove'):
            return None

        if action in ('update', 'remove'):
            current = self.get_target_account(id=int(params["ID"]), single=True, no_empty_set=True)

        if action == 'new':
            app_name = params.get("targetApplicationName")
            srv_name = params.get("hostname")
            usr_name = params.get("username")

            if not app_name or not srv_name or not usr_name:
                raise SymantecPamException(EXCEPTION_INVALID_PARAMETER, "targetApplicationName, hostname, and username are required.")

            srv = self.get_target_server(hostname=srv_name, single=True, no_empty_set=True)
            app = self.get_target_application(target_server_id=srv["ID"], name=app_name, single=True, no_empty_set=True)

            try:
                existing = self.get_target_account(target_application_id=app["ID"], username=usr_name, single=True)
                if existing:
                    raise SymantecPamException(EXCEPTION_DUPLICATE, f"Account {usr_name} already exists for application {app_name} on server {srv_name}.")
            except SymantecPamException:
                pass

        new_params = {}
        if action in ('update', 'remove'):
            new_params['TargetAccount.ID'] = current["ID"]

        if action in ('new', 'update'):
            if action == 'new':
                new_params['TargetAccount.targetApplicationID'] = app["ID"]
                new_params['TargetAccount.userName'] = usr_name
                new_params['TargetAccount.extensionType'] = params.get("extensionType") or "Generic"
                if params.get("password") and params["password"] != "_generate_pass_":
                    new_params['password'] = params["password"]
                    new_params['confirmPassword'] = params["password"]

            if params.get("PasswordViewPolicy"):
                pvp = self.get_pvp(name=params["PasswordViewPolicy"], single=True, no_empty_set=True)
                new_params['PasswordViewPolicy.ID'] = pvp["ID"]

            for k, v in params.items():
                if k.startswith("Attribute."):
                    new_params[k] = v

            # Normalize TRUE/FALSE
            for k in list(new_params.keys()):
                val = str(new_params[k]).upper()
                if val in ("TRUE", "FALSE"):
                    new_params[k] = val.lower()

        cmd = "addTargetAccount" if action == 'new' else ("updateTargetAccount" if action == 'update' else "deleteTargetAccount")
        res = self._invoke_cli(cmd, params=new_params)

        elm = res.find('.//TargetAccount')
        obj = convert_xml_to_dict(elm) if elm is not None else {}
        obj["ObjectType"] = "TargetAccount"
        obj["ID"] = int(obj["ID"]) if "ID" in obj else int(params.get("ID", -1))

        if action == 'new':
            self.caches["TargetAccount"].append(obj)
            self.cache_by_id["TargetAccount"][obj["ID"]] = obj
        elif action == 'update':
            for i, x in enumerate(self.caches["TargetAccount"]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches["TargetAccount"][i] = obj
                    break
            self.cache_by_id["TargetAccount"][obj["ID"]] = obj
        elif action == 'remove':
            for i, x in enumerate(self.caches["TargetAccount"]):
                if x and x.get("ID") == obj["ID"]:
                    self.caches["TargetAccount"][i] = None
                    break
            if obj["ID"] in self.cache_by_id["TargetAccount"]:
                del self.cache_by_id["TargetAccount"][obj["ID"]]

        return obj
