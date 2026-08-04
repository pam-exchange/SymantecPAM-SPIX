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

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymDevice @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for Device"
    }

    [object] New([object]$params) {
        throw "New is not supported for Device"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','Name')
        $ignoreColums = @('deviceId','deviceName','deviceGroupMembership')
        Export-SymGeneric -ObjectType Device -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
