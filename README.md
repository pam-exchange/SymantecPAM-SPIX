# SymantecPAM SPIX

Many years ago, a tool named **xsie** was available for exporting information from and importing information to Xceedium Xsuite PAM. The name **xsie** stood for **Xs**uite **I**mport **E**xport. Not everything could be exported/imported, but specifically, the Credential Management part of Xsuite and its successor, CA PAM. **xsie** was tested with Xsuite/CA PAM up until version 3.2. Xsuite/CA PAM was later rebranded to Symantec PAM, and many updates and enhancements have been added since version 3.2. The tool described here is **S**ymantec **P**AM **I**mport **E**xport, or simply **SPIX**. It provides similar functionality to **xsie**, but it also covers enhancements added to Symantec PAM.

Symantec PAM has built-in export/import functionality using CSV files for some types of information in PAM. However, this does not cover Credential Management information, which **SPIX** can be used to export/import via CSV files. **SPIX** is written in PowerShell, whereas **xsie** was written in Perl.

**SPIX** uses both CLI and API calls for exporting and importing information in Symantec PAM. It relies on CLI/API users and the permissions they have in Symantec PAM. The permissions granted to the CLI/API users will determine how much information can be exported, as well as whether creating, updating, or deleting is possible with **SPIX**. The tool does not allow actions in PAM that the CLI/API user does not have permission to perform.

There are three PowerShell scripts available:

- **SPIX-Config**  
  Script for generating a properties file with login credentials for CLI and API.
  
- **SPIX**  
  The import/export script, including the SymantecPAM module.
  
- **SPIX-Password**  
  When exporting passwords, these can be stored as plain text or encrypted using a passphrase. This tool uses the same encryption mechanism to both encrypt and decrypt passwords.

## Environment

**SPIX** has been tested in the following environment:

- Symantec PAM version 4.3
- PowerShell 5.1 and 7.5
- Windows 11 and Windows Server 2022

It has not been tested with PowerShell on Linux. It is unknown whether the mechanism for protecting CLI/API user passwords (see below) works in a Linux environment.

## Setting Up Credentials Properties

**SPIX** uses the CLI and, occasionally, the API when reading or updating credential management information. Both use basic authentication (username/password), and these credentials are stored in a properties file. **SPIX-Config** is used to create this file, which contains basic configuration for the Symantec PAM environment and the necessary CLI and API users and passwords.

Edit the **SPIX-Config.ps1** file to match your environment. The **tcf** variable is used to name any Custom Connectors that may be available. Note that the names of Custom Connectors are case-sensitive. Both the CLI and API users must exist in PAM. The CLI user is a regular user, and the API user is an ApiKey. The ApiKey is best assigned to the user and should have the same permissions as the CLI user.

The delimiter specifies how CSV files are created and read. Depending on the region and language settings of Windows, a delimiter value may need to be specified. If no delimiter is specified, the default value is `,`.

The **limit** controls how many entries can be returned when calling the CLI/API. There is no paging mechanism available when reading information from PAM. If there is more information available, it will not be visible to **SPIX**.

```powershell
$configSymantecPAM = @{
  type = "SymantecPAM"
  DNS = "192.168.xxx.yyy"
  
  cliUsername = "symantecCLI"
  cliPassword = "xxxxxxxxxxx"
  
  apiUsername = "symantecAPI-131001"
  apiPassword = "xxxxxxxxxxx"
  
  tcf = ("keystorefile", "configfile", "mongodb", "postgresql", "pamuser")
  limit = 100000
  delimiter = ";"
}```

**SPIX-Config** will generate a properties file in `C:\Temp`. The filename will include the hostname and username. This information is used when PowerShell encrypts the passwords in the properties file.<br/>
**Note:** The encryption key used to protect the passwords in the properties file is tied to a specific computer and the user running **SPIX-Config**. As a result, the properties file will only work on the same system and for the same user who generated it. In other words, the properties file cannot be transferred to a different server or used by a different user.

**SPIX** will look for the properties file in the current directory by default. The location of the properties file can be changed using a command-line parameter.


# Running SPIX

## Help

```
SPIX -Help
```

Will show a brief description of parameters.


## Export

