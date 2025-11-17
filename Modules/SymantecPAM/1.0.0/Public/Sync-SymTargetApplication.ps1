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

function Sync-SymTargetApplication () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
        if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        $srv= $null
        $current= $null
        try {
            # Get current object (update) or fail (new)
            if ($params.hostname) {
                $srv= Get-SymTargetServer -Hostname $params.hostname -Single -NoEmptySet
            }
            if ($params.name) {
                $current= Get-SymTargetApplication -TargetServerID $srv.ID -Name $params.name -Single -NoEmptySet
            }

            if ($params.action -eq 'new') {
                $details= $DETAILS_EXCEPTION_DUPLICATE_APPL_01 -f $params.hostname, $params.name
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            } 
            else {
                $current= Get-SymTargetApplication -ID $params.ID -Single -NoEmptySet
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }
            
        $newParams= @{}

        if ($params.action -match '(remove)') { 
            $newParams+= @{ 'TargetApplication.ID'= $current.ID } 
        }
        if ($params.action -match '(update)') { 
            $newParams+= @{ 'TargetApplication.ID'= $current.ID } 
            $newParams+= @{ 'TargetServer.ID'= $current.targetServerID } 
        }

        if ($params.action -match '(new|update)') {        
            if (!$newparams.'TargetServer.ID') {
                if ($params.targetServerID) { 
                    $newParams+= @{ 'TargetServer.ID'= $params.TargetServerID} 
                }
                elseif ($params.hostname) {
                    $newParams+= @{ 'TargetServer.ID'= (Get-SymTargetServer -Hostname $params.hostName -Single -NoEmptySet).ID }
                }
            }
            if ($params.name) {$newParams+= @{ 'TargetApplication.name'= $params.name}}
            if ($params.extensionType) {$newParams+= @{ 'TargetApplication.type'= _ExtensionType($params.extensionType)}}
            if ($params.'PasswordPolicy.ID') {$newParams+= @{ 'PasswordPolicy.ID'= $params.'PasswordPolicy.ID'}}

            foreach ($p in $params.PSObject.Properties | Where-Object {$_.Name -like 'Attribute*'}) {
                #if ($p.Value -match "^(TRUE|FALSE)$") {$p.Value= $p.Value.toLower()}
                $newParams+= @{ $p.Name= $p.Value }
            }
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addTargetApplication" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updateTargetApplication" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deleteTargetApplication" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.TargetApplication
        $obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|extensionType\b|targetServer\b|create\w*|update\w*)[\w\.]+\b"
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "TargetApplication"
        $obj.ID= [int]($obj.ID)

        if (!$srv) {
            $srv= Get-SymTargetServer -ID $obj.TargetServerID
        }

        $obj | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $srv.hostname
        $obj | Add-Member -MemberType NoteProperty -Name 'deviceName' -Value $srv.deviceName
        $obj.deviceId= $srv.deviceId
        #$obj | Add-Member -MemberType NoteProperty -Name 'PcpName' -Value (Get-SymPCP -ID $obj.policyID).name
        #$obj | Add-Member -MemberType NoteProperty -Name 'PcpId' -Value $obj.policyID

        switch ($params.action) {
        'new' {
            $idx= $script:cacheTargetApplicationBase.Add( $obj )
            $script:cacheTargetApplicationByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cacheTargetApplicationByID[ [int]($obj.ID) ]
            $script:cacheTargetApplicationBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheTargetApplicationByID[ [int]($obj.ID) ]
            $script:cacheTargetApplicationBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}

# --- end-of-file ---