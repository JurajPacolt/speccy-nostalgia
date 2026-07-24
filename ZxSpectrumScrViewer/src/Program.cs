namespace ZxSpectrumScrViewer;

static class Program
{
    /// <summary>
    ///  The main entry point for the application.
    /// </summary>
    [STAThread]
    static void Main(string[] args)
    {
        // To customize application configuration such as set high DPI settings or default font,
        // see https://aka.ms/applicationconfiguration.
        ApplicationConfiguration.Initialize();
        string? initialFilePath = args.FirstOrDefault(static arg => !string.IsNullOrWhiteSpace(arg));
        Application.Run(new MainForm(initialFilePath));
    }    
}