# SymantecPAM SPIX

Many years ago a tool named **xsie** used for exporting and importing information to the Credential Management part of Xceedium (now Symantec PAM) was available as a Perl script. 

The tool SPIX is now available as a PowerShell script. It has a similar functionality as the original xsie tool.

SPIX uses the CLI and API for finding and updating information in the credential management part of Symantec PAM. It uses a login user for CLI commands and an API key for API calls. 

There are two Powershell scripts available. 

- SPIX-Config.ps1  
Script for generating a properties file with login credentials to CLI and API
- SPIX.ps1  
The import/export script


# Environment

SPIX has been tested using the following environment

- Symantec PAM version 4.3
- Powershell 5.1 and 7.5
- Windows 11 and Windows Server 2022


# Setup credentials properties

The script SPIX-Config is used to create a properties file containing PAM hostname, username for CLI and API as well as the corresponding password. This version of SPIX does not support using A2A client when fetching current password for CLI and API calls. 

Edit the file to match you environment. The `tcf` variable is containing any Custom Connectors used in the environment. The CLI user must exist as a login user in PAM and it must have an API key assigned. The ID of the API key is assigned when the user is created. 
Default delimiter is ',' and should be set to match the region/language setting for Excel or whatever program is used to view CSV files.


```
$configSymantecPAM = @{
	type="SymantecPAM"; 
	DNS= "192.168.xxx.yyy";

	cliUsername= "symantecCLI"; 
	cliPassword= "xxxxxxxxxxx";

	apiUsername= "symantecAPI-131001";
	apiPassword= "xxxxxxxxxxx";

	tcf= ("keystorefile","configfile","mongodb","postgresql","pamuser");
	delimiter= ";"
}
```

When running the SPIX-Config.ps1 script it will generate a properties file in `C:\Temp` where the passwords are encrypted using Powershell mechanism to protect the content. The encryption is fixed to a specific system and user running the configuration script. 

By default the SPIX.ps1 script will look for the file in the current directory.

# Running SPIX

## Help

```
SPIX -Help
```

Will show a brief description of parameters.


## Export

```
SPIX -Export [-ConfigPath <path>] [-OutputPath <path>] [-Category <category>] [-SrvName <filter>] [-AppName <filter>] [-AccName <filter>] [-ExtensionType <name>] [-ShowPassword] [-Passphrase <passphrase>] [-Delimiter <character>] [-Quiet]
```


| Parameter | Description |
| :---- | :---- |
| &#8209;ConfigPath&nbsp;\<path> | Path where configuration properties file is located. Default is current directory `.\` |
| &#8209;OutputPath&nbsp;\<path> | Path where exported files are stored. Default is `.\SPIX-output`. |
| &#8209;Category&nbsp;\<category> | One or more categories to export. Available options are<br/>**ALL**<br/>**Target** (TargetServer, TargetApplication, TargetAccount)<br/>**A2A** (RequestServer, RequestScript, Authorization)<br/>**Proxy**<br/>**Policy** (PCP, PVP, SSHKeyPairPolicy, JIT or CustomWorkflow)<br/>**UserGroup** (Filter, Group, Role, User, UserGroup)<br/>**Secret** (Vault, VaultSecret)<br/>**AccessPolicy**<br/>**Service**<br/>**Device** |
| &#8209;SrvName&nbsp;\<filter> | Used with Category `Target`, `TargetServer`, `TargetApplication` and `TargetAccount`.<br/>Specify a hostname for the target server. Wildcard `*` can be used. |  
| &#8209;AppName&nbsp;\<filter> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an application name for the target application. Wildcard `*` can be used. |  
| &#8209;AccName&nbsp;\<filter> | Used with Category `Target` and `TargetAccount`.<br/>Specify an account name (username) for the target account. Wildcard `*` can be used. |  
| &#8209;ExtensionType&nbsp;\<ext> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an extension for application and account to export. Wildcard `*` can be used. |  
| &#8209;ShowPassword | Used with Category `Target` and `TargetAccount`. Retrieve target account password and store it in clear text in the export file. If the PVP uses options to checkout, appovals or e.mail notifications, the PVP is temporarely changed to 'SPIX-PVP' before the password is fetched.|  
| &#8209;Passphrase&nbsp;\<passphrase> | Used together with `-ShowPassword`. If the `encryptionn passphrase` is empty "", the user is prompted to enter a password.<br/>Passwords are fetched and encrypted using an encryption key derived from the passphrase. |  
| &#8209;Delimiter&nbsp;\<character> | Delimiter character used when writing CSV file. This option will overrule the settings in the properties file. |  
| &#8209;Quiet | Less output when running SPIX |  


When retrieving account passwords (option `-ShowPassword`) the current PVP used on an account may have options for check-out, notifications and the like. Such settings should not apply when retrieving passwords for export and a new PVP is created and assigned to the account when the password is retrieved. The extra PVP is named `SPIX-PVP` and will be kept in PAM after SPIX has completed its export of target account passwords. It can be deleted manually and will be created next time SPIX is exporting target account passwords.

Available values for **extensionType** are:  
activeDirectorySshKey, AS400, AwsAccessCredentials, AwsApiProxyCredentials, AzureAccessCredentials, CiscoSSH, Generic, genericSecretType, HPServiceManager, juniper, ldap, mssql, mssqlAzureMI, nsxcontroller, nsxmanager, nsxproxy, oracle, PaloAlto, RadiusTacacsSecret, remedy, ServiceDeskBroker, ServiceNow, SPML2, sybase, unixII, vcf, vmware, weblogic10, windows, windowsDomainService, windowsRemoteAgent, windowsSshKey, windowsSshPassword, XsuiteApiKey

