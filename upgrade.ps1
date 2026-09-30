param([Parameter(Mandatory=$true)][string]$RepositoryPath)
$ErrorActionPreference='Stop'
$updaterRevision='0.02'
$branch='main'
$expectedOrigin='https://github.com/Suenee/HandBrakeProjectQueue.git'
$RepositoryPath=$RepositoryPath.TrimEnd('\')
$logDir=Join-Path $RepositoryPath 'logs'
New-Item -ItemType Directory -Force -Path $logDir|Out-Null
$log=Join-Path $logDir 'upgrade.log'
Set-Content -LiteralPath $log -Value '' -Encoding UTF8
function Log([string]$m){$line=('{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$m);Write-Host $m;Add-Content -LiteralPath $log -Value $line -Encoding UTF8}
function Invoke-Native([string]$File,[string[]]$ArgumentList){
 $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
 try{& $File @ArgumentList 2>&1|ForEach-Object{Log "$_"};$rc=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
 return $rc
}
function GitText([string[]]$ArgumentList){
 $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
 try{$o=& git.exe @ArgumentList 2>$null;$rc=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
 if($rc -ne 0){return $null};return (($o|Out-String).Trim())
}
function Fail([string]$phase,[string]$m,[int]$code=1){Log "ERROR [$phase] $m";Log "STATUS: FAILED - phase=$phase";exit $code}
try{
 Push-Location $RepositoryPath
 $env:GIT_CONFIG_COUNT='1';$env:GIT_CONFIG_KEY_0='safe.directory';$env:GIT_CONFIG_VALUE_0='*'
 Log "Repository:  $RepositoryPath";Log "Branch:      $branch";Log "Updater:     $updaterRevision"
 if(-not(Test-Path '.git')){Fail 'REPOSITORY' 'Bootstrap did not create a Git repository.' 10}
 $origin=GitText @('remote','get-url','origin')
 if(-not $origin){Fail 'REPOSITORY' 'Git remote origin is missing.' 11}
 if($origin -ne $expectedOrigin){Fail 'REPOSITORY' "Unexpected origin: $origin" 12}
 $start=GitText @('rev-parse','HEAD');if(-not $start){$start='unknown'}
 $current='unknown';if(Test-Path VERSION){$current=(Get-Content VERSION -Raw).Trim()}
 $rc=Invoke-Native 'git.exe' @('fetch','origin',$branch);if($rc -ne 0){Fail 'REPOSITORY' "git fetch failed ($rc)." 13}
 $target=GitText @('show',('origin/{0}:VERSION' -f $branch));if(-not $target){$target='unknown'}
 Log 'Application: HandBrake Project Queue';Log "Current:     $current";Log "Target:      $target"
 $status=GitText @('status','--porcelain','--untracked-files=no')
 $dirty=@($status -split "[
]+"|Where-Object{$_ -and $_ -notmatch 'upgrade\.cmd$' -and $_ -notmatch 'upgrade\.ps1$'})
 if($dirty.Count -gt 0){$dirty|ForEach-Object{Log "LOCAL CHANGE: $_"};Fail 'REPOSITORY' 'Tracked local changes detected. Commit or revert them before upgrade.' 14}
 $rc=Invoke-Native 'git.exe' @('checkout','-B',$branch,"origin/$branch");if($rc -ne 0){Fail 'REPOSITORY' "git checkout failed ($rc)." 15}
 $rc=Invoke-Native 'git.exe' @('reset','--hard',"origin/$branch");if($rc -ne 0){Fail 'REPOSITORY' "git reset failed ($rc)." 16}
 $head=GitText @('rev-parse','HEAD');$remote=GitText @('rev-parse',"origin/$branch")
 if(-not $head -or $head -ne $remote){Fail 'VERIFY' 'HEAD does not match target branch.' 17}
 $version=(Get-Content VERSION -Raw).Trim()
 Log "Starting commit:     $start";Log "Synchronized commit: $head";Log "Result version:      $version";Log 'STATUS: SUCCESS - phase=COMPLETE'
 Write-Host '';Write-Host '========================================' -ForegroundColor Green;Write-Host 'UPGRADE SUCCESSFUL' -ForegroundColor Green;Write-Host "HandBrake Project Queue v$version" -ForegroundColor Green;Write-Host '========================================' -ForegroundColor Green
 exit 0
}catch{try{Log "ERROR: $($_.Exception.Message)";Log 'STATUS: FAILED - phase=UNKNOWN'}catch{};exit 99}finally{try{Pop-Location}catch{}}
