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

function New-SymTargetServer () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
        if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        try {
            if ($params.action -match 'update|remove') {
                $current= Get-SymTargetServer -ID $params.ID -Single -NoEmptySet
            }

            if ($params.action -eq 'new') {
                if (!$params.hostName) {
                    $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'HostName'
                    throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }
                $current= Get-SymTargetServer -Hostname $params.hostname -NoEmptySet

                $details= $DETAILS_EXCEPTION_DUPLICATE_SERVER_01 -f $params.hostname
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }
            
        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'TargetServer.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {
            if ($params.hostname) {$newParams+= @{ "TargetServer.hostName"= $params.hostname }}
            if ($params.deviceName) {$newParams+= @{ "TargetServer.deviceName"= $params.deviceName }}
            if ($params.'Attribute.Descriptor1') {$newParams+= @{ "Attribute.descriptor1"= $params.'Attribute.Descriptor1' }}
            if ($params.'Attribute.Descriptor2') {$newParams+= @{ "Attribute.descriptor2"= $params.'Attribute.Descriptor2' }}
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addTargetServer" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updateTargetServer" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deleteTargetServer" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.TargetServer
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "TargetServer"
        $obj.ID= [int]($obj.ID)

        if ($obj.ipAddress -eq "Unknown") {$obj.ipAddress= ""}

        switch ($params.action) {
        'new' {
            $idx= $script:cacheTargetServerBase.Add( $obj )
            $script:cacheTargetServerByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cacheTargetServerByID[ [int]($obj.ID) ]
            $script:cacheTargetServerBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheTargetServerByID[ [int]($obj.ID) ]
            $script:cacheTargetServerBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}
# --- end-of-file ---