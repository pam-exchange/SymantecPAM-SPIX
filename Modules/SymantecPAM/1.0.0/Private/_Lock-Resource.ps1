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

function _Lock-Resource {

    param(
        [string]$LockName,
        [int]$TimeoutSeconds = 30
    )

    if ($global:psVersion -ge 7) {
        # PowerShell 7+ uses .NET Core's SemaphoreSlim
        try {
            $semaphore = [System.Threading.SemaphoreSlim]::new(1, 1)
            $acquired = $semaphore.Wait($TimeoutSeconds * 1000)
            
            if (-not $acquired) {
                throw "Failed to acquire lock '$LockName' within $TimeoutSeconds seconds"
            }
            
            return $semaphore
        }
        catch {
            throw "Error acquiring lock '$LockName': $_"
        }
    }
    else {
        # PowerShell 5.1 uses named Mutex
        try {
            $mutex = New-Object System.Threading.Mutex($false, "Global\$LockName")
            $acquired = $mutex.WaitOne(($TimeoutSeconds * 1000))
            
            if (-not $acquired) {
                throw "Failed to acquire lock '$LockName' within $TimeoutSeconds seconds"
            }
            
            return $mutex
        }
        catch {
            throw "Error acquiring lock '$LockName': $_"
        }
    }
}