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

function Sync-SymPCP () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
		if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        try {
            if ($params.action -match 'update|remove') {
                $current= Get-SymPCP -ID $params.ID -Single -NoEmptySet
            }

            if ($params.action -eq 'new') {
                if (!$params.name) {
                    $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'Name'
                    throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }

                $current= Get-SymPCP -name $params.name -Single -NoEmptySet

                $details= $DETAILS_EXCEPTION_DUPLICATE_PCP_01 -f $params.name
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }
            
        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'PasswordPolicy.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {
            $newParams+= @{ "PasswordPolicy.name"= $params.name }
            if ($params.description) {$newParams+= @{ "PasswordPolicy.description"= $params.description} }
            if ($params.composedOfLowerCaseCharacters) {$newParams+= @{'Attribute.composedOfLowerCaseCharacters'= $params.composedOfLowerCaseCharacters} }
            if ($params.composedOfMustNotContainCharacters) {$newParams+= @{'Attribute.composedOfMustNotContainCharacters'= $params.composedOfMustNotContainCharacters} }
            if ($params.composedOfNumericCharacters) {$newParams+= @{'Attribute.composedOfNumericCharacters'= $params.composedOfNumericCharacters} }
            if ($params.composedOfSpecialCharacters) {$newParams+= @{'Attribute.composedOfSpecialCharacters'= $params.composedOfSpecialCharacters} }
            if ($params.composedOfUpperCaseCharacters) {$newParams+= @{'Attribute.composedOfUpperCaseCharacters'= $params.composedOfUpperCaseCharacters} }
            if ($params.disallowSameClassRepeat) {$newParams+= @{'Attribute.disallowSameClassRepeat'= $params.disallowSameClassRepeat} }
            if ($params.enableMaxPasswordAge) {$newParams+= @{'Attribute.enableMaxPasswordAge'= $params.enableMaxPasswordAge} }
            if ($params.firstCharacterLowerCase) {$newParams+= @{'Attribute.firstCharacterLowerCase'= $params.firstCharacterLowerCase} }
            if ($params.firstCharacterNumeric) {$newParams+= @{'Attribute.firstCharacterNumeric'= $params.firstCharacterNumeric} }
            if ($params.firstCharacterSpecial) {$newParams+= @{'Attribute.firstCharacterSpecial'= $params.firstCharacterSpecial} }
            if ($params.firstCharacterSpecialCharacters) {$newParams+= @{'Attribute.firstCharacterSpecials'= $params.firstCharacterSpecialCharacters} }
            if ($params.firstCharacterUpperCase) {$newParams+= @{'Attribute.firstCharacterUpperCase'= $params.firstCharacterUpperCase} }
            if ($params.lastCharacterLowerCase) {$newParams+= @{'Attribute.lastCharacterLowerCase'= $params.lastCharacterLowerCase} }
            if ($params.lastCharacterNumeric) {$newParams+= @{'Attribute.lastCharacterNumeric'= $params.lastCharacterNumeric} }
            if ($params.lastCharacterSpecial) {$newParams+= @{'Attribute.lastCharacterSpecial'= $params.lastCharacterSpecial} }
            if ($params.lastCharacterSpecialCharacters) {$newParams+= @{'Attribute.lastCharacterSpecialCharacters'= $params.lastCharacterSpecialCharacters} }
            if ($params.lastCharacterUpperCase) {$newParams+= @{'Attribute.lastCharacterUpperCase'= $params.lastCharacterUpperCase} }
            if ($params.maxClassRepeat) {$newParams+= @{'Attribute.maxClassRepeat'= $params.maxClassRepeat} }
            if ($params.maxLength) {$newParams+= @{'Attribute.maxLength'= $params.maxLength} }
            if ($params.maxPasswordAge) {$newParams+= @{'Attribute.maxPasswordAge'= $params.maxPasswordAge} }
            if ($params.minDaysBeforeReuse) {$newParams+= @{'Attribute.minDaysBeforeReuse'= $params.minDaysBeforeReuse} }
            if ($params.minIterationsBeforeReuse) {$newParams+= @{'Attribute.minIterationsBeforeReuse'= $params.minIterationsBeforeReuse} }
            if ($params.minLength) {$newParams+= @{'Attribute.minLength'= $params.minLength} }
            if ($params.mustNotContainCharacters) {$newParams+= @{'Attribute.mustNotContainCharacters'= $params.mustNotContainCharacters} }
            if ($params.mustNotContainDuplicateCharacters) {$newParams+= @{'Attribute.mustNotContainDuplicateCharacters'= $params.mustNotContainDuplicateCharacters} }
            if ($params.mustNotContainRepeatingCharacters) {$newParams+= @{'Attribute.mustNotContainRepeatingCharacters'= $params.mustNotContainRepeatingCharacters} }
            if ($params.passwordPrefix) {$newParams+= @{'Attribute.passwordPrefix'= $params.passwordPrefix} }
            if ($params.remotePasswordGeneration) {$newParams+= @{'Attribute.remotePasswordGeneration'= $params.remotePasswordGeneration} }
            if ($params.specialCharacters) {$newParams+= @{'Attribute.specialCharacters'= $params.specialCharacters} }

            @($newParams.Keys) | ForEach-Object { if ($newParams[$_] -match '^(TRUE|FALSE)$') { $newParams[$_] = $newParams[$_].ToLower() } }
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addPasswordPolicy" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updatePasswordPolicy" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deletePasswordPolicy" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.PasswordPolicy
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+|Attribute\.)'
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "PCP"
        $obj.ID= [int]($obj.ID)

        switch ($params.action) {
        'new' {
            $idx= $script:cachePCPBase.Add( $obj )
            $script:cachePCPByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cachePCPByID[ [int]($obj.ID) ]
            $script:cachePCPBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cachePCPByID[ [int]($obj.ID) ]
            $script:cachePCPBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}

# --- end-of-file ---