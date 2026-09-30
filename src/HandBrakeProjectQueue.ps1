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
$form=New-Object Windows.Forms.Form;$form.Text="$($L.title) 0.02";$form.Size=New-Object Drawing.Size(780,390);$form.StartPosition='CenterScreen'
$menu=New-Object Windows.Forms.MenuStrip;$fileMenu=New-Object Windows.Forms.ToolStripMenuItem('Soubor');$settingsItem=New-Object Windows.Forms.ToolStripMenuItem('Nastavení...');$closeItem=New-Object Windows.Forms.ToolStripMenuItem('Zavřít');[void]$fileMenu.DropDownItems.Add($settingsItem);[void]$fileMenu.DropDownItems.Add($closeItem);[void]$menu.Items.Add($fileMenu);$form.MainMenuStrip=$menu;$form.Controls.Add($menu)
$label=New-Object Windows.Forms.Label;$label.Text=$L.project;$label.Location=New-Object Drawing.Point(18,42);$label.AutoSize=$true;$form.Controls.Add($label)
$combo=New-Object Windows.Forms.ComboBox;$combo.Location=New-Object Drawing.Point(18,66);$combo.Size=New-Object Drawing.Size(725,28);$combo.DropDownStyle='DropDown';$combo.AutoCompleteMode='SuggestAppend';$combo.AutoCompleteSource='CustomSource';$form.Controls.Add($combo)
$hint=New-Object Windows.Forms.Label;$hint.Text=$L.searchHint;$hint.Location=New-Object Drawing.Point(18,97);$hint.AutoSize=$true;$form.Controls.Add($hint)
$fl=New-Object Windows.Forms.Label;$fl.Text=$L.files;$fl.Location=New-Object Drawing.Point(18,129);$fl.AutoSize=$true;$form.Controls.Add($fl)
$list=New-Object Windows.Forms.DataGridView;$list.Location=New-Object Drawing.Point(18,154);$list.Size=New-Object Drawing.Size(725,145);$list.AllowUserToAddRows=$false;$list.RowHeadersVisible=$false;$list.AutoSizeColumnsMode='Fill';$c0=New-Object Windows.Forms.DataGridViewCheckBoxColumn;$c0.HeaderText='';$c0.Width=38;$c0.AutoSizeMode='None';$c1=New-Object Windows.Forms.DataGridViewTextBoxColumn;$c1.HeaderText='Soubor';$c1.ReadOnly=$true;$c2=New-Object Windows.Forms.DataGridViewTextBoxColumn;$c2.HeaderText='Stav';$c2.ReadOnly=$true;$c2.Width=170;$c2.AutoSizeMode='None';[void]$list.Columns.Add($c0);[void]$list.Columns.Add($c1);[void]$list.Columns.Add($c2);$form.Controls.Add($list)
$add=New-Object Windows.Forms.Button;$add.Text=$L.add;$add.Location=New-Object Drawing.Point(455,315);$add.Size=New-Object Drawing.Size(185,32);$form.Controls.Add($add)
$cancel=New-Object Windows.Forms.Button;$cancel.Text='Zavřít';$cancel.Location=New-Object Drawing.Point(650,315);$cancel.Size=New-Object Drawing.Size(93,32);$cancel.Add_Click({$form.Close()});$form.Controls.Add($cancel)
foreach($p in $all){[void]$combo.AutoCompleteCustomSource.Add($p.Name)};foreach($p in $pending){[void]$combo.Items.Add($p.Name)}
function Show-Project([string]$name){$list.Rows.Clear();if(-not $lookup.ContainsKey($name)){return};foreach($x in $lookup[$name].Files){$state=if($x.Converted){$L.converted}else{$L.pending};[void]$list.Rows.Add((-not $x.Converted),$x.File.Name,$state)}}

