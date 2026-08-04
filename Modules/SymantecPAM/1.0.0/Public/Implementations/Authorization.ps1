class Authorization : IAuthorization {
    Authorization() {
        $this.ObjectType = "Authorization"
    }
    Authorization([object]$obj) {
        $this.ObjectType = "Authorization"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Target = [string]$obj.Target
        $this.Request = [string]$obj.Request
        $this.Script = [string]$obj.Script
        $this.checkExecutionID = [string]$obj.checkExecutionID
        $this.executionUser = [string]$obj.executionUser
    }
}
