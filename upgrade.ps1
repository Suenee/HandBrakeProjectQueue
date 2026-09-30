param([Parameter(Mandatory=$true)][string]$RepositoryPath)
$ErrorActionPreference='Stop'
$updaterRevision='0.01'
$branch='main'
$logDir=Join-Path $RepositoryPath 'logs'
New-Item -ItemType Directory -Force -Path $logDir|Out-Null
$log=Join-Path $logDir 'upgrade.log'
Set-Content -LiteralPath $log -Value '' -Encoding UTF8
function Log([string]$m){$line=('{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$m);Write-Host $m;Add-Content -LiteralPath $log -Value $line -Encoding UTF8}
function Fail([string]$phase,[string]$m,[int]$code=1){Log "ERROR [$phase] $m";Log "STATUS: FAILED - phase=$phase";exit $code}
try{
 Push-Location $RepositoryPath
 $start=(git.exe rev-parse HEAD 2>$null)
 if($LASTEXITCODE -ne 0){Fail 'REPOSITORY' 'Not a Git repository.' 10}
 $current='unknown';if(Test-Path VERSION){$current=(Get-Content VERSION -Raw).Trim()}
 git.exe fetch origin $branch 2>&1|ForEach-Object{Log "$_"};$rc=$LASTEXITCODE;if($rc -ne 0){Fail 'REPOSITORY' "git fetch failed ($rc)." 11}
 $targetRef=('origin/{0}:VERSION' -f $branch)
 $target=(git.exe show $targetRef 2>$null|Out-String).Trim();if(-not $target){$target='unknown'}
 Log 'Application: HandBrake Project Queue';Log "Current:     $current";Log "Target:      $target";Log "Updater:     $updaterRevision";Log "Branch:      $branch"
 $dirty=@(git.exe status --porcelain --untracked-files=no|Where-Object{$_ -and $_ -notmatch 'upgrade\.cmd$' -and $_ -notmatch 'upgrade\.ps1$'})
 if($dirty.Count -gt 0){Fail 'REPOSITORY' 'Tracked local changes detected. Commit or revert them before upgrade.' 12}
 git.exe reset --hard "origin/$branch" 2>&1|ForEach-Object{Log "$_"};$rc=$LASTEXITCODE;if($rc -ne 0){Fail 'REPOSITORY' "git reset failed ($rc)." 13}
 $head=(git.exe rev-parse HEAD).Trim();$remote=(git.exe rev-parse "origin/$branch").Trim();if($head -ne $remote){Fail 'VERIFY' 'HEAD does not match target branch.' 14}
 $version=(Get-Content VERSION -Raw).Trim()
 Log "Starting commit: $start";Log "Synchronized commit: $head";Log "Result version: $version";Log 'STATUS: SUCCESS - phase=COMPLETE'
 Write-Host '';Write-Host '========================================' -ForegroundColor Green;Write-Host 'UPGRADE SUCCESSFUL' -ForegroundColor Green;Write-Host "HandBrake Project Queue v$version" -ForegroundColor Green;Write-Host '========================================' -ForegroundColor Green
 exit 0
}catch{try{Log "ERROR: $($_.Exception.Message)";Log 'STATUS: FAILED - phase=UNKNOWN'}catch{};exit 99}finally{try{Pop-Location}catch{}}
