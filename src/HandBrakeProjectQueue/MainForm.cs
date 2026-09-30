namespace HandBrakeProjectQueue;

internal sealed class MainForm : Form
{
    private readonly AppSettings settings = AppSettings.Load();
    private readonly ComboBox projects = new() { DropDownStyle = ComboBoxStyle.DropDown, Dock = DockStyle.Top };
    private readonly DataGridView files = new() { Dock = DockStyle.Fill, AllowUserToAddRows = false, AllowUserToDeleteRows = false, RowHeadersVisible = false, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill };
    private readonly ProgressBar progress = new() { Dock = DockStyle.Fill };
    private readonly Label scanText = new() { AutoSize = true, Text = "Připravuji prohledávání…" };
    private readonly Button cancelScan = new() { Text = "Zrušit", AutoSize = true };
    private readonly Button close = new() { Text = "Zavřít", AutoSize = true };
    private readonly Button add = new() { Text = "Přidat vybrané do HandBrake", AutoSize = true };
    private readonly CancellationTokenSource scanCts = new();
    private List<ProjectItem> all = [];
    private bool filtering;

    public MainForm()
    {
        Text = "HandBrake Project Queue 0.04";
        Width = 820; Height = 430; StartPosition = FormStartPosition.CenterScreen;

        var menu = new MenuStrip();
        var fileMenu = new ToolStripMenuItem("Soubor");
        var settingsItem = new ToolStripMenuItem("Nastavení…");
        var exitItem = new ToolStripMenuItem("Zavřít");
        settingsItem.Click += (_, _) => ShowSettings();
        exitItem.Click += (_, _) => Close();
        fileMenu.DropDownItems.AddRange([settingsItem, exitItem]); menu.Items.Add(fileMenu);
        MainMenuStrip = menu;

        files.Columns.Add(new DataGridViewCheckBoxColumn { HeaderText = "", Width = 38, AutoSizeMode = DataGridViewAutoSizeColumnMode.None });
        files.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "Soubor", ReadOnly = true });
        files.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "Stav", ReadOnly = true, Width = 160, AutoSizeMode = DataGridViewAutoSizeColumnMode.None });

        var top = new Panel { Dock = DockStyle.Top, Height = 76, Padding = new Padding(12, 8, 12, 6) };
        top.Controls.Add(projects); top.Controls.Add(new Label { Text = "Projekt", Dock = DockStyle.Top, Height = 24 });
        var bottom = new TableLayoutPanel { Dock = DockStyle.Bottom, Height = 72, ColumnCount = 5, Padding = new Padding(12, 8, 12, 8) };
        bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize)); bottom.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100)); bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize)); bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize)); bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        bottom.Controls.Add(scanText, 0, 0); bottom.Controls.Add(progress, 1, 0); bottom.Controls.Add(cancelScan, 2, 0); bottom.Controls.Add(add, 3, 0); bottom.Controls.Add(close, 4, 0);
        Controls.Add(files); Controls.Add(bottom); Controls.Add(top); Controls.Add(menu);

        projects.TextUpdate += (_, _) => FilterProjects();
        projects.SelectedIndexChanged += (_, _) => ShowProject(projects.Text);
        cancelScan.Click += (_, _) => scanCts.Cancel();
        close.Click += (_, _) => Close();
        FormClosing += (_, _) => scanCts.Cancel();
        Shown += async (_, _) => await StartScanAsync();
    }

    private async Task StartScanAsync()
    {
        try
        {
            var reporter = new Progress<(int done, int total, string name)>(x => { progress.Maximum = Math.Max(1, x.total); progress.Value = Math.Min(x.done, progress.Maximum); scanText.Text = $"Prohledávám {x.done} / {x.total}  {x.name}"; });
            all = await new ProjectScanner(settings).ScanAsync(reporter, scanCts.Token);
            Populate(all.Where(x => x.PendingCount > 0)); scanText.Text = $"Nalezeno projektů: {all.Count}"; progress.Value = progress.Maximum; cancelScan.Enabled = false;
        }
        catch (OperationCanceledException) { scanText.Text = $"Prohledávání zrušeno — nalezené projekty zůstávají k dispozici."; cancelScan.Enabled = false; }
        catch (Exception ex) { scanText.Text = "Chyba prohledávání"; MessageBox.Show(this, ex.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }

    private void Populate(IEnumerable<ProjectItem> source)
    {
        filtering = true; var typed = projects.Text; projects.Items.Clear(); foreach (var p in source) projects.Items.Add(p.Name); projects.Text = typed; projects.SelectionStart = typed.Length; filtering = false;
    }
    private void FilterProjects()
    {
        if (filtering) return; var typed = projects.Text;
        var matches = string.IsNullOrWhiteSpace(typed) ? all.Where(x => x.PendingCount > 0) : all.Where(x => x.Name.Contains(typed, StringComparison.CurrentCultureIgnoreCase));
        Populate(matches); if (projects.Items.Count > 0) projects.DroppedDown = true;
    }
    private void ShowProject(string name)
    {
        var p = all.FirstOrDefault(x => x.Name.Equals(name, StringComparison.CurrentCultureIgnoreCase)); if (p is null) return;
        files.Rows.Clear(); foreach (var f in p.Files) files.Rows.Add(!f.Converted, f.Name, f.Converted ? "již převedeno" : "čeká na převod");
    }
    private void ShowSettings()
    {
        using var dialog = new SettingsForm(settings); if (dialog.ShowDialog(this) == DialogResult.OK) settings.Save();
    }
}
