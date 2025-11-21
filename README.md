# SymantecPAM SPIX

Many years ago a tool named **xsie** used for exporting and importing information to the Credential Management part of Xceedium (now Symantec PAM) was available as a Perl script. 

The tool SPIX has a similar functionality as the original xsie tool.

Main purpose is to allow export of SymantecPAM credentials management information into CSV files, using names instead of internal IDs returned from the CLI commands. For example when refering to a master account for password change, the CLI returns an ID of the account. SPIX will convert the internal ID to names and use these in the CSV file. Also included in SPIX is an import functionality, where a CSV file can be used to bulk import new entries or to update existing entries. 

SPIX uses the CLI and API for finding and updating information in the credential management part of Symantec PAM. It uses a login user for CLI commands and an API key for API calls. 

There are three Powershell scripts available. 

- SPIX-Config.ps1  
Script for generating a properties file with login credentials to CLI and API
- SPIX.ps1  
The import/export script
- SPIX-Password.ps1  
When exporting passwords, these can be as plain text or encrypted using a passphrase. This tool is using the same encryption mechanism to decrypt and encrypt passwords. 


# Environment

SPIX has been tested using the following environment

- Symantec PAM version 4.3
- Powershell 5.1 and 7.5
- Windows 11 and Windows Server 2022


# Setup credentials properties

The SPIX tool is using the CLI and occationally the API when reading or updating credential management information. Both of these uses basic authentication (username/password) and these are stored in a properties file. The script SPIX-Config is used to create such a properties file with basic configuration of the Symantec PAM encironment, the necessary CLI and API users and passwords. 

Edit the file SPIX-Config.ps1 such that it is matching you environment. The `tcf` variable is used to name any Custom Connectors available. The CLI user must exist as a login user in PAM and the API key is assigned to the user. The ID suffix of the API key is assigned when the user is created. 
Default CSV file delimiter is ',' and should be set to match the region/language setting for Excel or whatever program is used to view CSV files.

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

SPIX-Config.ps1 will generate a properties file in `C:\Temp` where the passwords are encrypted using Powershell mechanism for encryption of passwords. The encryption is fixed to a specific computer and user running the SPIX-Config script and subsequently the SPIX script. 

By default the SPIX.ps1 script will look for the file in the current directory, but it can be changed using a command line parameter.

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
| &#8209;OutputPath&nbsp;\<path> | Path where exported files are stored. Default is `.\SPIX-output`, which will be created if it does not exist. |
| &#8209;Category&nbsp;\<category> | One or more categories to export. Available options are<br/>**ALL**<br/>**Target** (TargetServer, TargetApplication, TargetAccount)<br/>**A2A** (RequestServer, RequestScript, Authorization)<br/>**Proxy**<br/>**Policy** (PCP, PVP, SSHKeyPairPolicy, JIT or CustomWorkflow)<br/>**UserGroup** (Filter, Group, Role, User, UserGroup)<br/>**Secret** (Vault, VaultSecret)<br/>**AccessPolicy**<br/>**Service**<br/>**Device** |
| &#8209;SrvName&nbsp;\<filter> | Used with Category `Target`, `TargetServer`, `TargetApplication` and `TargetAccount`.<br/>Specify a hostname for the target server. Wildcard `*` can be used. |  
| &#8209;AppName&nbsp;\<filter> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an application name for the target application. Wildcard `*` can be used. |  
| &#8209;AccName&nbsp;\<filter> | Used with Category `Target` and `TargetAccount`.<br/>Specify an account name (username) for the target account. Wildcard `*` can be used. |  
| &#8209;ExtensionType&nbsp;\<ext> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an extension for application and account to export. Wildcard `*` can be used. |  
| &#8209;ShowPassword | Used with Category `Target` and `TargetAccount`. Retrieve target account password and store it in clear text in the export file. If the PVP uses options to checkout, appovals or e.mail notifications, the PVP is temporarely changed to 'SPIX-PVP' before the password is fetched.|  
| &#8209;Passphrase&nbsp;\<passphrase> | Used together with `-ShowPassword`. If the `passphrase` is empty "", the user is prompted to enter a passphrase.<br/>Passwords are fetched and encrypted using an encryption key derived from the passphrase. |  
| &#8209;Delimiter&nbsp;\<character> | Delimiter character used when writing CSV file. This option will overrule the settings in the properties file. |  
| &#8209;Quiet | Less output when running SPIX |  


