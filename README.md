# SymantecPAM SPIX

Many years ago, a tool named **xsie** was available for exporting and importing data to and from Xceedium Xsuite PAM. The name **xsie** stood for **Xs**uite **I**mport **E**xport. It did not support all PAM data types but focused mainly on Credential Management for Xsuite and later CA PAM. xsie was tested only up to version 3.2. Since then, Xsuite/CA PAM has become Symantec PAM and has undergone many changes.

The tool described here is **SPIX** — **S**ymantec **P**AM **I**mport **E**xport. It offers functionality similar to xsie but also supports enhancements added in newer Symantec PAM releases.

Symantec PAM includes native CSV-based export/import features for certain object types, but Credential Management is not included. **SPIX** fills this gap by supporting export/import of Credential Management data using CSV files. **SPIX** is implemented in PowerShell, while xsie was written in Perl.

**SPIX** uses both CLI and API calls to export and import Symantec PAM data. The CLI/API users and their assigned permissions determine what can be exported, created, updated, or deleted. **SPIX** will never perform an operation that the authenticated user is not authorized for.

Three PowerShell scripts are provided:

- **SPIX-Config**  
Generates a properties file containing login credentials for the CLI and API.

- **SPIX**  
The main export/import script, including the SymantecPAM module.

- **SPIX-Password**  
Encrypts and decrypts passwords using the same mechanism used during export.

## Environment

**SPIX** has been tested in the following environment:

- Symantec PAM 4.3
- PowerShell 5.1 and 7.5
- Windows 11 and Windows Server 2022

It has **not** been tested on PowerShell for Linux. The password-protection mechanism used in the properties file may not work on Linux.

## Setting Up Credentials Properties

**SPIX** uses Symantec PAM’s CLI and, in some cases, the API to read and update Credential Management information. Both require basic authentication, and these credentials are stored in a properties file created by **SPIX-Config**. The properties file also contains basic environment settings.

Edit SPIX-Config.ps1 to fit your environment. The tcf variable lists Custom Connector names (case-sensitive). Both the CLI user and API user must already exist in PAM. The CLI user is a normal user; the API user is an ApiKey assigned to the same user and should have matching permissions.

The `delimiter` setting defines the CSV delimiter. Depending on Windows locale settings, this may need to be changed. If not set, it defaults to a comma (`,`).

The `limit` settomg defines the maximum number of items returned by CLI/API queries. Since PAM does not support paging, items beyond this limit are not retrieved.

The `tcf` settomg defines names (case-sensitive) for all Custom Connectors used in Symantec PAM.


```
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
}

```

**SPIX-Config** creates the properties file in `C:\Temp`. The filename includes the hostname and username, which PowerShell uses for encrypting stored passwords.  
**Important:** The encryption key is tied to the machine and the user account that created the file. The properties file cannot be moved to another system or used by another user.

By default, **SPIX** looks for the properties file in the current directory. You may override this using a command-line parameter.


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
| &#8209;ConfigPath&nbsp;\<path> | Path where configuration properties file is located. Default: `.\` |
| &#8209;OutputPath&nbsp;\<path> | Path where exported files are stored. Default: `.\SPIX-output` |
| &#8209;Category&nbsp;\<category> | One or more categories to export. Available options are<br/>**ALL**<br/>**Target** (TargetServer, TargetApplication, TargetAccount)<br/>**A2A** (RequestServer, RequestScript, Authorization)<br/>**Proxy**<br/>**Policy** (PCP, PVP, SSHKeyPairPolicy, JIT or CustomWorkflow)<br/>**UserGroup** (Filter, Group, Role, User, UserGroup)<br/>**Secret** (Vault, VaultSecret)<br/>**AccessPolicy**<br/>**Service**<br/>**Device** |
| &#8209;SrvName&nbsp;\<filter> | Filter by server name for categories `Target`, `TargetServer`, `TargetApplication` and `TargetAccount`.<br/>Supports `*`. |  
| &#8209;AppName&nbsp;\<filter> | Filter by application name for categories `Target`, `TargetApplication` and `TargetAccount`.<br/>Supports `*`. |  
| &#8209;AccName&nbsp;\<filter> | Filter by account name for categories `Target` and `TargetAccount`.<br/>Supports `*`.  |  
| &#8209;ExtensionType&nbsp;\<ext> | Filter by extension type for categories `Target`, `TargetApplication` and `TargetAccount`.<br/>Supports `*`. |  
| &#8209;ShowPassword | Used with categories `Target` and `TargetAccount`. Retrieve password for target accounts and export it in clear text in the CSV file. If the Password View Policy (PVP) used for the target account uses options for checkout, appovals or e-mail notifications, the PVP is temporarely changed to **SPIX-PVP** before the password is retrieved from PAM. If this PVP does not exist it is created. |  
| &#8209;Passphrase&nbsp;\<passphrase> | Used with `-ShowPassword`. Encrypts exported passwords with key derived from passphrase. If the `passphrase` is empty ('') the user is prompted to enter a passphrase. |  
| &#8209;Delimiter&nbsp;\<character> | Delimiter character used when writing CSV files. This option will overrule the settings in the properties file. |  
| &#8209;Compress | Creates a single file for TargetApplication and TargetAccounts (no extension-specific attributes or passwords). |  
| &#8209;Quiet | reduce console output. |  

