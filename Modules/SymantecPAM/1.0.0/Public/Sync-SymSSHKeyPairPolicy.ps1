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

function Sync-SymSSHKeyPairPolicy () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
        if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        try {
            if ($params.action -match 'update|remove') {
                $current= Get-SymSSHKeyPairPolicy -ID $params.ID -Single -NoEmptySet
            }

            if ($params.action -eq 'new') {
                if (!$params.name) {
                    $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'Name'
                    throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }
                $current= Get-SymSSHKeyPairPolicy -name $params.name -Single -NoEmptySet

                $details= $DETAILS_EXCEPTION_DUPLICATE_SSHKEYPAIR_01 -f $params.name
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }
            
        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'SSHKeyPairPolicy.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {
            $newParams+= @{ "SSHKeyPairPolicy.name"= $params.name }
            if ($Params.description) {$newParams+= @{ "SSHKeyPairPolicy.description"= $params.Description} }
            if ($Params.'Attribute.keyType') { $newParams+= @{ "SSHKeyPairPolicy.keyType"= $params.'Attribute.keyType'} }
            if ($Params.'Attribute.keyLength') { $newParams+= @{ "SSHKeyPairPolicy.keyLength"= $params.'Attribute.keyLength'} }
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addSSHKeyPairPolicy" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updateSSHKeyPairPolicy" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deleteSSHKeyPairPolicy" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.SSHKeyPairPolicy
        $obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|extensionType\b|create\w*|update\w*)[\w\.]+\b"
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "SSHKeyPairPolicy"
        $obj.ID= [int]($obj.ID)

        switch ($params.action) {
        'new' {
            $idx= $script:cacheSSHKeyPairPolicyBase.Add( $obj )
            $script:cacheSSHKeyPairPolicyByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cacheSSHKeyPairPolicyByID[ [int]($obj.ID) ]
            $script:cacheSSHKeyPairPolicyBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheSSHKeyPairPolicyByID[ [int]($obj.ID) ]
            $script:cacheSSHKeyPairPolicyBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}
# --- end-of-file ---