When retrieving account passwords (option `-ShowPassword`) the current PVP used on an account may have options for check-out, notifications and the like. Such settings should not apply when retrieving passwords for export and a new PVP is created and assigned to the account when the password is retrieved. The extra PVP is named `SPIX-PVP` and will be kept in PAM after SPIX has completed its export of target account passwords. It can be deleted manually and will be created next time SPIX is exporting target account passwords.

Available values for **extensionType** are the built-in connectors:  
activeDirectorySshKey, AS400, AwsAccessCredentials, AwsApiProxyCredentials, AzureAccessCredentials, CiscoSSH, Generic, genericSecretType, HPServiceManager, juniper, ldap, mssql, mssqlAzureMI, nsxcontroller, nsxmanager, nsxproxy, oracle, PaloAlto, RadiusTacacsSecret, remedy, ServiceDeskBroker, ServiceNow, SPML2, sybase, unixII, vcf, vmware, weblogic10, windows, windowsDomainService, windowsRemoteAgent, windowsSshKey, windowsSshPassword, XsuiteApiKey

**plus** names for all Custom Connectors specified in the properties file.


### Examples

```
.\SPIX -Export -Category Target -ExtensionType Windows*
```

Will export TargetServer, TargetApplication and TargetAccount, but only where the extensionType starts with **windows**. The output directory is `.\SPIX-output` and configuration file is current directory `.\`.

This example will fetch **Targets**, i.e. TargetServer, TargetApplication and TargetAccount, but only where the extensionType starts with 'windows'.

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
```

This command will fetch **TargetServer**, **TargetApplication** and **PCP**, but TargetApplication only where the extensionType starts with 'windows'.

```
PS W:\> .\SPIX.ps1 -Export -Category TargetServer,TargetApplication,PCP -ExtensionType windows*
Exporting TargetServer
Exporting TargetApplication
... windows
... windowsDomainService
... windowsRemoteAgent
... windowsSshKey
... windowsSshPassword
Exporting PCP
Run time: 1 seconds
Done
```

This command will passwords and the user is prompted to enter a passphrase (-passphrase uses a "" as argument). The passphrase is hashed and the hash is used as encryption key. The encryption itself uses a random salt value and two identical passwords will use different encrypted passwords. Exporting twice will also result in different encrypted passwords. Encrypted passwords are prefixed with '{enc}'. The script `SPIX-Password` can generate encrypted passwords, which can be used when importing a CSV file.

```
PS W:\> .\SPIX.ps1 -Export -Category TargetAccount -ExtensionType windowsDomainService -ShowPassword -Passphrase ""
Exporting TargetAccount
... windowsDomainService
Run time: 2 seconds
Done
```

This command will export target account where the extension type is 'windowsDomainService' and the application name contains the word 'breakglass'.

```
PS W:\> .\SPIX.ps1 -Export -Category TargetAccount -ExtensionType windowsDomainService -ShowPassword -AppName *breakgæass*
Exporting TargetAccount
... windowsDomainService
Run time: 2 seconds
Done
```

This command will export accounts using -ShowPassword without having a passphrase on the command line. If a passphrase is provided on the command line, the user is not prompted to enter a passphrase. **Note** that Powershell ISE (version 5.1) will prompte the user for a passphrase in a seperate pop-up window.

```
PS W:\> .\SPIX.ps1 -export -Category TargetAccount -ExtensionType windowsDomainService -ShowPassword -Passphrase ''
Enter encryption passphrase: ***********
Confirm encryption passphrase: ***********
Exporting TargetAccount
... windowsDomainService
Run time: 12 seconds
Done
```


## Import

```
SPIX -Import [-ConfigPath <path>] [-InputFile <filename>] [-Synchronize] [-Passphrase <passphrase>] [-Delimiter <character>] [-Quiet]
```

