# Shared Windows PowerShell 5.1 GPU contract for the physical acceptance workflow.
# Accept only the selected device, never combined regex matches across GPU rows.
function Get-QualifiedSm75Gpu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Rows,
        [ValidateRange(0,15)]
        [int]$Device = 0
    )

    $Selected = $null
    foreach ($Row in $Rows) {
        $Parts = @(([string]$Row -split ',') | ForEach-Object { $_.Trim() })
        if ($Parts.Count -ne 5) {
            throw "Invalid nvidia-smi inventory row (expected index,name,memory,compute_cap,driver)."
        }
        $Index = -1
        if (-not [int]::TryParse($Parts[0], [ref]$Index) -or $Index -lt 0) {
            throw "Invalid nvidia-smi device index."
        }
        if ($Index -ne $Device) { continue }
        if ($null -ne $Selected) {
            throw "Duplicate selected GPU index $Device in nvidia-smi inventory."
        }
        $MemoryMiB = 0
        if (-not [int]::TryParse($Parts[2], [ref]$MemoryMiB)) {
            throw "Invalid VRAM reading for GPU $Device."
        }
        $DriverMajor = 0
        if (-not [int]::TryParse(($Parts[4] -split '\.')[0], [ref]$DriverMajor)) {
            throw "Invalid NVIDIA driver version for GPU $Device."
        }
        if ($Parts[1] -notmatch '\bRTX\s*2080\s*Ti\b' -or
            $Parts[3] -ne '7.5' -or
            $MemoryMiB -lt 20000 -or
            $DriverMajor -lt 580) {
            throw "GPU $Device is not a qualified RTX 2080 Ti 22GB / SM75 / R580+ device."
        }
        $Selected = [pscustomobject]@{
            index = $Index
            name = $Parts[1]
            memory_total_mib = $MemoryMiB
            compute_capability = $Parts[3]
            driver_version = $Parts[4]
        }
    }
    if ($null -eq $Selected) {
        throw "Selected GPU index $Device was not found in nvidia-smi inventory."
    }
    return $Selected
}
