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

SPIX -Help

## Export

SPIX **-Export** [-ConfigPath \<path>] [-OutputPath \<path>] [-Category \<category>] [-SrvName \<filter>] [-AppName \<filter>] [-AccName \<filter>] [-ExtensionType \<name>] [-ShowPassword] [-Key \<passphrase>] [-Quiet]


| Parameter | Description |
| :---- | :---- |
| &#8209;ConfigPath&nbsp;\<path> | Path where configuration properties file is located. Default is current directory `.\` |
| &#8209;OutputPath&nbsp;\<path> | Path where exported files are stored. Default is `.\SPIX-output`. |
| &#8209;Category&nbsp;\<category> | One or more categories to export. Available options are<br/>**ALL**<br/>**Target**<br/>- TargetServer<br/>- TargetApplication<br/>- TargetAccount<br/>**A2A**<br/>- RequestServer<br/>- RequestScript<br/>- Authorization<br/>- Proxy<br/>**Policy**<br/>- PCP<br/>- PVP<br/>- JIT or CustomWorkflow<br/>- SSHKeyPairPolicy<br/>**UserGroup**<br/>- User<br/>- Role<br/>- Filter<br/>- Group<br/>**Secret**<br/>- Vault<br/>- VaultSecret<br/>AccessPolicy<br/>Service<br/>Device |
| &#8209;SrvName&nbsp;\<filter> | Used with Category `Target`, `TargetServer`, `TargetApplication` and `TargetAccount`.<br/>Specify a hostname for the target server. Wildcard `*` can be used. |  
| &#8209;AppName&nbsp;\<filter> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an application name for the target application. Wildcard `*` can be used. |  
| &#8209;AccName&nbsp;\<filter> | Used with Category `Target` and `TargetAccount`.<br/>Specify an account name (username) for the target account. Wildcard `*` can be used. |  
| &#8209;ExtensionType&nbsp;\<ext> | Used with Category `Target`, `TargetApplication` and `TargetAccount`.<br/>Specify an extension for application and account to export. Wildcard `*` can be used. |  
| &#8209;ShowPassword | Used with Category `Target` and `TargetAccount`. Retrieve target account password and store it in clear text in the export file. If the PVP uses options to checkout, appovals or e.mail notifications, the PVP is temporarely changed before the password is fetched. |  
| &#8209;Key&nbsp;\<passphrase> | Used together with `-ShowPassword`. If the `encryptionn passphrase` is empty "", the user is prompted to enter a password.<br/>Passwords are fetched and encrypted using an encryption key derived from the passphrase. |  
| &#8209;Quiet | Less output when running SPIX |  

### Example

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


```
PS W:\> .\SPIX.ps1 -Export -Category TargetAccount -ExtensionType windowsDomainService -ShowPassword -Key ""
Exporting TargetAccount
... windowsDomainService
Run time: 2 seconds
Done
PS W:\>
```



