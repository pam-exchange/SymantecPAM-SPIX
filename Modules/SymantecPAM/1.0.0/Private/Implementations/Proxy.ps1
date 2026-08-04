class Proxy : IProxy {
    Proxy() {
        $this.ObjectType = "Proxy"
    }
    Proxy([object]$obj) {
        $this.ObjectType = "Proxy"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.ipAddress = [string]$obj.ipAddress
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymProxy @params
    }

    [object] Set([object]$params) {
        return Sync-SymProxy -params $params
    }

    [object] New([object]$params) {
        return Sync-SymProxy -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','deviceName','hostname','ipAddress')
        $ignoreColums = @('serverKeyId','SiteID','pendingAcknowledgement','currentKey','oldKey','lastDigestLoginDate','lastPatchStatusChangeDate')
        Export-SymGeneric -ObjectType Proxy -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
