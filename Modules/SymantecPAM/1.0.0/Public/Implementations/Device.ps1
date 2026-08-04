class Device : IDevice {
    Device() {
        $this.ObjectType = "Device"
    }
    Device([object]$obj) {
        $this.ObjectType = "Device"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
    }
}
