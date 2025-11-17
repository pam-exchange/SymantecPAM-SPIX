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

enum METHODTYPE {
    GET
    PUT
    POST
    DELETE
}

#--------------------------------------------------------------------------------------
function _Invoke-SymantecAPI () {

    Param(
        [Parameter(Mandatory=$true)][string] $Cmd,
        [Parameter(Mandatory=$false)][METHODTYPE] $Method= 'GET',
        [Parameter(Mandatory=$false)] $Params
    )

    $url= "$($script:apiUrl)/$($cmd.trim('/'))"

    if ($Params) {
        if ($Params.GetType().name -eq "Hashtable") {
            $paramsStr= ($Params.GetEnumerator() |
                            #Where-Object { -not [string]::IsNullOrWhiteSpace($_.Value) } |
                            ForEach-Object { "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" }) -join '&'
        }
        if ($Params.GetType().name -eq "PSCustomObject") {
            $paramsStr= ($Params.PSObject.Properties |
                            #Where-Object { -not [string]::IsNullOrWhiteSpace($_.Value) } |
                            ForEach-Object { "$($_.Name)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" }) -join '&'
        }
        if ($paramsStr) {$url+= "?"+$paramsStr}
    }

    try {
        if ($global:psVersion -lt "7") {
            switch($Method) {
                'GET' {
                    $res= Invoke-RestMethod -Uri $url -Method $Method -Headers $Script:apiHeaders -ContentType 'application/json'
                    break
                }
            }
        }
        else {
            switch($Method) {
                'GET' {
                    $res= Invoke-RestMethod -Uri $url -Method $Method -Headers $Script:apiHeaders -ContentType 'application/json' -SkipCertificateCheck 
                    break
                }
            }
        }
        return $res
    }
    catch {
        if ($_.Exception.GetType().FullName -eq "SymantecPamException") {throw}

        if ($_.Exception.GetType().FullName -eq "System.Net.WebException") {
            $details= $_.Exception.Message
            throw ( New-Object SymantecPamException( $EXCEPTION_NOT_FOUND, $details ) )
        }

        # something else happened
        throw
    }
}

#--------------------------------------------------------------------------------------
function uriencode( [string]$var ) 
{
    return [uri]::EscapeUriString($var)
}

#--------------------------------------------------------------------------------------
function urlencode( [string]$var ) 
{
    return [System.Web.HTTPUtility]::UrlEncode($var)
}

# --- end-of-file ---