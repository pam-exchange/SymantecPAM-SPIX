class SSHKeyPairPolicy : ISSHKeyPairPolicy {
    SSHKeyPairPolicy() {
        $this.ObjectType = "SSHKeyPairPolicy"
    }
    SSHKeyPairPolicy([object]$obj) {
        $this.ObjectType = "SSHKeyPairPolicy"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
        if ($obj.PSObject.Properties['Attribute.keyType']) { $this.Attribute_keyType = [string]$obj.'Attribute.keyType' }
        if ($obj.PSObject.Properties['Attribute.keyLength']) { $this.Attribute_keyLength = [string]$obj.'Attribute.keyLength' }
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymSSHKeyPairPolicy @params
    }

    [object] Set([object]$params) {
        return Sync-SymSSHKeyPairPolicy -params $params
    }

    [object] New([object]$params) {
        return Sync-SymSSHKeyPairPolicy -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','Description','Attribute.keyType','Attribute.keyLength')
        $ignoreColums = @('SSHKeyType','SSHKeyLength','type')
        Export-SymGeneric -ObjectType SSHKeyPairPolicy -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