**plus** any Custom Connectors available in PAM.


### Examples

```
.\SPIX -Export -Category Target -ExtensionType Windows*
```

Will export TargetServer, TargetApplication and TargetAccount, but only where the extensionType starts with **windows**. The output directory is `.\SPIX-output` and configuration file is current directory `.\`.

```
PS W:\> .\SPIX.ps1 -Export -Category Target -ExtensionType windows* -ShowPassword
Exporting TargetServer
Exporting TargetApplication
... windows
... windowsDomainService
... windowsRemoteAgent
... windowsSshKey
... windowsSshPassword
Exporting TargetAccount
... windows
... windowsDomainService
... windowsRemoteAgent
... windowsSshKey
... windowsSshPassword
Run time: 2 seconds
Done
PS W:\>
```

The command above will fetch **Targets**, i.e. TargetServer, TargetApplication and TargetAccount, but only where the extensionType starts with 'windows'.

```
PS W:\> .\SPIX.ps1 -Export -Category TargetAccount -ExtensionType windowsDomainService -ShowPassword -Key ""
Exporting TargetAccount
... windowsDomainService
Run time: 2 seconds
Done
PS W:\>
```

The exported passwords must be encrypted (-key option), but no passphrase is given on hte command line. SPIX will prompt the user to enter a passphrase and confirm it before proceeding. The passphrase is hashed and the hash is used as encryption key. The encryption itself uses random salt value, such that two exports of the same account password will have different encrypted text.

```
PS W:\> .\SPIX.ps1 -Export -Category TargetAccount -ExtensionType windowsDomainService -ShowPassword -AppName *breakgæass*
Exporting TargetAccount
... windowsDomainService
Run time: 2 seconds
Done
PS W:\>
```

Export target account where the extension type is 'windowsDomainService' and the application name contains the word 'breakglass'.


## Import

```
SPIX -Import [-ConfigPath <path>] [-InputFile <filename>] [-Synchronize] [-UpdatePassword] [-Passphrase <passphrase>] [-Delimiter <character>] [-Quiet]
```


| Parameter | Description |
| :---- | :---- |
| &#8209;ConfigPath&nbsp;\<path> | Path where configuration properties file is located. Default is current directory `.\` |
| &#8209;InputFile&nbsp;\<filename> | Filename with import information. |
| &#8209;Synchronize | Flag used when creating new accounts. PAM will try to synchronize the account when it is added. |  
| &#8209;UpdatePassword | Flag used when creating new accounts. PAM will set the account password to a new random value according to the PCP used for the target application. |  
| &#8209;Key&nbsp;\<passphrase> | Used when updating existing accounts. The password in hte import file is encrypted using the passphrase given. If the `encryptionn passphrase` is empty "", the user is prompted to enter a password. |  
| &#8209;Delimiter&nbsp;\<character> | Delimiter character used when writing CSV file. This option will overrule the settings in the properties file |  
| &#8209;Quiet | Less output when running SPIX |  


### Import CSV

The exported CSV file will always contain a column **ID**, **ObjectType** and **Action**.
The CSV file can be used as a template for importing through a CSV file. 

Available actions are

- **New**  
Will create a new object of the ObjectType. The remaining columns describes the new object and all the parameters necessary.

- **Update**  
Will update the object with the ID and Name. Parameters are found in the remaining columns and will depend on the type of object.

- **Remove**  
Will remove or delete the object with the ID and Name.

- **Empty**  
The row in the CSV file is ignored.
 

![Export/Import CSV](/Docs/SPIX-Export.png)

Not all ObjectTypes and for TargetApplications and TargerAccounts the extensionType can be created or updated using the SPIX import mechanism.


# SPIX Password

There is a utility named `SPIX-Passwpord` available for encrypting and decrypting a password using a passphrase. Both the encrypted and decrypted password are shown on the console. The encrypted password is prefixed with `{enc}`.

If the **-key** option is not provided, the user is prompted for the passphrase.


Encrypt:

```
.\SPIX-Password.ps1 -Key <passphrase> -Password <password> 
```

Decrypt:

```
.\SPIX-Password.ps1 -Key <passphrase> -EncryptedPassword <encrypted password> 
```

Example

```
PS W:\> .\SPIX-Password.ps1 -Key 'MyPassphrase' -Password 'HelloWorld'
{enc}FMoZGS3utUnmQDKEa3shLLEImWiZ6Ol0MgqL7VFdTSuXYU5eQAaN/v+Z7/XgZPJT

PS W:\> .\SPIX-Password.ps1 -Key 'MyPassphrase' -Password 'HelloWorld'
{enc}IG0Zf2BODJkHKgrwIJsbjFf369d4XWbw1oFFHd8KTPNhF9MISBLt70yLeGDyrVXP

PS W:\> .\SPIX-Password.ps1 -Key 'MyPassphrase' -Password 'HelloWorld'
{enc}GhmDUPlD0v4Fvs27yUt2pEoMxdIhc4oeqDd5eHY8/sjZSfPx+xVm5M+HhX8zQMmp

PS W:\> .\SPIX-Password.ps1 -Key 'MyPassphrase' -Password 'HelloWorld'
{enc}ElYk9EjTIjbC7/yApiRLm+tqX9TDKH9oP/Gg9Il3cnG5dGMlGd+sg4Eych1aJaZ2

PS W:\> .\SPIX-Password.ps1 -Key 'MyPassphrase' -EncryptedPassword '{enc}ElYk9EjTIjbC7/yApiRLm+tqX9TDKH9oP/Gg9Il3cnG5dGMlGd+sg4Eych1aJaZ2'
HelloWorld

```

Note that using the same passphrase and same password will return different encrypted passwords.
