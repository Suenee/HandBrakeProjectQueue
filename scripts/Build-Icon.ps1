param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Destination
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$original=[System.Drawing.Image]::FromFile($Source)
try {
    $sizes=@(16,24,32,48,64,128,256)
    $frames=New-Object 'System.Collections.Generic.List[byte[]]'
    foreach($size in $sizes) {
        $bitmap=New-Object System.Drawing.Bitmap($size,$size,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $g=[System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $g.Clear([System.Drawing.Color]::Transparent)
                $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.DrawImage($original,0,0,$size,$size)
            } finally { $g.Dispose() }
            $ms=New-Object System.IO.MemoryStream
            try {
                $bitmap.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png)
                $frames.Add($ms.ToArray())
            } finally { $ms.Dispose() }
        } finally { $bitmap.Dispose() }
    }
    $dir=Split-Path -Parent $Destination
    if($dir -and -not(Test-Path -LiteralPath $dir)){New-Item -ItemType Directory -Force -Path $dir|Out-Null}
    $stream=[System.IO.File]::Create($Destination)
    try {
        $writer=New-Object System.IO.BinaryWriter($stream)
        try {
            $writer.Write([uint16]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]$frames.Count)
            $offset=6+16*$frames.Count
            for($i=0;$i -lt $frames.Count;$i++) {
                $size=$sizes[$i]
                $writer.Write([byte]$(if($size -eq 256){0}else{$size}))
                $writer.Write([byte]$(if($size -eq 256){0}else{$size}))
                $writer.Write([byte]0)
                $writer.Write([byte]0)
                $writer.Write([uint16]1)
                $writer.Write([uint16]32)
                $writer.Write([uint32]$frames[$i].Length)
                $writer.Write([uint32]$offset)
                $offset+=$frames[$i].Length
            }
            foreach($frame in $frames){$writer.Write($frame)}
        } finally { $writer.Dispose() }
    } finally { $stream.Dispose() }
} finally { $original.Dispose() }
Write-Host "Icon generated: $Destination"
