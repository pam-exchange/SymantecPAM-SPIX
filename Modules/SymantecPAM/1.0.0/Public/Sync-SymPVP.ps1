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

function Sync-SymPVP () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
		if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        try {
            if ($params.action -match 'update|remove') {
                $current= Get-SymPVP -ID $params.ID -Single -NoEmptySet
            }

            if ($params.action -eq 'new') {
                if (!$params.name) {
                    $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'Name'
                    throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }
                $current= Get-SymPVP -name $params.name -Single -NoEmptySet

                $details= $DETAILS_EXCEPTION_DUPLICATE_PVP_01 -f $params.name
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }

        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'PasswordViewPolicy.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {
            if ($params.name) {$newParams+= @{ "PasswordViewPolicy.name"= $params.name }}
            if ($params.description) {$newParams+= @{ "PasswordViewPolicy.description"= $params.description} }

            if ($params.approverIDs) { $newParams+= @{'PasswordViewPolicy.approverIDs'= $params.approverIDs} }
            if ($params.approvers) { $newParams+= @{'PasswordViewPolicy.approvers'= $params.approvers.replace(' ','')} }
            if ($params.authenticationRequiredSso) {$newParams+= @{'PasswordViewPolicy.authenticationRequired'= $params.authenticationRequiredSso} }
            if ($params.authenticationRequiredView) {$newParams+= @{'PasswordViewPolicy.authenticationRequiredSso'= $params.authenticationRequiredView} }
            if ($params.changePasswordOnConnectionEnd) {$newParams+= @{'PasswordViewPolicy.changePasswordOnConnectionEnd'= $params.changePasswordOnConnectionEnd } }
            if ($params.changePasswordOnSessionEnd) {$newParams+= @{'PasswordViewPolicy.changePasswordOnSessionEnd'= $params.changePasswordOnSessionEnd} }
            if ($params.changePasswordOnSso) {$newParams+= @{'PasswordViewPolicy.changePasswordOnSso'= $params.changePasswordOnSso} }
            if ($params.changePasswordOnView) {$newParams+= @{'PasswordViewPolicy.changePasswordOnView'= $params.changePasswordOnView} }
            if ($params.checkinCheckoutInterval) {$newParams+= @{'PasswordViewPolicy.checkinCheckoutInterval'= $params.checkinCheckoutInterval} }
            if ($params.checkinCheckoutRequired) {$newParams+= @{'PasswordViewPolicy.checkinCheckoutRequired'= $params.checkinCheckoutRequired} }
            if ($params.dualAuthorizationInterval) {$newParams+= @{'PasswordViewPolicy.dualAuthorizationInterval'= $params.dualAuthorizationInterval} }
            if ($params.dualAuthorizationRequired) {$newParams+= @{'PasswordViewPolicy.dualAuthorization'= $params.dualAuthorizationRequired} }

            if ($params.emailNotificationForActiveUsers) {$newParams+= @{'PasswordViewPolicy.emailNotificationToActiveUsers'= $params.emailNotificationForActiveUsers} }
            if ($params.emailNotificationForDualAuthApprovers) {$newParams+= @{'PasswordViewPolicy.emailNotificationToDualAuthApprovers'= $params.emailNotificationForDualAuthApprovers} }
            if ($params.emailNotificationRequired) {$newParams+= @{'PasswordViewPolicy.emailNotificationRequired'= $params.emailNotificationRequired} }
            if ($params.emailNotificationUserIDs) {$newParams+= @{'PasswordViewPolicy.emailNotificationUserIDs'= $params.emailNotificationUserIDs} }
            if ($params.emailNotificationUsers) {$newParams+= @{'PasswordViewPolicy.emailNotificationUsers'= $params.emailNotificationUsers.replace(' ','')} }

            if ($params.enableOneClickApproval) {$newParams+= @{'PasswordViewPolicy.enableOneClickApproval'= $params.enableOneClickApproval} }
            if ($params.exclusiveCheckoutCheckinInterval) {$newParams+= @{'PasswordViewPolicy.exclusiveCheckoutCheckinInterval'= $params.exclusiveCheckoutCheckinInterval} }
            if ($params.exclusiveCheckoutRequired) {$newParams+= @{'PasswordViewPolicy.exclusiveCheckoutRequired'= $params.exclusiveCheckoutRequired} }
            if ($params.passwordChangeInterval) {$newParams+= @{'PasswordViewPolicy.passwordChangeInterval'= $params.passwordChangeInterval} }
            if ($params.passwordViewRequestBanner) {$newParams+= @{'PasswordViewPolicy.passwordViewRequestBanner'= $params.passwordViewRequestBanner} }
            if ($params.passwordViewRequestMaxDays) {$newParams+= @{'PasswordViewPolicy.PasswordViewRequestMaxDays'= $params.passwordViewRequestMaxDays} }
            if ($params.passwordViewRequestMaxInterval) {$newParams+= @{'PasswordViewPolicy.PasswordViewRequestMaxInterval'= $params.passwordViewRequestMaxInterval} }
            if ($params.reasonRequiredSso) {$newParams+= @{'PasswordViewPolicy.reasonRequiredSso'= $params.reasonRequiredSso} }
            if ($params.reasonRequiredView) {$newParams+= @{'PasswordViewPolicy.reasonRequiredView'= $params.reasonRequiredView} }
            if ($params.retrospectiveApprovalRequired) {$newParams+= @{'PasswordViewPolicy.retrospectiveApprovalRequired'= $params.retrospectiveApprovalRequired} }

            @($newParams.Keys) | ForEach-Object { if ($newParams[$_] -match '^(TRUE|FALSE)$') { $newParams[$_] = $newParams[$_].ToLower() } }
        }

        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addPasswordViewPolicy" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updatePasswordViewPolicy" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deletePasswordViewPolicy" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.PasswordViewPolicy
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+|Attribute\.)'
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "PVP"
        $obj.ID= [int]($obj.ID)

        switch ($params.action) {
        'new' {
            $idx= $script:cachePVPBase.Add( $obj )
            $script:cachePVPByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cachePVPByID[ [int]($obj.ID) ]
            $script:cachePVPBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cachePVPByID[ [int]($obj.ID) ]
            $script:cachePVPBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}
# --- end-of-file ---