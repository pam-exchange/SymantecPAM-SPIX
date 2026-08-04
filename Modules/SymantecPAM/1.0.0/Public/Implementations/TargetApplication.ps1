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
}
