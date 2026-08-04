class CustomWorkflow : ICustomWorkflow {
    CustomWorkflow() {
        $this.ObjectType = "CustomWorkflow"
    }
    CustomWorkflow([object]$obj) {
        $this.ObjectType = "CustomWorkflow"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.applicationType = [string]$obj.applicationType
        $this.Description = [string]$obj.Description
    }
}
