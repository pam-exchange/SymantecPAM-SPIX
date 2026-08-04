class Filter : IFilter {
    Filter() {
        $this.ObjectType = "Filter"
    }
    Filter([object]$obj) {
        $this.ObjectType = "Filter"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
    }
}
