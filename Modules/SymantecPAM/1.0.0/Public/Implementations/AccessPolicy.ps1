class AccessPolicy : IAccessPolicy {
    AccessPolicy() {
        $this.ObjectType = "AccessPolicy"
    }
    AccessPolicy([object]$obj) {
        $this.ObjectType = "AccessPolicy"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.User = [string]$obj.User
        $this.Device = [string]$obj.Device
    }
}
