# SymantecPAM SPIX

Many years ago a tool named **xsie** was available for exporting from and importing information to Xceedium Xsuite PAM. Not everything, but specifically the Credential Management part of Xsuite. **xsie** was tested with Xsuite versioin 3.2 and there have been many updates and enhancements as it evolved to Symantec PAM. The tool in this repository is a newer version of **xsie** working with Symantec PAM version 4.3.

The tool SPIX has a similar functionality as the original xsie tool.

Symantec PAM has export/import functionality using CSV files. However, this does not completely cover the Credential Management parts and **SPIX** can be used to extract information and save this to CSV files. **SPIX** can also be used to import information from CSV files. The tool is written in Powershell and is available free to use.

When using **SPIX** it uses CLI and API calls to export and import information in Symantec PAM. **SPIX** will use the CLI/API users with the permissions they have in Symantec PAM, thus the permissions granted to the CLI/API users will determine if SPIX can retrieve ever7ything or if it has a limited functioinality in Symantec PAM. 

There are three Powershell scripts available. 

- **SPIX-Config.ps1**  
Script for generating a properties file with login credentials to CLI and API
- **SPIX.ps1**  
The import/export script
- **SPIX-Password.ps1**  
When exporting passwords, these can be as plain text or encrypted using a passphrase. This tool is using the same encryption mechanism to decrypt and encrypt passwords. 


# Environment

SPIX has been tested using the following environment

- Symantec PAM version 4.3
- Powershell 5.1 and 7.5
- Windows 11 and Windows Server 2022


# Setup credentials properties

**SPIX** uses the CLI and occationally the API when reading or updating credential management information. Both of these uses basic authentication (username/password) and these are stored in a properties file. **SPIX-Config** is used to create a properties file with basic configuration of the Symantec PAM encironment and the necessary CLI and API users and passwords. 

Edit the file **SPIX-Config.ps1** such that it is matching you environment. The **tcf** variable is used to name any Custom Connectors available. Note that the names of Custom Connectors are case sensitive. Both the CLI and API users must exist in PAM. The CLI user is a regular user and the API user is an ApiKey. It is best assigned to the user and should have the same permissions as granted to the CLI user. 
 
The delimiter is used to change how CSV files are created and read. Depending on the region and language settings of Windows a delimiter value can be specified. If the delimiter option is not specified the default value is `,`. 

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

**SPIX-Config** will generate a properties file in `C:\Temp`. The passwords are encrypted using Powershell mechanism for encryption of passwords. Note that the encryption key used is fixed to a specific computer and user running the **SPIX-Config** script and will only work on the specific computer and for the specific user. A properties file for the specific computer and user must exist when using **SPIX**.

By default **SPIX** will look for the properties file in the current directory. The location of a properties file can be changed with a command line parameter.

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

When retrieving account passwords (option `-ShowPassword`) the current PVP used on an account may have options for check-out, notifications and the like. Such settings should not apply when retrieving passwords for export and a new PVP is created and assigned to the account when the password is retrieved. The extra PVP is named `SPIX-PVP` and will be kept in PAM after **SPIX** has completed exporting of target account passwords. It can be deleted manually and will, if needed, be created next time **SPIX** is used for exporting target accounts and associated password.

Available values for **extensionType** are the built-in connectors:  
activeDirectorySshKey, AS400, AwsAccessCredentials, AwsApiProxyCredentials, AzureAccessCredentials, CiscoSSH, Generic, genericSecretType, HPServiceManager, juniper, ldap, mssql, mssqlAzureMI, nsxcontroller, nsxmanager, nsxproxy, oracle, PaloAlto, RadiusTacacsSecret, remedy, ServiceDeskBroker, ServiceNow, SPML2, sybase, unixII, vcf, vmware, weblogic10, windows, windowsDomainService, windowsRemoteAgent, windowsSshKey, windowsSshPassword, XsuiteApiKey

**plus** names for all Custom Connectors specified in the properties `tcf` option. Keep in mind that the names are case sensitive.


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

This command will export accounts using -ShowPassword without having a passphrase on the command line. If a passphrase is provided on the command line, the user is not prompted to enter a passphrase.<br/>**Note** that Powershell ISE (version 5.1) will prompte the user for a passphrase in a seperate pop-up window.

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

When importing a file with ObjectType TargetAccount, it is possible to let PAM generate a new random password. This is relevant when using the actions **New** and **Update**. Set the value in `password` column to `_generate_pass_`. This will tell PAM to generate a new password according to the PCP defined for the target application.

The option `-UpdatePassword` is used when creating a new TargetAccount when a known password is used at the end-point. After the account added a password update to a new random value using (**_generate_pass_**) is done. Typical use-case is when adding an account in PAM where the password on the end-point is known and the account changes its own password, i.e. there is no otherAccount specified. If there is an otherAccount specified, it is recommended using the account password `_generate_pass_`.

### Import CSV

The exported CSV file will always contain the columns **ID**, **ObjectType** and **Action**.
The CSV file can be used as a template when importing a CSV file. 

Available values for actions are

- **New**  
Will create a new object of the ObjectType. The remaining columns describes the new object and all the parameters necessary.

- **Update**  
Will update the object with the ID and Name. Parameters are found in the remaining columns and will depend on the type of object.

- **Remove**  
Will remove or delete the object with the ID and Name.

- Empty  
The row in the import CSV file is ignored.
 

![Export/Import CSV](/Docs/SPIX-Export.png)


### Limitations

Import is available for ObjectTypes **Authorization**, **PCP**, **Proxy**, **PVP**, **RequestScript**, **RequestServer**, **Role SSHKeyPairPolicy**, **TargetAccount**, **TargetApplication**, **TargetServer** and **UserGroup**.

Note that it is not possible to create (New) a proxy using a CLI command. A proxy is registered when it is installed and started first time.  

There are more objectTypes that may be exported to CSV files. Either there is no mechanism available for import or an import mechanism is already available in Symantec PAM.


### Errors during import

If there is an error importing a CSV file, the row giving an error is written to a new CSV file. The error shown is added as an extra column `ErrorMessage` with details about the error for the specific row. Rows processed without errors will not appear in the new CSV file. A message with the filename of the generated CSV file is shown on the console.


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