function Find-HandBrake { foreach($p in @($env:ProgramFiles+'\HandBrake\HandBrake.exe',$env:LOCALAPPDATA+'\Programs\HandBrake\HandBrake.exe')){if($p -and (Test-Path -LiteralPath $p)){return $p}};return '' }
function Show-Settings {
 $dlg=New-Object Windows.Forms.Form;$dlg.Text='Nastavení';$dlg.Size=New-Object Drawing.Size(620,360);$dlg.StartPosition='CenterParent';$dlg.FormBorderStyle='FixedDialog';$dlg.MaximizeBox=$false;$dlg.MinimizeBox=$false
 $labels=@('Kořen projektů','Složka DELIVERY','Přípona převedeného souboru','Cesta k HandBrake','Jazyk','Logování');$vals=@([string]$config.editingRoot,[string]$config.deliveryFolder,[string]$config.convertedSuffix,[string]$config.handBrakePath,[string]$config.language,[string]$config.logging);$boxes=@()
 for($i=0;$i -lt $labels.Count;$i++){$l=New-Object Windows.Forms.Label;$l.Text=$labels[$i];$l.Location=New-Object Drawing.Point(15,(20+$i*42));$l.Size=New-Object Drawing.Size(180,22);$dlg.Controls.Add($l);$b=New-Object Windows.Forms.TextBox;$b.Text=$vals[$i];$b.Location=New-Object Drawing.Point(200,(17+$i*42));$b.Size=New-Object Drawing.Size(365,24);$dlg.Controls.Add($b);$boxes+=$b}
 if([string]::IsNullOrWhiteSpace($boxes[3].Text)){$boxes[3].Text=Find-HandBrake}
 $browse=New-Object Windows.Forms.Button;$browse.Text='...';$browse.Location=New-Object Drawing.Point(568,143);$browse.Size=New-Object Drawing.Size(30,24);$browse.Add_Click({$fd=New-Object Windows.Forms.OpenFileDialog;$fd.Filter='HandBrake|HandBrake.exe|Programy (*.exe)|*.exe';if($fd.ShowDialog() -eq 'OK'){$boxes[3].Text=$fd.FileName}});$dlg.Controls.Add($browse)
 $ok=New-Object Windows.Forms.Button;$ok.Text='Uložit';$ok.Location=New-Object Drawing.Point(410,275);$ok.Size=New-Object Drawing.Size(75,28);$ok.Add_Click({$obj=[ordered]@{editingRoot=$boxes[0].Text;deliveryFolder=$boxes[1].Text;convertedSuffix=$boxes[2].Text;videoExtensions=@($config.videoExtensions);handBrakePath=$boxes[3].Text;language=$boxes[4].Text;logging=$boxes[5].Text};$obj|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $repoRoot 'config.local.json') -Encoding UTF8;$dlg.Close()});$dlg.Controls.Add($ok);[void]$dlg.ShowDialog($form)
}
$settingsItem.Add_Click({Show-Settings});$closeItem.Add_Click({$form.Close()})
$combo.Add_SelectedIndexChanged({Show-Project $combo.Text})
$combo.Add_KeyDown({if($_.KeyCode -eq [Windows.Forms.Keys]::Enter -and $lookup.ContainsKey($combo.Text)){Show-Project $combo.Text;$_.SuppressKeyPress=$true}})
$add.Add_Click({if(-not $lookup.ContainsKey($combo.Text)){return};$p=$lookup[$combo.Text];$selected=@();for($i=0;$i -lt $list.Rows.Count;$i++){if([bool]$list.Rows[$i].Cells[0].Value){$selected+=$p.Files[$i].File.FullName}};if($selected.Count -eq 0){return};$r=Add-ToHandBrakeQueue -SourceFiles $selected;if(-not $r.Success){[Windows.Forms.MessageBox]::Show($L.integrationPending,$L.title,'OK','Information')|Out-Null}})
if($pending.Count -gt 0){$combo.SelectedIndex=0;Show-Project $combo.Text};[void]$form.ShowDialog()
