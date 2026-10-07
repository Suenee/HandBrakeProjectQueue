namespace HandBrakeProjectQueue;

internal sealed class MainForm : Form
{
    private readonly AppSettings settings;
    private readonly AppLog log;
    private readonly ComboBox projects=new(){DropDownStyle=ComboBoxStyle.DropDown,Dock=DockStyle.Top,MaxDropDownItems=8};
    private readonly DataGridView files=new(){Dock=DockStyle.Fill,AllowUserToAddRows=false,AllowUserToDeleteRows=false,RowHeadersVisible=false,AutoSizeColumnsMode=DataGridViewAutoSizeColumnsMode.Fill};
    private readonly Button openHb=new(){AutoSize=true}, close=new(){AutoSize=true};
    private List<ProjectItem> all=[]; private bool filtering;

    public MainForm()
    {
        settings=AppSettings.Load(); Strings.ApplyCulture(settings.Language); log=new AppLog(settings.Logging);
        Text="HandBrake Project Queue 0.06";Width=820;Height=390;StartPosition=FormStartPosition.CenterScreen;
        var menu=new MenuStrip();var fileMenu=new ToolStripMenuItem(Strings.Get("FileMenu"));var si=new ToolStripMenuItem(Strings.Get("Settings"));var ei=new ToolStripMenuItem(Strings.Get("Close"));
        si.Click+=(_,_)=>ShowSettings();ei.Click+=(_,_)=>Close();fileMenu.DropDownItems.AddRange([si,ei]);menu.Items.Add(fileMenu);MainMenuStrip=menu;
        files.Columns.Add(new DataGridViewCheckBoxColumn{HeaderText="",Width=38,AutoSizeMode=DataGridViewAutoSizeColumnMode.None});
        files.Columns.Add(new DataGridViewTextBoxColumn{HeaderText=Strings.Get("File"),ReadOnly=true});
        files.Columns.Add(new DataGridViewTextBoxColumn{HeaderText=Strings.Get("Status"),ReadOnly=true,Width=160,AutoSizeMode=DataGridViewAutoSizeColumnMode.None});
        var top=new Panel{Dock=DockStyle.Top,Height=76,Padding=new Padding(12,8,12,6)};top.Controls.Add(projects);top.Controls.Add(new Label{Text=Strings.Get("Project"),Dock=DockStyle.Top,Height=24});
        openHb.Text=Strings.Get("OpenHandBrake");close.Text=Strings.Get("Close");
        var bottom=new FlowLayoutPanel{Dock=DockStyle.Bottom,Height=50,FlowDirection=FlowDirection.RightToLeft,Padding=new Padding(12,8,12,8)};bottom.Controls.Add(close);bottom.Controls.Add(openHb);
        Controls.Add(files);Controls.Add(bottom);Controls.Add(top);Controls.Add(menu);
        projects.DropDownHeight=projects.ItemHeight*4+2;
        projects.TextUpdate+=(_,_)=>FilterProjects();projects.SelectedIndexChanged+=(_,_)=>ShowProject(projects.Text);
        openHb.Click+=(_,_)=>OpenSelected();close.Click+=(_,_)=>Close();FormClosed+=(_,_)=>log.Dispose();
        Shown+=async(_,_)=>await StartScanAsync();
    }
    private async Task StartScanAsync()
    {
        using var cts=new CancellationTokenSource();using var dialog=new ScanDialog();dialog.CancelRequested+=(_,_)=>cts.Cancel();
        var reporter=new Progress<(int done,int total,string name)>(x=>dialog.Report(x.done,x.total,x.name));
        var task=new ProjectScanner(settings,log).ScanAsync(reporter,cts.Token);dialog.Shown+=async(_,_)=>{try{all=await task;}catch(OperationCanceledException){}catch(Exception ex){log.Write("ERROR",ex.ToString());MessageBox.Show(this,ex.Message,Text,MessageBoxButtons.OK,MessageBoxIcon.Error);}finally{dialog.Close();}};
        dialog.ShowDialog(this);Populate(all.Where(x=>x.PendingCount>0));log.Write("SCAN",$"Available projects: {all.Count}");
    }
    private void Populate(IEnumerable<ProjectItem> source){filtering=true;var typed=projects.Text;projects.Items.Clear();foreach(var p in source)projects.Items.Add(p.Name);projects.Text=typed;projects.SelectionStart=typed.Length;filtering=false;}
    private void FilterProjects(){if(filtering)return;var typed=projects.Text;var matches=string.IsNullOrWhiteSpace(typed)?all.Where(x=>x.PendingCount>0):all.Where(x=>x.Name.Contains(typed,StringComparison.CurrentCultureIgnoreCase));Populate(matches);if(projects.Items.Count>0)projects.DroppedDown=true;}
    private void ShowProject(string name){var p=all.FirstOrDefault(x=>x.Name.Equals(name,StringComparison.CurrentCultureIgnoreCase));if(p is null)return;files.Rows.Clear();foreach(var f in p.Files)files.Rows.Add(!f.Converted,f.Name,f.Converted?Strings.Get("Converted"):Strings.Get("Pending"));log.Write("PROJECT",$"Selected: {p.Name}");}
    private void OpenSelected()
    {
        var p=all.FirstOrDefault(x=>x.Name.Equals(projects.Text,StringComparison.CurrentCultureIgnoreCase));if(p is null)return;
        var selected=new List<string>();for(int i=0;i<files.Rows.Count;i++)if(Convert.ToBoolean(files.Rows[i].Cells[0].Value??false))selected.Add(p.Files[i].FullPath);
        if(selected.Count==0){MessageBox.Show(this,Strings.Get("NoSelection"));return;}
        try{new HandBrakeService(settings,log).OpenSources(selected);}catch(Exception ex){log.Write("ERROR",ex.ToString());MessageBox.Show(this,ex.Message,Text,MessageBoxButtons.OK,MessageBoxIcon.Error);}
    }
    private void ShowSettings(){using var d=new SettingsForm(settings);if(d.ShowDialog(this)==DialogResult.OK){settings.Save();MessageBox.Show(this,"Settings saved. Restart the application to apply language/logging changes.");}}
}
