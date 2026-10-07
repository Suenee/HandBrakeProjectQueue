namespace HandBrakeProjectQueue;

internal sealed class ScanDialog : Form
{
    private readonly Label text = new() { Dock = DockStyle.Top, Height = 30 };
    private readonly ProgressBar bar = new() { Dock = DockStyle.Top, Height = 22 };
    private readonly Button cancel = new() { AutoSize = true, Anchor = AnchorStyles.Right };
    public event EventHandler? CancelRequested;
    public ScanDialog()
    {
        Text=Strings.Get("ScanningTitle"); Width=470; Height=145; StartPosition=FormStartPosition.CenterParent;
        FormBorderStyle=FormBorderStyle.FixedDialog; MaximizeBox=false; MinimizeBox=false; ControlBox=false;
        cancel.Text=Strings.Get("Cancel"); cancel.Click+=(_,_)=>{cancel.Enabled=false;CancelRequested?.Invoke(this,EventArgs.Empty);};
        var buttons=new FlowLayoutPanel{Dock=DockStyle.Bottom,Height=45,FlowDirection=FlowDirection.RightToLeft,Padding=new Padding(8)};
        buttons.Controls.Add(cancel); Controls.Add(buttons); Controls.Add(bar); Controls.Add(text);
    }
    public void Report(int done,int total,string name){bar.Maximum=Math.Max(1,total);bar.Value=Math.Min(done,bar.Maximum);text.Text=string.Format(Strings.Get("Scanning"),done,total,name);}
}