SPIX **-Export** [&#8209;ConfigPath \<path>] [&#8209;OutputPath \<path>] [&#8209;Category \<category>] [&#8209;SrvName \<filter>] [&#8209;AppName \<filter>] [&#8209;AccName \<filter>] [&#8209;ExtensionType \<name>] [&#8209;ShowPassword] [&#8209;Passphrase \<passphrase>] [&#8209;Compress] [&#8209;Delimiter \<character>] [&#8209;Quiet]


| Option | Description |
| :---- | :---- |
| &#8209;ConfigPath&nbsp;\<path> | Path where configuration properties file is located. Default is current directory `.\` |
| &#8209;OutputPath&nbsp;\<path> | Path where exported files are stored. Default is `.\SPIX-output`, which will be created if it does not exist. |
| &#8209;Category&nbsp;\<category> | One or more categories to export. Available options are<br/>**ALL**<br/>**Target** (TargetServer, TargetApplication, TargetAccount)<br/>**A2A** (RequestServer, RequestScript, Authorization)<br/>**Proxy**<br/>**Policy** (PCP, PVP, SSHKeyPairPolicy, JIT or CustomWorkflow)<br/>**UserGroup** (Filter, Group, Role, User, UserGroup)<br/>**Secret** (Vault, VaultSecret)<br/>**AccessPolicy**<br/>**Service**<br/>**Device** |
| &#8209;SrvName&nbsp;\<filter> | Used with Category `Target`, `TargetServer`, `TargetApplication` and `TargetAccount`.<br/>Specify a hostname as filter for target servers. Wildcard `*` can be used. |  
| &#8209;AppName&nbsp;\<filter> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an application name as filter for target applications. Wildcard `*` can be used. |  
| &#8209;AccName&nbsp;\<filter> | Used with Category `Target` and `TargetAccount`.<br/>Specify an account name (username) as filter for target accounts. Wildcard `*` can be used. |  
| &#8209;ExtensionType&nbsp;\<ext> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an extension for application and account types to export. Wildcard `*` can be used. |  
| &#8209;ShowPassword | Used with Category `Target` and `TargetAccount`. Retrieve password for target accounts and export it in clear text in the CSV file. If the Password View Policy (PVP) used for the target account uses options for checkout, appovals or e-mail notifications, the PVP is temporarely changed to 'SPIX-PVP' before the password is retrieved from PAM. If the PVP does not exist it is created. |  
| &#8209;Passphrase&nbsp;\<passphrase> | Used together with the option `-ShowPassword`. If the `passphrase` is empty (''), the user is prompted to enter a passphrase.<br/>Passwords fetched are encrypted using an encryption key derived from the passphrase. |  
| &#8209;Delimiter&nbsp;\<character> | Delimiter character used when writing CSV files. This option will overrule the settings in the properties file. |  
| &#8209;Compress | Used when exporting TargetApplication and TargetAccounts. Instead of creating CSV files for each extensionType, this option will create a single file without attributes specific for extensionTypes for TargetApplications and TargetAccounts. Such a file does not will not include passwords for TargetAccounts. |  
| &#8209;Quiet | Less output when running SPIX |  

When retrieving account passwords (using the `-ShowPassword` option), the current PVP (Password View Policy) applied to an account may have settings for check-out, notifications, and similar actions. These settings should not apply when exporting passwords. Therefore, a new PVP is created and assigned to the account when the password is retrieved. This temporary PVP is named `SPIX-PVP` and will remain in PAM after **SPIX** has completed the export of target account passwords. It can be manually deleted and, if needed, will be recreated the next time **SPIX** is used for exporting target accounts and their associated passwords.

The available values for **extensionType** include the built-in connectors:

- activeDirectorySshKey
- AS400
- AwsAccessCredentials
- AwsApiProxyCredentials
- AzureAccessCredentials
- CiscoSSH
- Generic
- genericSecretType
- HPServiceManager
- juniper
- ldap
- mssql
- mssqlAzureMI
- nsxcontroller
- nsxmanager
- nsxproxy
- oracle
- PaloAlto
- RadiusTacacsSecret
- remedy
- ServiceDeskBroker
- ServiceNow
- SPML2
- sybase
- unixII
- vcf
- vmware
- weblogic10
- windows
- windowsDomainService
- windowsRemoteAgent
- windowsSshKey
- windowsSshPassword
- XsuiteApiKey

**Additionally**, custom connector names specified in the `tcf` option of the properties file are also valid values. Keep in mind that these names are case-sensitive.



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

This command will export passwords on TargetAccounts. The user is prompted to enter a passphrase (option **-passphrase** uses a "" as argument). The passphrase is hashed and the hash is used to derive the encryption key. The encryption itself uses a random salt value and two identical passwords will result in different encrypted passwords. Encrypted passwords are prefixed with '{enc}'. The script `SPIX-Password` can generate encrypted passwords, which can be used when importing a CSV file securely.

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

This command will export accounts using **-ShowPassword** without having a passphrase on the command line. If a passphrase is provided on the command line, the user is not prompted to enter a passphrase.<br/>**Note** that Powershell ISE (version 5.1) will prompte the user for a passphrase in a seperate pop-up window.

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

SPIX **-Import** [&#8209;ConfigPath \<path>] [&#8209;InputFile \<filename>] [&#8209;Passphrase \<passphrase>] [&#8209;UpdatePassword] [&#8209;Delimiter \<character>] [&#8209;Quiet]

| Option | Description |
| :---- | :---- |
| &#8209;ConfigPath&nbsp;\<path> | Path where configuration properties file is located. Default is current directory `.\` |
| &#8209;InputFile&nbsp;\<filename> | Filename with import information. |
| &#8209;Passphrase&nbsp;\<passphrase> | When a password in the import CSV file is encrypted, it is decrypted using the passphrase before being created or updated. If the `passphrase` is empty "", the user is prompted to enter a passphrase. |  
| &#8209;UpdatePassword | Flag used when creating a new TargetAccounts. If an account in the input CSV has a password different from `_generate_pass_`, SPIX will attempt to generate a new password after the account has been added. |  
| &#8209;Delimiter&nbsp;\<character> | Delimiter character used when writing CSV file. This option will overrule the settings in the properties file |  
| &#8209;Quiet | Less output when running SPIX |  

### Generate new random password

When importing a file with an ObjectType of `TargetAccount`, it is possible to let PAM generate a new random password. This is useful when performing the **New** and **Update** actions. To trigger this, set the value in the `password` column to `_generate_pass_`. This instructs PAM to generate a new password according to the Password Change Policy (PCP) defined for the target application.

The `-UpdatePassword` option is used when creating a new `TargetAccount` and a known password is provided for the endpoint. After the account is created, the password is updated to a new random value using `_generate_pass_`. A typical use case for this is when adding an account to PAM where the password on the endpoint is known, and the account is responsible for changing its own password (i.e., there is no other account specified). If another account is specified, it is recommended to use `_generate_pass_` as the password for the new account.

### Import CSV

The exported CSV file will always include the following columns: **ID**, **ObjectType**, and **Action**. This CSV file can serve as a template when importing data.

The available values for the **Action** column are as follows:

- **New**  
  Creates a new object of the specified **ObjectType**. The remaining columns describe the new object and include all the necessary parameters.

- **Update**  
  Updates the existing object identified by its **ID** and **Name**. The parameters to be updated are specified in the remaining columns and depend on the object type.

- **Remove**  
  Removes or deletes the object identified by its **ID** and **Name**.

- **Empty**  
  If the action column in a row is empty, it will be ignored during the import process.




![Export/Import CSV](/Docs/SPIX-Export.png)


### Limitations

Import functionality is available for the following ObjectTypes: **Authorization**, **PCP**, **Proxy**, **PVP**, **RequestScript**, **RequestServer**, **Role SSHKeyPairPolicy**, **TargetAccount**, **TargetApplication**, **TargetServer**, and **UserGroup**.

Please note that it is not possible to create (New) a proxy using a CLI command. A proxy is automatically registered when it is installed and started for the first time.

There are additional ObjectTypes that can be exported to CSV files. However, either an import mechanism is not available for these ObjectTypes, or an import functionality is already built into Symantec PAM.

### Errors During Import

If an error occurs during the import of a CSV file, the problematic row is written to a new CSV file. The error details are included in an additional column named `ErrorMessage`, which provides specifics about the error for that particular row. Rows that are processed successfully will not appear in the new CSV file. A message indicating the filename of the generated error CSV file will be displayed in the console.

# SPIX Password

The utility `SPIX-Passwpord` is available for encrypting and decrypting a password using a passphrase. Both the encrypted and decrypted password are shown on the console. Encrypted password is or must be prefixed with `{enc}`.

If the option **-Passphrase** is not used of has an empty value (''), the user is prompted for the passphrase.


## Encrypt a password

Create an encrypted password using this command

```
.\SPIX-Password.ps1 -Passphrase <passphrase> -Password <password> 
```

Note that even when using the same password and same passphrase will give different encrypted passwords.


## Decrypt an encrypted password

Decrypte an encrypted password using this command.

```
.\SPIX-Password.ps1 -Passphrase <passphrase> -EncryptedPassword <encrypted password> 
```

The encrypted password must start with '{enc}'.


## Example

```
PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -Password 'HelloWorld'
{enc}FMoZGS3utUnmQDKEa3shLLEImWiZ6Ol0MgqL7VFdTSuXYU5eQAaN/v+Z7/XgZPJT

PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -Password 'HelloWorld'
{enc}IG0Zf2BODJkHKgrwIJsbjFf369d4XWbw1oFFHd8KTPNhF9MISBLt70yLeGDyrVXP

PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -Password 'HelloWorld'
{enc}ElYk9EjTIjbC7/yApiRLm+tqX9TDKH9oP/Gg9Il3cnG5dGMlGd+sg4Eych1aJaZ2

PS W:\> .\SPIX-Password.ps1 -Passphrase 'MyPassphrase' -EncryptedPassword '{enc}ElYk9EjTIjbC7/yApiRLm+tqX9TDKH9oP/Gg9Il3cnG5dGMlGd+sg4Eych1aJaZ2'
HelloWorld

```

