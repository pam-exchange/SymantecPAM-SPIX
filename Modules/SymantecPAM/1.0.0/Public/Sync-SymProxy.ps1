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

function Sync-SymProxy () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
        if ($params.action -notmatch '^(update|remove)$') {return $null}

        if ($params.action -match 'update|remove') {
            $current= Get-SymProxy -ID $params.ID -Single -NoEmptySet
        }

        # 
        # Note: There is no 'New' option for Proxy servers
        #
           
        $newParams= @{}

        switch ($params.action) {
        'update' {
            $newParams+= @{ 'Agent.ID'= $current.ID }
            if ($params.hostname) {$newParams+= @{ "Agent.hostName"= $params.hostname }}
            if ($params.deviceName) {$newParams+= @{ "Agent.deviceName"= $params.devicename }}
            if ($params.active) {$newParams+= @{ "Agent.active"= $params.active.toLower() }}
            if ($params.port) {$newParams+= @{ "Agent.port"= $params.port}}
            if ($params.preserveHostName) {$newParams+= @{ "Agent.preserveHostName"= $params.preserveHostName.toLower() }}
            if ($params.pendingFingerprint) {$newParams+= @{ "Agent.acceptPendingFingerprint"= $params.pendingFingerprint.toLower() }}
            if ($params.patchStatus) {$newParams+= @{ "Agent.patchStatus"= $params.patchStatus.toLower() }}
            if ($params.'Attribute.Descriptor1') {$newParams+= @{ "Attribute.descriptor1"= $params.'Attribute.Descriptor1' }}
            if ($params.'Attribute.Descriptor2') {$newParams+= @{ "Attribute.descriptor2"= $params.'Attribute.Descriptor2' }}

            if ($newParams.'Agent.port') {$newParams+= @{ 'Agent.updatePortFlag'= 'true'}}

            $res= _Invoke-SymantecCLI -cmd "updateAgent" -params $newParams
            break
        }

        'remove' {
            $newParams+= @{ 'RequestServer.ID'= $current.ID }
            $res= _Invoke-SymantecCLI -cmd "deleteRequestServer" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.Agent
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Proxy"
        $obj.ID= [int]($obj.ID)
        if ($obj.ipAddress -eq "Unknown") {$obj.ipAddress= ""}

        switch ($params.action) {
        'update' {
            $idx= $script:cacheProxyByID[ [int]($obj.ID) ]
            $script:cacheProxyBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheProxyByID[ [int]($obj.ID) ]
            $script:cacheProxyBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}
# --- end-of-file ---