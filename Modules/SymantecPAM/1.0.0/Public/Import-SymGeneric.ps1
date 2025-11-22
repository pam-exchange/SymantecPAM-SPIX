<#
MIT License

Copyright (c) 2025 PAM-Exchange

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>
#--------------------------------------------------------------------------------------


function Import-SymGeneric (
    [PSCustomObject[]] $InputCsv,
    [switch] $Quiet= $false
)
{
	process {
        $failedImport= New-Object System.Collections.ArrayList
        foreach ($row in $InputCsv) {
            try {
                if ($row.Action -notmatch "^(New|Update|Remove)$") {
                    continue
                }
                
                switch ($row.ObjectType) {
                    'Authorization' { $res= Sync-SymAuthorization -params $row; break }
                    'RequestServer' { $res= Sync-SymRequestServer -params $row; break }
                    'RequestScript' { $res= Sync-SymRequestScript -params $row; break }
                    'TargetServer' { $res= Sync-SymTargetServer -params $row; break }
                    'PCP' { $res= Sync-SymPCP -params $row; break }
                    'Proxy' { $res= Sync-SymProxy -params $row; break }
                    'PVP' { $res= Sync-SymPVP -params $row; break }
                    'Group' { $res= Sync-SymGroup -params $row; break }
                    'Role' { $res= Sync-SymRole -params $row; break }
                    'SSHKeyPairPolicy' { $res= Sync-SymSSHKeyPairPolicy -params $row; break }
                }
            }
            catch {
                $row | Add-Member -NotePropertyName ErrorMessage -NotePropertyValue "$($_.Exception.Message) -- $($_.Exception.Details)" -Force
                $failedImport.add( $row ) | Out-Null
            }
        }
        return $failedImport
     }
}

# --- end-of-file ---