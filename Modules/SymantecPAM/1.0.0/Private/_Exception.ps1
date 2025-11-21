<#
MIT License

Copyright (c) 2025 PAM-Exchange

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>
#--------------------------------------------------------------------------------------

Set-Variable EXCEPTION_INVALID_PARAMETER -Option Constant -Value "Invalid parameters"
Set-Variable EXCEPTION_NOT_FOUND -Option Constant -Value "Not found"
#Set-Variable EXCEPTION_DUPLICATE -Option Constant -Value "Duplicate" 
#Set-Variable EXCEPTION_DEPENDENCY -Option Constant -Value "Dependency"
Set-Variable EXCEPTION_NOT_AUTHORIZED -Option Constant -Value "Not authorized"
#Set-Variable EXCEPTION_FORBIDDEN -Option Constant -Value "Forbidden"
Set-Variable EXCEPTION_NOT_SINGLE -Option Constant -Value "Not single"
Set-Variable EXCEPTION_PASSWORD_UPDATE -Option Constant -Value "Password update failed"
Set-Variable EXCEPTION_DUPLICATE -Option Constant -Value "Duplicate"
Set-Variable EXCAPTION_MISSING_TCF -Option Constant -Value "Custom Connector not operational"

Set-Variable DETAILS_EXCEPTION_INVALID_PARAMETER_01 -Option Constant -Value "Parameter '{0}' is missing"
Set-Variable DETAILS_EXCEPTION_INVALID_PARAMETER_02 -Option Constant -Value "A parameter is incorrect"
Set-Variable DETAILS_EXCEPTION_NOT_SINGLE_01 -Option Constant -Value "Multiple elements found when using parameter '-Single'"
Set-Variable DETAILS_EXCEPTION_NOT_FOUND_01 -Option Constant -Value "Nothing found when using parameter '-NoEmptySet'"
Set-Variable DETAILS_EXCEPTION_NOT_FOUND_PCP_01 -Option Constant -Value "PCP name '{0}' not found"
Set-Variable DETAILS_EXCEPTION_NOT_FOUND_PCP_02 -Option Constant -Value "PCP id '{0}' not found"
Set-Variable DETAILS_EXCEPTION_NOT_FOUND_SERVICE_01 -Option Constant -Value "Service name '{0}' not found"
Set-Variable DETAILS_EXCEPTION_NOT_FOUND_SERVICE_02 -Option Constant -Value "Service id '{0}' not found"
Set-Variable DETAILS_EXCEPTION_NOT_AUTHORIZED_01 -Option Constant -Value "PAM user '{0}' is not authorized"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_SERVER_01 -Option Constant -Value "Server '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_APPL_01 -Option Constant -Value "Server '{0}' and application '{1}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_PCP_01 -Option Constant -Value "PCP '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_PVP_01 -Option Constant -Value "PCP '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_GROUP_01 -Option Constant -Value "Group '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_ROLE_01 -Option Constant -Value "Role '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_FILTER_01 -Option Constant -Value "Filter '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_SSHKEYPAIR_01 -Option Constant -Value "SSH Key pair policy '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_REQUESSCRIPT_01 -Option Constant -Value "RequestScript '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_VAULT_01 -Option Constant -Value "Vault '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_DUPLICATE_VAULTSECRET_01 -Option Constant -Value "VaultSecret '{0}' already exist"
Set-Variable DETAILS_EXCEPTION_CANNOT_IMPORT_01 -Option Constant -Value "Cannot import extension type '{0}'"
Set-Variable DETAILS_EXCEPTION_CANNOT_IMPORT_02 -Option Constant -Value "Import filename missing"
Set-Variable DETAILS_EXCEPTION_TCF_01 -Option Constant -Value "PAM-CF-0001: The Custom Connector server is inaccessible or its configuration is invalid."

<#
Set-Variable DETAILS_FUNCTIONALACCOUNT_01 -Option Constant -Value "Functional account not found"
Set-Variable DETAILS_MANAGEDACCOUNT_01 -Option Constant -Value "Managed Account not found"
Set-Variable DETAILS_MANAGEDSYSTEM_01 -Option Constant -Value "Managed System not found"
Set-Variable DETAILS_PLATFORM_01 -Option Constant -Value "Platform is not found"
Set-Variable DETAILS_REQUEST_01 -Option Constant -Value "RequestID is not found"
Set-Variable DETAILS_REQUEST_02 -Option Constant -Value "Cannot find system/account for new request (systemID={0}, accountID=(1))"
#>


class SymantecPamException : Exception {
    [string] $Details

    SymantecPamException($Message) : base($Message) {
        $this.Details= ""
    }
    SymantecPamException($Message, $Details) : base($Message) {
        $this.Details= $Details
    }
}

# --- end-of-file ---