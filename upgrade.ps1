param([Parameter(Mandatory=$true)][string]$RepositoryPath)
$ErrorActionPreference = 'Stop'
$updaterRevision = '0.03'
$branch = 'main'
$expectedOrigin = 'https://github.com/Suenee/HandBrakeProjectQueue.git'
$RepositoryPath = $RepositoryPath.TrimEnd('\')
$logDir = Join-Path $RepositoryPath 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'upgrade.log'
Set-Content -LiteralPath $log -Value '' -Encoding UTF8

function Write-Log([string]$Message,[string]$Color='Gray') {
  $line = ('{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Message)
  Write-Host $Message -ForegroundColor $Color
  Add-Content -LiteralPath $log -Value $line -Encoding UTF8
}
function Invoke-Native([string]$File,[string[]]$ArgumentList) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { & $File @ArgumentList 2>&1 | ForEach-Object { Write-Log "$_" }; $rc = $LASTEXITCODE }
  finally { $ErrorActionPreference = $old }
  return $rc
}
function Get-GitText([string[]]$ArgumentList) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $o = & git.exe @ArgumentList 2>$null; $rc = $LASTEXITCODE }
  finally { $ErrorActionPreference = $old }
  if($rc -ne 0){ return $null }
  return (($o | Out-String).Trim())
}
function Stop-Upgrade([string]$Phase,[string]$Message,[int]$Code=1) {
  Write-Log "ERROR [$Phase] $Message" 'Red'
  Write-Log "STATUS: FAILED - phase=$Phase" 'Red'
  exit $Code
}

try {
  Push-Location $RepositoryPath
  $env:GIT_CONFIG_COUNT='1'
  $env:GIT_CONFIG_KEY_0='safe.directory'
  $env:GIT_CONFIG_VALUE_0='*'

  Write-Host ''
  Write-Host '[SELF-UPDATE]' -ForegroundColor Cyan
  Write-Log "Repository:  $RepositoryPath"
  Write-Log "Branch:      $branch"
  Write-Log "Updater:     $updaterRevision"

  if(-not (Test-Path '.git')) { Stop-Upgrade 'REPOSITORY' 'Bootstrap did not create a Git repository.' 10 }
  $origin = Get-GitText @('remote','get-url','origin')
  if(-not $origin) { Stop-Upgrade 'REPOSITORY' 'Git remote origin is missing.' 11 }
  if($origin -ne $expectedOrigin) { Stop-Upgrade 'REPOSITORY' "Unexpected origin: $origin" 12 }

  $start = Get-GitText @('rev-parse','HEAD'); if(-not $start){$start='unknown'}
  $current='unknown'; if(Test-Path 'VERSION'){$current=(Get-Content 'VERSION' -Raw).Trim()}
  $rc = Invoke-Native 'git.exe' @('fetch','origin',$branch)
  if($rc -ne 0){ Stop-Upgrade 'SELF-UPDATE' "git fetch failed ($rc)." 13 }
  $target = Get-GitText @('show',("origin/{0}:VERSION" -f $branch)); if(-not $target){$target='unknown'}

  Write-Host ''
  Write-Host '=== VERSION ===' -ForegroundColor Cyan
  Write-Log 'Application: HandBrake Project Queue'
  Write-Log "Current:     $current" 'Yellow'
  Write-Log "Target:      $target" 'Cyan'
  Write-Log "Updater:     $updaterRevision"
  Write-Log "Branch:      $branch"

  Write-Host ''
  Write-Host '[REPOSITORY]' -ForegroundColor Cyan
  $status = Get-GitText @('status','--porcelain','--untracked-files=no')
  $dirty = @($status -split "[\r\n]+" | Where-Object { $_ -and $_ -notmatch 'upgrade\.cmd$' -and $_ -notmatch 'upgrade\.ps1$' })
  if($dirty.Count -gt 0) {
    $backupRoot = Join-Path $RepositoryPath 'logs\upgrade-backup'
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    foreach($line in $dirty) {
      $rel = $line.Substring(3).Trim()
      if($rel -match ' -> '){$rel=($rel -split ' -> ')[-1]}
      $src = Join-Path $RepositoryPath $rel
      if(Test-Path -LiteralPath $src -PathType Leaf) {
        $dst = Join-Path $backupRoot $rel
        $parent = Split-Path -Parent $dst
        if($parent){New-Item -ItemType Directory -Force -Path $parent | Out-Null}
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Log "BACKUP: $rel -> logs\upgrade-backup\$rel" 'Yellow'
      }
    }
    Write-Log 'Tracked local changes preserved; synchronizing authoritative installation tree.' 'Yellow'
  }

  # The runner is executing from TEMP. The repository updater files are authoritative
  # bootstrap state and must not block the update merely because an older copy is local.
  $rc = Invoke-Native 'git.exe' @('reset','--hard',"origin/$branch")
  if($rc -ne 0){ Stop-Upgrade 'REPOSITORY' "git reset failed ($rc)." 16 }

  $head = Get-GitText @('rev-parse','HEAD')
  $remote = Get-GitText @('rev-parse',"origin/$branch")
  if(-not $head -or $head -ne $remote){ Stop-Upgrade 'VERIFY' 'HEAD does not match target branch.' 17 }

  Write-Host ''
  Write-Host '[VERIFY]' -ForegroundColor Cyan
  $version=(Get-Content 'VERSION' -Raw).Trim()
  Write-Log "Starting commit:     $start"
  Write-Log "Synchronized commit: $head"
  Write-Log "Result version:      $version"

  Write-Host ''
  Write-Host '========================================' -ForegroundColor Green
  Write-Host 'UPGRADE SUCCESSFUL' -ForegroundColor Green
  Write-Host "HandBrake Project Queue v$version" -ForegroundColor Green
  Write-Host '========================================' -ForegroundColor Green
  Write-Log 'STATUS: SUCCESS - phase=COMPLETE' 'Green'
  exit 0
}
catch {
  try { Write-Log "ERROR: $($_.Exception.Message)" 'Red'; Write-Log 'STATUS: FAILED - phase=UNKNOWN' 'Red' } catch {}
  exit 99
}
finally {
  try { Pop-Location } catch {}
}
