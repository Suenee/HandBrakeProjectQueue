namespace HandBrakeProjectQueue;

internal sealed class SettingsForm : Form
{
    private readonly AppSettings settings;
    private readonly TextBox root = new(), delivery = new(), suffix = new(), handbrake = new(), language = new(), logging = new();

    public SettingsForm(AppSettings settings)
    {
        this.settings = settings; Text = "Nastavení"; Width = 660; Height = 380; StartPosition = FormStartPosition.CenterParent; FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = false; MinimizeBox = false;
        root.Text=settings.EditingRoot; delivery.Text=settings.DeliveryFolder; suffix.Text=settings.ConvertedSuffix; handbrake.Text=string.IsNullOrWhiteSpace(settings.HandBrakePath)?FindHandBrake():settings.HandBrakePath; language.Text=settings.Language; logging.Text=settings.Logging;
        var table=new TableLayoutPanel{Dock=DockStyle.Fill,ColumnCount=3,RowCount=7,Padding=new Padding(12)};table.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,190));table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));table.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,42));
        AddRow(table,0,"Kořen projektů",root);AddRow(table,1,"Složka DELIVERY",delivery);AddRow(table,2,"Přípona převedeného souboru",suffix);AddRow(table,3,"Cesta k HandBrake",handbrake);AddRow(table,4,"Jazyk",language);AddRow(table,5,"Logování",logging);
        var browse=new Button{Text="…",Dock=DockStyle.Fill};browse.Click+=(_,_)=>{using var d=new OpenFileDialog{Filter="HandBrake|HandBrake.exe|Programy (*.exe)|*.exe"};if(d.ShowDialog(this)==DialogResult.OK)handbrake.Text=d.FileName;};table.Controls.Add(browse,2,3);
        var save=new Button{Text="Uložit",AutoSize=true,Anchor=AnchorStyles.Right};save.Click+=(_,_)=>{settings.EditingRoot=root.Text;settings.DeliveryFolder=delivery.Text;settings.ConvertedSuffix=suffix.Text;settings.HandBrakePath=handbrake.Text;settings.Language=language.Text;settings.Logging=logging.Text;DialogResult=DialogResult.OK;Close();};table.Controls.Add(save,1,6);Controls.Add(table);
    }
    private static void AddRow(TableLayoutPanel t,int row,string label,Control box){t.Controls.Add(new Label{Text=label,AutoSize=true,Anchor=AnchorStyles.Left},0,row);box.Dock=DockStyle.Fill;t.Controls.Add(box,1,row);}
    private static string FindHandBrake()
    {
        var paths=new[]{Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),"HandBrake","HandBrake.exe"),Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),"HandBrake","HandBrake.exe"),Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Programs","HandBrake","HandBrake.exe")};
        return paths.FirstOrDefault(File.Exists)??"";
    }
}
