namespace HandBrakeProjectQueue;

internal sealed class SettingsForm : Form
{
    private readonly AppSettings settings;
    private readonly TextBox root=new(),delivery=new(),suffix=new(),handbrake=new();
    private readonly ComboBox language=new(){DropDownStyle=ComboBoxStyle.DropDownList},logging=new(){DropDownStyle=ComboBoxStyle.DropDownList};
    public SettingsForm(AppSettings settings)
    {
        this.settings=settings;Text=Strings.Get("Settings");Width=610;Height=310;StartPosition=FormStartPosition.CenterParent;FormBorderStyle=FormBorderStyle.FixedDialog;MaximizeBox=false;MinimizeBox=false;
        language.Items.AddRange(["cs","en"]);logging.Items.AddRange(["off","single","all"]);LoadValues();
        var t=new TableLayoutPanel{Dock=DockStyle.Fill,ColumnCount=3,RowCount=7,Padding=new Padding(12)};t.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,180));t.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));t.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,42));
        AddRow(t,0,Strings.Get("Root"),root);AddRow(t,1,Strings.Get("Delivery"),delivery);AddRow(t,2,Strings.Get("Suffix"),suffix);AddRow(t,3,Strings.Get("HandBrakePath"),handbrake);AddRow(t,4,Strings.Get("Language"),language);AddRow(t,5,Strings.Get("Logging"),logging);
        var browse=new Button{Text="…",Dock=DockStyle.Fill};browse.Click+=(_,_)=>{using var d=new OpenFileDialog{Filter="HandBrake|HandBrake.exe|Programs (*.exe)|*.exe"};if(d.ShowDialog(this)==DialogResult.OK)handbrake.Text=d.FileName;};t.Controls.Add(browse,2,3);
        var buttons=new FlowLayoutPanel{Dock=DockStyle.Fill,FlowDirection=FlowDirection.RightToLeft};
        var cancel=new Button{Text=Strings.Get("Cancel"),AutoSize=true};var save=new Button{Text=Strings.Get("Save"),AutoSize=true};var reset=new Button{Text="↺",AutoSize=true,AccessibleName=Strings.Get("Reset")};
        cancel.Click+=(_,_)=>{DialogResult=DialogResult.Cancel;Close();};save.Click+=(_,_)=>SaveValues();reset.Click+=(_,_)=>LoadDefaults();buttons.Controls.Add(cancel);buttons.Controls.Add(save);buttons.Controls.Add(reset);t.Controls.Add(buttons,1,6);Controls.Add(t);
    }
    private void LoadValues(){root.Text=settings.EditingRoot;delivery.Text=settings.DeliveryFolder;suffix.Text=settings.ConvertedSuffix;handbrake.Text=string.IsNullOrWhiteSpace(settings.HandBrakePath)?HandBrakeService.FindExecutable():settings.HandBrakePath;language.SelectedItem=settings.Language;logging.SelectedItem=settings.Logging;}
    private void LoadDefaults(){var d=new AppSettings();root.Text=d.EditingRoot;delivery.Text=d.DeliveryFolder;suffix.Text=d.ConvertedSuffix;handbrake.Text=HandBrakeService.FindExecutable();language.SelectedItem=d.Language;logging.SelectedItem=d.Logging;}
    private void SaveValues(){settings.EditingRoot=root.Text;settings.DeliveryFolder=delivery.Text;settings.ConvertedSuffix=suffix.Text;settings.HandBrakePath=handbrake.Text;settings.Language=language.SelectedItem?.ToString()??"cs";settings.Logging=logging.SelectedItem?.ToString()??"single";DialogResult=DialogResult.OK;Close();}
    private static void AddRow(TableLayoutPanel t,int row,string label,Control c){t.Controls.Add(new Label{Text=label,AutoSize=true,Anchor=AnchorStyles.Left},0,row);c.Dock=DockStyle.Fill;t.Controls.Add(c,1,row);}
}
