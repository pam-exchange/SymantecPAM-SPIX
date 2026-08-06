class TargetAccount : ITargetAccount {
    TargetAccount() {
        $this.ObjectType = "TargetAccount"
    }
    TargetAccount([object]$obj) {
        $this.ObjectType = "TargetAccount"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.ExtensionType = [string]$obj.ExtensionType
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.targetApplicationName = [string]$obj.targetApplicationName
        $this.userName = [string]$obj.userName
        $this.password = [string]$obj.password
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymTargetAccount @params
    }

    [object] Set([object]$params) {
        return Sync-SymTargetAccount -params $params
    }

    [object] New([object]$params) {
        return Sync-SymTargetAccount -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($params)
        $fixedColumns = @('ID','ObjectType','Action','ExtensionType','deviceName','hostname','targetApplicationName','username','password')
        $ignoreColums = @('cacheAllowed','cacheBehaviorInt','compoundAccount','compoundServerIDs','ownerUserID','passwordViewPolicyID','parentAccountId','Privileged','ServerkeyID','TargetApplication','TargetApplicationID','TargetServerAlias','TargetServerID','Attribute.useOtherAccountToChangePassword')
        Export-SymTargetAccount -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Compress:$params.Compress -Delimiter $params.Delimiter -OutputPath $params.OutputPath -ShowPassword:$params.ShowPassword -Passphrase $params.Passphrase -Quiet:$params.Quiet
    }
}
