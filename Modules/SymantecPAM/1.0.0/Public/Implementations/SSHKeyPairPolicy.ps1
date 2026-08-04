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
}
