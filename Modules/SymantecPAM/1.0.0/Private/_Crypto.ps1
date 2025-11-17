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
function _Encrypt-PBKDF2 {
    param(
        [Parameter(Mandatory=$true)][string]$PlainText,
        [Parameter(Mandatory=$true)][string]$Password
    )

    $salt = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)

    $pbkdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 100000)
    $key = $pbkdf.GetBytes(32)   # AES-256 key

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256
    $aes.Mode    = "CBC"
    $aes.Padding = "PKCS7"
    $aes.Key     = $key
    $aes.GenerateIV()
    $iv = $aes.IV

    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

    return [Convert]::ToBase64String($salt + $iv + $cipherBytes)
}

#--------------------------------------------------------------------------------------
function _Decrypt-PBKDF2 {
    param(
        [Parameter(Mandatory=$true)][string]$CipherBase64,
        [Parameter(Mandatory=$true)][string]$Password
    )

    $combined = [Convert]::FromBase64String($CipherBase64)
    $salt = $combined[0..15]
    $iv   = $combined[16..31]
    $cipherBytes = $combined[32..($combined.Length-1)]

    $pbkdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 100000)
    $key = $pbkdf.GetBytes(32)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256
    $aes.Mode    = "CBC"
    $aes.Padding = "PKCS7"
    $aes.Key     = $key
    $aes.IV      = $iv

    $decryptor = $aes.CreateDecryptor()
    $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)

    return [System.Text.Encoding]::UTF8.GetString($plainBytes)
}
