$version= "1.0.0"

$configSymantecPAM = @{
        type="SymantecPAM"; 
		DNS= "192.168.xxx.yyy";

		cliUsername= "symantecCLI"; 
		cliPassword= "xxxxxxxxxxx";

        apiUsername= "symantecAPI-131001";
        apiPassword= "xxxxxxxxxxx";

        tcf= ("keystorefile","configfile","mongodb","postgresql","pamuser");

        limit= 100000;
        delimiter= ";"
    }

try {
    Write-Host "Credentials start, version=$($version) -----------------------------------"

    $runHostname= $([System.Net.DNS]::GetHostByName('').hostname).ToLower()
    Write-Host "runHostname= $runHostname"

    $whoami= [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    $idx= $whoami.IndexOf("\")
    if ($idx -ge 0) {
        $whoami= $whoami.substring($whoami.IndexOf("\")+1)
    }
    Write-Host "WhoAmI= $whoami"

    #
    # prepare configSymantecPAM
    #
    if ($configSymantecPAM.cliPassword) {
        $securePassword= $configSymantecPAM.cliPassword | ConvertTo-SecureString -AsPlainText -Force 
        $configSymantecPAM.cliPassword= $securePassword | ConvertFrom-SecureString 
    }
    if ($configSymantecPAM.apiPassword) {
        $securePassword= $configSymantecPAM.apiPassword | ConvertTo-SecureString -AsPlainText -Force 
        $configSymantecPAM.apiPassword= $securePassword | ConvertFrom-SecureString 
    }

    #
    # Convert to Json and save to file
    # 
    $config= New-Object System.Collections.ArrayList
    $config.add( $configSymantecPAM ) | Out-Null
    
    $configJson= $config | ConvertTo-Json

    $outFilename= "c:\Temp\SPIX-$($runHostname)_$($whoami).properties"
    Write-Host "Write configuration to '$outFilename'"
    $configJson | Out-file -FilePath $outFilename -Encoding ascii
} 
catch {
    Write-Error "Expected exception received, Name= $($_.Exception.Message), details= $($_.Exception.Details)"
}
