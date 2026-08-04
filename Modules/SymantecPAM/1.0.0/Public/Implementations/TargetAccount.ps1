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
}
