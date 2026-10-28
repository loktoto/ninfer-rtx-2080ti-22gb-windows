$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'resolve-windows-sm75-gpu.ps1')

$Good = '0, NVIDIA GeForce RTX 2080 Ti, 22528, 7.5, 616.56'
$Other = '1, NVIDIA GeForce RTX 4070, 12288, 8.9, 616.56'
$GoodOne = '1, NVIDIA GeForce RTX 2080 Ti, 22528, 7.5, 616.56'
$Cases = @(
    @{ Name='single target'; Rows=@($Good); Device=0; Pass=$true },
    @{ Name='selected target is second GPU'; Rows=@($Other,$GoodOne); Device=1; Pass=$true },
    @{ Name='do not borrow memory from another card'; Rows=@('0, NVIDIA GeForce RTX 2080 Ti, 11264, 7.5, 616.56','1, NVIDIA RTX 4090, 24576, 8.9, 616.56'); Device=0; Pass=$false },
    @{ Name='do not borrow architecture from another card'; Rows=@('0, NVIDIA GeForce RTX 2080 Ti, 22528, 8.9, 616.56',$GoodOne); Device=0; Pass=$false },
    @{ Name='wrong device rejects even when another device qualifies'; Rows=@($Other,$GoodOne); Device=0; Pass=$false },
    @{ Name='old driver'; Rows=@('0, NVIDIA GeForce RTX 2080 Ti, 22528, 7.5, 579.99'); Device=0; Pass=$false },
    @{ Name='missing device'; Rows=@($Good); Device=1; Pass=$false },
    @{ Name='duplicate device'; Rows=@($Good,$Good); Device=0; Pass=$false },
    @{ Name='malformed row'; Rows=@('0, malformed'); Device=0; Pass=$false }
)
foreach ($Case in $Cases) {
    $Rejected = $false
    $Failure = ''
    $Selected = $null
    try {
        $Selected = Get-QualifiedSm75Gpu -Rows $Case.Rows -Device $Case.Device
    } catch {
        $Rejected = $true
        $Failure = $_.Exception.Message
    }
    if ($Case.Pass) {
        if ($Rejected -or $null -eq $Selected -or $Selected.index -ne $Case.Device) {
            throw "GPU fixture unexpectedly failed: $($Case.Name). Cause: $Failure"
        }
    } elseif (-not $Rejected) {
        throw "GPU fixture unexpectedly accepted: $($Case.Name)"
    }
    Write-Host "PASS selected GPU fixture: $($Case.Name)"
}
