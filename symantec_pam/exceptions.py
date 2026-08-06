# exceptions.py

class SymantecPamException(Exception):
    def __init__(self, message, details=""):
        super().__init__(message)
        self.message = message
        self.details = details

    def __str__(self):
        if self.details:
            return f"{self.message}: {self.details}"
        return self.message


EXCEPTION_INVALID_PARAMETER = "Invalid parameters"
EXCEPTION_NOT_FOUND = "Not found"
EXCEPTION_NOT_AUTHORIZED = "Not authorized"
EXCEPTION_NOT_SINGLE = "Not single"
EXCEPTION_PASSWORD_UPDATE = "Password update failed"
EXCEPTION_DUPLICATE = "Duplicate"
EXCAPTION_MISSING_TCF = "Custom Connector not operational"

DETAILS_EXCEPTION_INVALID_PARAMETER_01 = "Parameter '{0}' is missing"
DETAILS_EXCEPTION_INVALID_PARAMETER_02 = "A parameter is incorrect"
DETAILS_EXCEPTION_NOT_SINGLE_01 = "Multiple elements found with parameter '-Single'"
DETAILS_EXCEPTION_NOT_SINGLE_02 = "Multiple elements found with parameter '-Single' in '{0}'"
DETAILS_EXCEPTION_NOT_FOUND_01 = "Nothing found with parameter '-NoEmptySet' in '{0}'"
DETAILS_EXCEPTION_NOT_FOUND_02 = "Nothing found using '{1}' in '{0}'"
DETAILS_EXCEPTION_NOT_FOUND_03 = "Nothing found using '{1}' & '{2}' in '{0}'"
DETAILS_EXCEPTION_NOT_FOUND_PCP_01 = "PCP name '{0}' not found"
DETAILS_EXCEPTION_NOT_FOUND_PCP_02 = "PCP id '{0}' not found"
DETAILS_EXCEPTION_NOT_FOUND_SERVICE_01 = "Service name '{0}' not found"
DETAILS_EXCEPTION_NOT_FOUND_SERVICE_02 = "Service id '{0}' not found"
DETAILS_EXCEPTION_NOT_FOUND_TARGETSERVER_01 = "Target Server '{0}' not found"
DETAILS_EXCEPTION_NOT_FOUND_TARGETAPPLICATION_01 = "Target Application '{0}' not found"
DETAILS_EXCEPTION_NOT_AUTHORIZED_01 = "PAM user '{0}' is not authorized"
DETAILS_EXCEPTION_DUPLICATE_SERVER_01 = "Server '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_APPL_01 = "Server '{0}' and application '{1}' already exist"
DETAILS_EXCEPTION_DUPLICATE_PCP_01 = "PCP '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_PVP_01 = "PVP '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_GROUP_01 = "Group '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_ROLE_01 = "Role '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_FILTER_01 = "Filter '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_SSHKEYPAIR_01 = "SSH Key pair policy '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_REQUESSCRIPT_01 = "RequestScript '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_VAULT_01 = "Vault '{0}' already exist"
DETAILS_EXCEPTION_DUPLICATE_VAULTSECRET_01 = "VaultSecret '{0}' already exist"
DETAILS_EXCEPTION_CANNOT_IMPORT_01 = "Cannot import extension type '{0}'"
DETAILS_EXCEPTION_CANNOT_IMPORT_02 = "Import filename missing"
DETAILS_EXCEPTION_TCF_01 = "PAM-CF-0001: The Custom Connector server is inaccessible or its configuration is invalid."
