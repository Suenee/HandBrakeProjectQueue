Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'HandBrakeIntegration.ps1')
$configPath=Join-Path $repoRoot 'config.local.json'
if(-not(Test-Path -LiteralPath $configPath)){$configPath=Join-Path $repoRoot 'config.example.json'}
$config=Get-Content -LiteralPath $configPath -Raw -Encoding UTF8|ConvertFrom-Json
$langPath=Join-Path $repoRoot ("lang\{0}.json" -f $config.language)
if(-not(Test-Path -LiteralPath $langPath)){$langPath=Join-Path $repoRoot 'lang\en.json'}
$L=Get-Content -LiteralPath $langPath -Raw -Encoding UTF8|ConvertFrom-Json
function Resolve-EditingRoot {
 $p=[string]$config.editingRoot
 if(-not $p.StartsWith('*:')){if(Test-Path -LiteralPath $p){return (Resolve-Path -LiteralPath $p).Path};throw "Editing root not found: $p"}
 $tail=$p.Substring(3)
 foreach($d in [IO.DriveInfo]::GetDrives()){if(-not $d.IsReady){continue};$c=Join-Path $d.RootDirectory.FullName $tail;if(Test-Path -LiteralPath $c){return (Resolve-Path -LiteralPath $c).Path}}
 throw "Editing root not found: $p"
}
function Get-ProjectInfo([string]$path){
 $delivery=Join-Path $path ([string]$config.deliveryFolder);if(-not(Test-Path -LiteralPath $delivery -PathType Container)){return}
 $ext=@($config.videoExtensions|ForEach-Object{$_.ToLowerInvariant()})
 $files=@(Get-ChildItem -LiteralPath $delivery -File -ErrorAction SilentlyContinue|Where-Object{$ext -contains $_.Extension.ToLowerInvariant() -and $_.Name.ToLowerInvariant() -notlike '*-conv.mp4'}|Sort-Object Name)
 $items=@(foreach($f in $files){$base=[IO.Path]::GetFileNameWithoutExtension($f.Name);$out=Join-Path $delivery ($base+[string]$config.convertedSuffix);[pscustomobject]@{File=$f;Converted=(Test-Path -LiteralPath $out);ConvertedPath=$out}})
 [pscustomobject]@{Name=(Split-Path $path -Leaf);Path=$path;Files=$items;PendingCount=@($items|Where-Object{-not $_.Converted}).Count}
}
$root=Resolve-EditingRoot
$all=@(Get-ChildItem -LiteralPath $root -Directory|ForEach-Object{Get-ProjectInfo $_.FullName}|Where-Object{$_}|Sort-Object Name -Descending)
$pending=@($all|Where-Object{$_.PendingCount -gt 0});$lookup=@{};foreach($p in $all){$lookup[$p.Name]=$p}
$form=New-Object Windows.Forms.Form;$form.Text="$($L.title) 0.01";$form.Size=New-Object Drawing.Size(780,560);$form.StartPosition='CenterScreen'
$label=New-Object Windows.Forms.Label;$label.Text=$L.project;$label.Location=New-Object Drawing.Point(18,18);$label.AutoSize=$true;$form.Controls.Add($label)
$combo=New-Object Windows.Forms.ComboBox;$combo.Location=New-Object Drawing.Point(18,42);$combo.Size=New-Object Drawing.Size(725,28);$combo.DropDownStyle='DropDown';$combo.AutoCompleteMode='SuggestAppend';$combo.AutoCompleteSource='CustomSource';$form.Controls.Add($combo)
$hint=New-Object Windows.Forms.Label;$hint.Text=$L.searchHint;$hint.Location=New-Object Drawing.Point(18,73);$hint.AutoSize=$true;$form.Controls.Add($hint)
$fl=New-Object Windows.Forms.Label;$fl.Text=$L.files;$fl.Location=New-Object Drawing.Point(18,105);$fl.AutoSize=$true;$form.Controls.Add($fl)
$list=New-Object Windows.Forms.CheckedListBox;$list.Location=New-Object Drawing.Point(18,130);$list.Size=New-Object Drawing.Size(725,330);$list.CheckOnClick=$true;$form.Controls.Add($list)
$add=New-Object Windows.Forms.Button;$add.Text=$L.add;$add.Location=New-Object Drawing.Point(455,475);$add.Size=New-Object Drawing.Size(185,32);$form.Controls.Add($add)
$cancel=New-Object Windows.Forms.Button;$cancel.Text=$L.cancel;$cancel.Location=New-Object Drawing.Point(650,475);$cancel.Size=New-Object Drawing.Size(93,32);$cancel.Add_Click({$form.Close()});$form.Controls.Add($cancel)
foreach($p in $all){[void]$combo.AutoCompleteCustomSource.Add($p.Name)};foreach($p in $pending){[void]$combo.Items.Add($p.Name)}
function Show-Project([string]$name){$list.Items.Clear();if(-not $lookup.ContainsKey($name)){return};foreach($x in $lookup[$name].Files){$state=if($x.Converted){$L.converted}else{$L.pending};$i=$list.Items.Add("$($x.File.Name)    [$state]");if(-not $x.Converted){$list.SetItemChecked($i,$true)}}}
$combo.Add_SelectedIndexChanged({Show-Project $combo.Text})
$combo.Add_KeyDown({if($_.KeyCode -eq [Windows.Forms.Keys]::Enter -and $lookup.ContainsKey($combo.Text)){Show-Project $combo.Text;$_.SuppressKeyPress=$true}})
$add.Add_Click({if(-not $lookup.ContainsKey($combo.Text)){return};$p=$lookup[$combo.Text];$selected=@();for($i=0;$i -lt $list.Items.Count;$i++){if($list.GetItemChecked($i)){$selected+=$p.Files[$i].File.FullName}};if($selected.Count -eq 0){return};$r=Add-ToHandBrakeQueue -SourceFiles $selected;if(-not $r.Success){[Windows.Forms.MessageBox]::Show($L.integrationPending,$L.title,'OK','Information')|Out-Null}})
if($pending.Count -gt 0){$combo.SelectedIndex=0;Show-Project $combo.Text};[void]$form.ShowDialog()