| Parameter | Description |
| :---- | :---- |
| &#8209;ConfigPath&nbsp;\<path> | Path where configuration properties file is located. Default is current directory `.\` |
| &#8209;InputFile&nbsp;\<filename> | Filename with import information. |
| &#8209;Synchronize | Flag used when creating new accounts. PAM will try to synchronize the account when it is added. |  
| &#8209;UpdatePassword | Flag used when creating new accounts.<br/>This flag is only relevant when creating a new account and the new account does **not** use an otherAccount for password update. PAM will synchronize the current password (provided) and change the password to a new random value. If the account uses an otherAccount, set the target account password for the new account to `_generate_pass_`. |  
| &#8209;Passphrase&nbsp;\<passphrase> | Used when updating existing accounts. The password in the import file is encrypted using the passphrase given. If the `passphrase` is empty "", the user is prompted to enter a passphrase. |  
| &#8209;Delimiter&nbsp;\<character> | Delimiter character used when writing CSV file. This option will overrule the settings in the properties file |  
| &#8209;Quiet | Less output when running SPIX |  

### Generate new random password

When importing a file with ObjectType TargetAccount, it is possible to let PAM generate a new random password. This is relevant when using the actions **New** and **Update**. Set value in the `password` column to `_generate_pass_`. This will tell PAM to generate a new password according to the PCP defined for the target application.


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
The row in the import CSV file is ignored.
 

![Export/Import CSV](/Docs/SPIX-Export.png)

Not all ObjectTypes and for TargetApplications and TargerAccounts the extensionType can be created or updated using the SPIX import mechanism.

### Limitations

Import is available for ObjectTypes **Authorization**,**PCP**,**Proxy**,**PVP**,**RequestScript**,**RequestServer**,**Role**,**SSHKeyPairPolicy**,**TargetAccount**,**TargetApplication**,**TargetServer** and **UserGroup**.

Other objectTypes may be available as exported CSV files, but they cannot be imported through SPIX.


### Errors during import

Should processing a rows result in an error, the row is written to a new file and a column `ErrorMessage` with details is added. 
Rows processed without errors will not appear in the new CSV file. A message is shown on the console with the exact filename for the new CSV file.

| Error | Description |
| :--- | _--- |
| Invalid parameters | PAM-CM-0579: Error. Attempt to create a duplicate entry. - Duplicate alias |
| Duplicate | Server '<hostname>' and application '<application Name>' already exist | 
| Invalid parameters | PAM-CM-0813: Account username may not contain whitespace characters. |


# SPIX Password

There is a utility named `SPIX-Passwpord` available for encrypting and decrypting a password using a passphrase. Both the encrypted and decrypted password are shown on the console. The encrypted password is prefixed with `{enc}`.

If the **-Passphrase** option is not provided, the user is prompted for the passphrase.


Encrypt:

```
.\SPIX-Password.ps1 -Passphrase <passphrase> -Password <password> 
```

Decrypt:

```
.\SPIX-Password.ps1 -Passphrase <passphrase> -EncryptedPassword <encrypted password> 
```

Example

```
PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -Password 'HelloWorld'
{enc}FMoZGS3utUnmQDKEa3shLLEImWiZ6Ol0MgqL7VFdTSuXYU5eQAaN/v+Z7/XgZPJT

PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -Password 'HelloWorld'
{enc}IG0Zf2BODJkHKgrwIJsbjFf369d4XWbw1oFFHd8KTPNhF9MISBLt70yLeGDyrVXP

PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -Password 'HelloWorld'
{enc}GhmDUPlD0v4Fvs27yUt2pEoMxdIhc4oeqDd5eHY8/sjZSfPx+xVm5M+HhX8zQMmp

PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -Password 'HelloWorld'
{enc}ElYk9EjTIjbC7/yApiRLm+tqX9TDKH9oP/Gg9Il3cnG5dGMlGd+sg4Eych1aJaZ2

PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -EncryptedPassword '{enc}ElYk9EjTIjbC7/yApiRLm+tqX9TDKH9oP/Gg9Il3cnG5dGMlGd+sg4Eych1aJaZ2'
HelloWorld

```

Note that using the same passphrase and same password will give different encrypted passwords.

