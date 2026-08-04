class TargetAlias : ITargetAlias {
    TargetAlias() {
        $this.ObjectType = "TargetAlias"
    }
    TargetAlias([object]$obj) {
        $this.ObjectType = "TargetAlias"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.userName = [string]$obj.userName
        if ($obj.PSObject.Properties['TargetApplicationID']) { $this.targetApplicationID = [int]$obj.TargetApplicationID }
    }
}
