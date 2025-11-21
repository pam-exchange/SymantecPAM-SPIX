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

function Sync-SymAuthorization () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
		if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        try {
            if ($params.action -match 'update|remove') {
                $current= Get-SymAuthorization -ID $params.ID -Single -NoEmptySet
            }

            if ($params.action -eq 'new') {

                $current= Get-SymAuthorization -TargetGroup $params.TargetGroup -RequestGroup $params.RequestGroup -TargetAlias $params.TargetAlias -RequestScript $params.script -RequestServer $params.RequestServer -Single -NoEmptySet

                $details= $DETAILS_EXCEPTION_DUPLICATE_AUTHORIZATION_01 -f $params.name
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }
            
        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'Authorization.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {

            if ($params.Target) {
                if ($params.Target -match "\((.*)\)") {
                    $newParams+= @{ 'Authorization.targetGroupName'= $matches[1] }
                }
                else {
                    $newParams+= @{ 'TargetAlias.name'= $params.Target}
                }
            }

            if ($params.Request) {
                if ($params.Request -match "\((.*)\)") {
                    $newParams+= @{ 'Authorization.requestGroupName'= $matches[1] }
                }
                else {
                    $newParams+= @{ 'RequestServer.hostName'= $params.Request}
                    if ($params.Script) {
                        $newParams+= @{ 'RequestScript.ID'= (Get-SymRequestScript -name $params.Script).ID } 
                    } 
                    else {
                        $newParams+= @{ 'RequestScript.ID'= '-1'} 
                    }
                }
            }

            if ($params.checkExecutionID) {$newParams+= @{ 'Authorization.checkExecutionID'= $params.checkExecutionID.ToLower()} }
            if ($params.executionUser) {$newParams+= @{ 'Authorization.executionUser'= $params.executionUser} }
            
            if ($newParams.'RequestScript.ID' -eq '-1') {
                $newParams+= @{ 'Authorization.checkFilePath'= 'false'}
                $newParams+= @{ 'Authorization.checkPath'= 'false'}
                $newParams+= @{ 'Authorization.checkScriptHash'= 'false' }
            }
            else {
                if ($params.checkFilePath) {$newParams+= @{ 'Authorization.checkFilePath'= $params.checkFilePath.ToLower()} }
                if ($params.checkPath) {$newParams+= @{ 'Authorization.checkPath'= $params.checkPath.ToLower()} }
                if ($params.checkScriptHash) {$newParams+= @{ 'Authorization.checkScriptHash'= $params.checkScriptHash.ToLower()} }
            }
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd 'addAuthorization' -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd 'updateAuthorization' -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd 'deleteAuthorization' -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.Authorization
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Authorization'
        $obj.ID= [int]($obj.ID)

        switch ($params.action) {
        'new' {
            $idx= $script:cacheAuthorizationBase.Add( $obj )
            $script:cacheAuthorizationByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cacheAuthorizationByID[ [int]($obj.ID) ]
            $script:cacheAuthorizationBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheAuthorizationByID[ [int]($obj.ID) ]
            $script:cacheAuthorizationBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}

# --- end-of-file ---