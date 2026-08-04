class TargetApplication : ITargetApplication {
    TargetApplication() {
        $this.ObjectType = "TargetApplication"
    }
    TargetApplication([object]$obj) {
        $this.ObjectType = "TargetApplication"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.ExtensionType = [string]$obj.ExtensionType
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.Name = [string]$obj.Name
        $this.PCP = [string]$obj.PCP
        if ($obj.PSObject.Properties['Attribute.descriptor1']) { $this.Attribute_descriptor1 = [string]$obj.'Attribute.descriptor1' }
        if ($obj.PSObject.Properties['Attribute.descriptor2']) { $this.Attribute_descriptor2 = [string]$obj.'Attribute.descriptor2' }
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymTargetApplication @params
    }

    [object] Set([object]$params) {
        return Sync-SymTargetApplication -params $params
    }

    [object] New([object]$params) {
        return Sync-SymTargetApplication -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($params)
        $fixedColumns = @('ID','ObjectType','Action','ExtensionType','deviceName','hostname','name','PCP','Attribute.descriptor1','Attribute.descriptor2')
        $ignoreColums = @('deviceId','policyID','TargetServerID','overrideDnsType','Attribute.agentId','Attribute.sshKeyPairPolicyID','Attribute.customWorkflowId')
        Export-SymTargetApplication -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Compress:$params.Compress -Delimiter $params.Delimiter -OutputPath $params.OutputPath -Quiet:$params.Quiet
    }
}