When `-ShowPassword` is used, SPIX temporarily assigns a special Password View Policy (SPIX-PVP) to bypass checkout, approval, or notification settings. If **SPIX-PVP** does not exist, it is created. It remains in PAM after the export and can be manually removed.

### Extension types

Built-in extnsion tyes are

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


Custom connector names from the `tcf` property are also supported (case-sensitive).



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

This command will export passwords on TargetAccounts. The user is prompted to enter a passphrase (option **-passphrase** uses `''` or `""` as argument). The passphrase is hashed and the hash is used to derive the encryption key. The encryption itself uses a random salt value and two identical passwords will result in different encrypted passwords. Encrypted passwords are prefixed with '{enc}'. The script `SPIX-Password` can generate encrypted passwords, which can be used when importing a CSV file securely.

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
| &#8209;ConfigPath&nbsp;\<path> | Path to the properties file. Default: `.\` |
| &#8209;InputFile&nbsp;\<filename> | CSV file to import. |
| &#8209;Passphrase&nbsp;\<passphrase> | Decrypts encrypted passwords. If empty (`''`or `""`), prompts for input. |  
| &#8209;UpdatePassword | When creating a new TargetAccounts with a known endpoint password, updates it to generated password after creation. |  
| &#8209;Delimiter&nbsp;\<character> | Overrides delimiter from properties file. |  
| &#8209;Quiet | Reduce console output. |  

### Generate new random password

When importing **TargetAccount** entries, setting the **password** column to `_generate_pass_` instructs PAM to generate a password according to the associated Password Change Policy (PCP).

`-UpdatePassword` is used when the endpoint's current password is known and must be replaced immediately after the account is created.


### Import CSV

All exported CSV file contain **ID**, **ObjectType**, and **Action**. These files can be used as import file templates.

Valid **Action** values:

- **New** — Creates a new object of the specified **ObjectType**. The remaining columns describe the new object and include all the necessary parameters.
- **Update** - Updates an existing object identified by **ID** and **Name**.
- **Remove** - Deletes the object.
- **Empty** - Row is ignored.


![Export/Import CSV](/Docs/SPIX-Export.png)


### Limitations

Import is supported for:

**Authorization**, **PCP**, **Proxy**, **PVP**, **RequestScript**, **RequestServer**, **Role SSHKeyPairPolicy**, **TargetAccount**, **TargetApplication**, **TargetServer**, and **UserGroup**.

Proxies cannot be created cia CLI/API - They register automatically when started first time.

Other ojectTypes can be exported but not imported. PAM already provides import mecanism.

### Errors During Import

If a row fails during import, **SPIX** writes that row to a separate error CSV file and appends an **ErrorMessage** column describing the failure. Successfully processed rows are not included. The script displays the name of the error file.

# SPIX Password

**SPIX-Password** encrypts and decrypts passwords using a passphrase. Decrypting an encrypted passwords must begin with `{enc}`. If `-Passphrase` is not provided or is empty (`''` or `""`), the user is prompted.


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

The encrypted password must start with `{enc}`.


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

