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

function Sync-SymUserGroup () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
        if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        if ($params.action -match 'update|remove') {
            $current= Get-SymUserGroup -ID $params.ID -Single -NoEmptySet
        }

        if ($params.action -eq 'new') {
            if (!$params.name) {
                $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'Name'
                throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
            }
            if (Get-SymUserGroup -name $params.name) {
                $details= $DETAILS_EXCEPTION_DUPLICATE_USERGROUP_01 -f $params.name
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        }
            
        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'UserGroup.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {
            $newParams+= @{ "UserGroup.name"= $params.name }
            if ($params.description) {$newParams+= @{ "UserGroup.description"= $params.description} }
            if ($params.roleID) {$newParams+= @{'UserGroup.roleID'= $params.roleID} }
            if ($params.groups) {$newParams+= @{'UserGroup.groups'= $params.groups} }
            if ($params.readOnly) {$newParams+= @{'UserGroup.readOnly'= 'false'} }
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addUserGroup" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updateUserGroup" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deleteUserGroup" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.UserGroup
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+|Attribute\.)'
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "UserGroup"
        $obj.ID= [int]($obj.ID)

        switch ($params.action) {
        'new' {
            $idx= $script:cacheUserGroupBase.Add( $obj )
            $script:cacheUserGroupByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cacheUserGroupByID[ [int]($obj.ID) ]
            $script:cacheUserGroupBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheUserGroupByID[ [int]($obj.ID) ]
            $script:cacheUserGroupBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}
# --- end-of-file ---