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

function Sync-SymRequestScript () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
        if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        if ($null -eq $params.name -or $params.name -eq "") {
            throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $null ) )
        }

        try {
            # Get current object (update) or fail (new)
            $current= Get-SymRequestScript -name $params.name -Single -NoEmptySet

            if ($params.action -eq 'new') {
                $details= $DETAILS_EXCEPTION_DUPLICATE_REQUESSCRIPT_01 -f $params.name
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }
            
        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'RequestScript.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {
            #if ($params.requestServerID) {$newParams+= @{'RequestServer.ID'= $params.requestServerID} }
            if ($params.requestServer) {$newParams+= @{'RequestServer.hostName'= $params.requestServer} }
            if ($params.name) {$newParams+= @{'RequestScript.name'= $params.name} }
            if ($params.type) {$newParams+= @{'RequestScript.type'= $params.type} }
            if ($params.executionPath) {$newParams+= @{'RequestScript.executionPath'= $params.executionPath} }
            if ($params.filePath) {$newParams+= @{'RequestScript.filePath'= $params.filePath} }
            if ($params.'Attribute.descriptor1') {$newParams+= @{'Attribute.descriptor1'= $params.'Attribute.descriptor1'} }
            if ($params.'Attribute.descriptor2') {$newParams+= @{'Attribute.descriptor2'= $params.'Attribute.descriptor2'} }
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addRequestScript" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updateRequestScript" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deleteRequestScript" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.RequestScript
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+|Attribute\.)'
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'RequestScript'
        $obj.ID= [int]($obj.ID)

        switch ($params.action) {
        'new' {
            $idx= $script:cacheRequestScriptBase.Add( $obj )
            $script:cacheRequestScriptByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cacheRequestScriptByID[ [int]($obj.ID) ]
            $script:cacheRequestScriptBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheRequestScriptByID[ [int]($obj.ID) ]
            $script:cacheRequestScriptBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}

# --- end-of-file ---