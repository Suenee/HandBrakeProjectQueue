param([Parameter(Mandatory=$true)][string]$RepositoryPath)
$ErrorActionPreference = 'Stop'
$updaterRevision = '0.08'
$branch = 'main'
$expectedOrigin = 'https://github.com/Suenee/HandBrakeProjectQueue.git'
$RepositoryPath = $RepositoryPath.TrimEnd('\')
$logDir = Join-Path $RepositoryPath 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'upgrade.log'
Set-Content -LiteralPath $log -Value '' -Encoding UTF8
function Write-Log([string]$Message,[string]$Color='Gray'){ $line=('{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Message); Write-Host $Message -ForegroundColor $Color; Add-Content -LiteralPath $log -Value $line -Encoding UTF8 }
function Invoke-Native([string]$File,[string[]]$ArgumentList){ $old=$ErrorActionPreference;$ErrorActionPreference='Continue';try{& $File @ArgumentList 2>&1|ForEach-Object{Write-Log "$_"};$rc=$LASTEXITCODE}finally{$ErrorActionPreference=$old};return $rc }
function Get-GitText([string[]]$ArgumentList){ $old=$ErrorActionPreference;$ErrorActionPreference='Continue';try{$o=& git.exe @ArgumentList 2>$null;$rc=$LASTEXITCODE}finally{$ErrorActionPreference=$old};if($rc -ne 0){return $null};return (($o|Out-String).Trim()) }
function Stop-Upgrade([string]$Phase,[string]$Message,[int]$Code=1){Write-Log "ERROR [$Phase] $Message" 'Red';Write-Log "STATUS: FAILED - phase=$Phase" 'Red';exit $Code}
try{
 Push-Location $RepositoryPath
 $env:GIT_CONFIG_COUNT='1';$env:GIT_CONFIG_KEY_0='safe.directory';$env:GIT_CONFIG_VALUE_0='*'
 Write-Host '';Write-Host '[SELF-UPDATE]' -ForegroundColor Cyan;Write-Log "Repository:  $RepositoryPath";Write-Log "Branch:      $branch";Write-Log "Updater:     $updaterRevision"
 if(-not(Test-Path '.git')){Stop-Upgrade 'REPOSITORY' 'Bootstrap did not create a Git repository.' 10}
 $origin=Get-GitText @('remote','get-url','origin');if(-not $origin){Stop-Upgrade 'REPOSITORY' 'Git remote origin is missing.' 11};if($origin -ne $expectedOrigin){Stop-Upgrade 'REPOSITORY' "Unexpected origin: $origin" 12}
 $start=Get-GitText @('rev-parse','HEAD');if(-not $start){$start='unknown'};$current='unknown';if(Test-Path VERSION){$current=(Get-Content VERSION -Raw).Trim()}
 $rc=Invoke-Native 'git.exe' @('fetch','origin',$branch);if($rc -ne 0){Stop-Upgrade 'SELF-UPDATE' "git fetch failed ($rc)." 13}
 $target=Get-GitText @('show',("origin/{0}:VERSION" -f $branch));if(-not $target){$target='unknown'}
 Write-Host '';Write-Host '=== VERSION ===' -ForegroundColor Cyan;Write-Log 'Application: HandBrake Project Queue';Write-Log "Current:     $current" 'Yellow';Write-Log "Target:      $target" 'Cyan';Write-Log "Updater:     $updaterRevision";Write-Log "Branch:      $branch"
 Write-Host '';Write-Host '[REPOSITORY]' -ForegroundColor Cyan
 $recovery=$false
 $inProgress=@('rebase-merge','rebase-apply','MERGE_HEAD','CHERRY_PICK_HEAD')|Where-Object{Test-Path (Join-Path (Join-Path $RepositoryPath '.git') $_)}
 $ahead=Get-GitText @('rev-list','--count',("origin/{0}..HEAD" -f $branch))
 $status=Get-GitText @('status','--porcelain','--untracked-files=no')
 $dirty=@($status -split "[\r\n]+" | Where-Object {$_})
 if($inProgress -or $null -eq $ahead -or [int]$ahead -gt 0 -or $dirty.Count -gt 0){
   $recovery=$true
   Write-Log 'WARNING: Local Git history/edits or an interrupted rebase detected. Original checkout will remain untouched; building from a clean GitHub snapshot.' 'Yellow'
   Write-Log ("Git state: in-progress={0}; ahead={1}; tracked-changes={2}" -f [bool]$inProgress,$ahead,$dirty.Count)
 }
 $sourceRoot=$RepositoryPath
 $snapshot=Join-Path $env:TEMP ("HBPQ_source_{0}" -f [guid]::NewGuid().ToString('N'))
 if($recovery){
   New-Item -ItemType Directory -Path $snapshot -Force|Out-Null
   $zip=Join-Path $env:TEMP ("HBPQ_archive_{0}.zip" -f [guid]::NewGuid().ToString('N'))
   $rc=Invoke-Native 'git.exe' @('archive','--format=zip',"-o=$zip","origin/$branch")
   if($rc -ne 0){Stop-Upgrade 'REPOSITORY' 'Cannot create clean source snapshot.' 16}
   Expand-Archive -LiteralPath $zip -DestinationPath $snapshot -Force
   Remove-Item -LiteralPath $zip -Force
   $sourceRoot=$snapshot
 }else{
   $rc=Invoke-Native 'git.exe' @('reset','--hard',"origin/$branch")
   if($rc -ne 0){Stop-Upgrade 'REPOSITORY' "git reset failed ($rc)." 16}
 }
 $head=Get-GitText @('rev-parse',"origin/$branch")
 Write-Host '';Write-Host '[DEPENDENCIES]' -ForegroundColor Cyan
 $dotnet=Get-Command dotnet.exe -ErrorAction SilentlyContinue;if(-not $dotnet){Stop-Upgrade 'DEPENDENCIES' '.NET 10 SDK is required. Install the current stable .NET 10 SDK and run upgrade.cmd again.' 20}
 $sdkList=& dotnet.exe --list-sdks;if(-not($sdkList|Where-Object{$_ -match '^10\.'})){Stop-Upgrade 'DEPENDENCIES' '.NET 10 SDK is required. Install the current stable .NET 10 SDK and run upgrade.cmd again.' 21};Write-Log '.NET 10 SDK: OK' 'Green'
 Write-Host '';Write-Host '[ICON]' -ForegroundColor Cyan
 $iconSource=Join-Path $RepositoryPath 'assets\\HBPQ.png';$iconOutput=Join-Path $RepositoryPath 'assets\\HBPQ.ico'
 if(Test-Path -LiteralPath $iconSource){
   $iconBuilder=Join-Path $sourceRoot 'scripts\\Build-Icon.ps1'
   & $iconBuilder -Source $iconSource -Destination $iconOutput
   if(-not(Test-Path -LiteralPath $iconOutput)){Stop-Upgrade 'ICON' 'Icon generation failed.' 25}
   Write-Log 'Local PNG icon converted to ICO for EXE.' 'Green'
 }elseif(Test-Path -LiteralPath $iconOutput){Write-Log 'Using existing local ICO icon.' 'Yellow'}else{Write-Log 'WARNING: assets/HBPQ.png not found; building without custom icon.' 'Yellow'}
 Write-Host '';Write-Host '[BUILD]' -ForegroundColor Cyan
 $project=Join-Path $sourceRoot 'src\HandBrakeProjectQueue\HandBrakeProjectQueue.csproj';$out=Join-Path $RepositoryPath 'bin';$stage=Join-Path $RepositoryPath '.upgrade-stage';$backup=Join-Path $RepositoryPath '.upgrade-previous';if(Test-Path $stage){Remove-Item -LiteralPath $stage -Recurse -Force};New-Item -ItemType Directory -Path $stage -Force|Out-Null
 $rc=Invoke-Native 'dotnet.exe' @('publish',$project,'-c','Release','-r','win-x64','--self-contained','false','-o',$stage);if($rc -ne 0){Stop-Upgrade 'BUILD' "dotnet publish failed ($rc)." 30}
 $stagedExe=Join-Path $stage 'HandBrakeProjectQueue.exe';if(-not(Test-Path -LiteralPath $stagedExe)){Stop-Upgrade 'VERIFY' 'Published executable is missing; existing installation preserved.' 31}
 Write-Host '';Write-Host '[DEPLOY]' -ForegroundColor Cyan
 if(Test-Path $backup){Remove-Item -LiteralPath $backup -Recurse -Force}
 if(Test-Path $out){Copy-Item -LiteralPath $out -Destination $backup -Recurse -Force}
 try{
   if(-not(Test-Path $out)){New-Item -ItemType Directory -Path $out -Force|Out-Null}
   Get-ChildItem -LiteralPath $stage -File -Recurse|ForEach-Object{
     $relative=$_.FullName.Substring($stage.Length).TrimStart('\')
     $dest=Join-Path $out $relative
     $parent=Split-Path -Parent $dest
     if(-not(Test-Path $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
     Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
   }
   $exe=Join-Path $out 'HandBrakeProjectQueue.exe'
   if(-not(Test-Path $exe)){throw 'Deployed executable missing'}
 }catch{
   Write-Log "Deployment failed; restoring previous bin: $($_.Exception.Message)" 'Red'
   if(Test-Path $backup){
     if(Test-Path $out){Remove-Item -LiteralPath $out -Recurse -Force}
     Copy-Item -LiteralPath $backup -Destination $out -Recurse -Force
   }
   Stop-Upgrade 'DEPLOY' 'Deployment failed; previous build restored where available.' 32
 }
 if(Test-Path $stage){Remove-Item -LiteralPath $stage -Recurse -Force}

 Write-Host '';Write-Host '[VERIFY]' -ForegroundColor Cyan;$version=(Get-Content (Join-Path $sourceRoot 'VERSION') -Raw).Trim();Write-Log "Starting commit:     $start";Write-Log "Synchronized commit: $head";Write-Log "Result version:      $version";Write-Log "Executable:          $exe" 'Green'
 Write-Host '';Write-Host '========================================' -ForegroundColor Green;Write-Host 'UPGRADE SUCCESSFUL' -ForegroundColor Green;Write-Host "HandBrake Project Queue v$version" -ForegroundColor Green;Write-Host '========================================' -ForegroundColor Green;if($recovery){Write-Log 'STATUS: WARNING - phase=COMPLETE (local Git state preserved; application built from origin/main)' 'Yellow'}else{Write-Log 'STATUS: SUCCESS - phase=COMPLETE' 'Green'};exit 0
}catch{try{Write-Log "ERROR: $($_.Exception.Message)" 'Red';Write-Log 'STATUS: FAILED - phase=UNKNOWN' 'Red'}catch{};exit 99}finally{try{if($snapshot -and (Test-Path $snapshot)){Remove-Item -LiteralPath $snapshot -Recurse -Force -ErrorAction SilentlyContinue}}catch{};try{Pop-Location}catch{}}
