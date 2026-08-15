namespace ZxSpectrumScrViewer;

public partial class MainForm : Form
{
    private const float MinZoom = 0.25f;
    private const float MaxZoom = 8f;
    private const float ZoomStep = 1.25f;
    private const string BaseTitle = "ZX Spectrum SCR/CHR Viewer";
    private static readonly Color WindowBackground = Color.FromArgb(17, 24, 39);
    private static readonly Color ToolbarBackground = Color.FromArgb(31, 41, 55);
    private static readonly Color AccentColor = Color.FromArgb(59, 130, 246);
    private static readonly Color SecondaryButtonColor = Color.FromArgb(55, 65, 81);
    private static readonly Color ControlBorderColor = Color.FromArgb(75, 85, 99);
    private static readonly Color ViewerBackground = Color.FromArgb(11, 15, 26);
    private static readonly Color PrimaryTextColor = Color.FromArgb(243, 244, 246);
    private static readonly Color SecondaryTextColor = Color.FromArgb(209, 213, 219);

    private Bitmap? sourceBitmap;
    private Bitmap? currentBitmap;
    private byte[]? currentFileData;
    private string? currentFileExtension;
    private bool invertPixels;
    private bool showAttributes = true;
    private bool showGrid;
    private float zoom = 2f;

    public MainForm(string? initialFilePath = null)
    {
        InitializeComponent();
        Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath) ?? SystemIcons.Application;
        ApplyModernTheme();

        if (!string.IsNullOrWhiteSpace(initialFilePath))
        {
            string resolvedPath = Path.GetFullPath(initialFilePath);
            if (File.Exists(resolvedPath))
            {
                LoadSpectrumFile(resolvedPath);
            }
            else
            {
                MessageBox.Show(this, $"File was not found:\n{resolvedPath}", BaseTitle, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
    }

    private void ApplyModernTheme()
    {
        DoubleBuffered = true;
        BackColor = WindowBackground;
        ForeColor = PrimaryTextColor;
        Font = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point);

        topPanel.AutoSize = false;
        topPanel.Height = 60;
        topPanel.Padding = new Padding(12, 10, 12, 10);
        topPanel.BackColor = ToolbarBackground;
        topPanel.Margin = Padding.Empty;

        StyleToolbarButton(openButton, isPrimary: true);
        StyleToolbarButton(zoomOutButton);
        StyleToolbarButton(zoomInButton);
        StyleToolbarButton(actualSizeButton);
        StyleToolbarButton(fitButton);
        StyleToolbarButton(invertButton);
        StyleToolbarButton(attributesButton);
        StyleToolbarButton(gridButton);

        openButton.Width = 110;
        zoomOutButton.Width = 44;
        zoomInButton.Width = 44;
        actualSizeButton.Width = 70;
        fitButton.Width = 56;
        invertButton.Width = 92;
        attributesButton.Width = 96;
        gridButton.Width = 90;

        zoomLabel.AutoSize = false;
        zoomLabel.Width = 64;
        zoomLabel.Height = 36;
        zoomLabel.TextAlign = ContentAlignment.MiddleCenter;
        zoomLabel.Margin = new Padding(8, 0, 0, 0);
        zoomLabel.ForeColor = SecondaryTextColor;
        zoomLabel.BackColor = SecondaryButtonColor;
        zoomLabel.BorderStyle = BorderStyle.FixedSingle;

        imagePanel.BackColor = ViewerBackground;
        imagePanel.Padding = new Padding(16);
        pictureBox.BackColor = Color.Black;
        UpdateInvertButtonState();
        UpdateAttributesButtonState();
        UpdateGridButtonState();
    }

    private static void StyleToolbarButton(Button button, bool isPrimary = false)
    {
        button.AutoSize = false;
        button.Height = 36;
        button.Margin = new Padding(0, 0, 8, 0);
        button.Padding = new Padding(10, 0, 10, 0);
        button.FlatStyle = FlatStyle.Flat;
        button.FlatAppearance.BorderSize = 1;
        button.FlatAppearance.MouseOverBackColor = isPrimary
            ? Color.FromArgb(96, 165, 250)
            : Color.FromArgb(75, 85, 99);
        button.FlatAppearance.MouseDownBackColor = isPrimary
            ? Color.FromArgb(37, 99, 235)
            : Color.FromArgb(55, 65, 81);
        button.BackColor = isPrimary ? AccentColor : SecondaryButtonColor;
        button.ForeColor = PrimaryTextColor;
        button.FlatAppearance.BorderColor = isPrimary ? AccentColor : ControlBorderColor;
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        sourceBitmap?.Dispose();
        currentBitmap?.Dispose();
        base.OnFormClosing(e);
    }

    protected override void OnShown(EventArgs e)
    {
        base.OnShown(e);
        FitToWindow();
    }

    private void openButton_Click(object sender, EventArgs e)
    {
        using OpenFileDialog dialog = new()
        {
            Filter = "ZX Spectrum files (*.scr;*.chr)|*.scr;*.chr|ZX Spectrum SCR (*.scr)|*.scr|ZX Spectrum CHR (*.chr)|*.chr|All files (*.*)|*.*",
            CheckFileExists = true,
            Title = "Open ZX Spectrum SCR/CHR file"
        };

        if (dialog.ShowDialog(this) == DialogResult.OK)
        {
            LoadSpectrumFile(dialog.FileName);
        }
    }

    private void zoomOutButton_Click(object sender, EventArgs e) => ChangeZoom(1f / ZoomStep);

    private void zoomInButton_Click(object sender, EventArgs e) => ChangeZoom(ZoomStep);

    private void actualSizeButton_Click(object sender, EventArgs e) => SetZoom(1f);

    private void fitButton_Click(object sender, EventArgs e) => FitToWindow();

    private void invertButton_Click(object sender, EventArgs e)
    {
        invertPixels = !invertPixels;
        UpdateInvertButtonState();
        RefreshDisplayedBitmap();
    }

    private void attributesButton_Click(object sender, EventArgs e)
    {
        if (!string.Equals(currentFileExtension, ".scr", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        showAttributes = !showAttributes;
        UpdateAttributesButtonState();
        RenderCurrentFile(fitToWindow: false);
    }

    private void gridButton_Click(object sender, EventArgs e)
    {
        showGrid = !showGrid;
        UpdateGridButtonState();
        RefreshDisplayedBitmap();
    }

    private void imagePanel_MouseEnter(object sender, EventArgs e) => imagePanel.Focus();

    private void imagePanel_MouseWheel(object? sender, MouseEventArgs e)
    {
        if (currentBitmap is null)
        {
            return;
        }

        if (e.Delta > 0)
        {
            ChangeZoom(ZoomStep);
        }
        else if (e.Delta < 0)
        {
            ChangeZoom(1f / ZoomStep);
        }
    }

    private void LoadSpectrumFile(string fullPath)
    {
        try
        {
            byte[] data = File.ReadAllBytes(fullPath);
            currentFileData = data;
            currentFileExtension = Path.GetExtension(fullPath).ToLowerInvariant();
            showAttributes = true;
            UpdateAttributesButtonState();
            RenderCurrentFile(fitToWindow: true);
            Text = $"{BaseTitle} - {Path.GetFileName(fullPath)}";
        }
        catch (IOException ex)
        {
            MessageBox.Show(this, ex.Message, BaseTitle, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        catch (InvalidDataException ex)
        {
            MessageBox.Show(this, ex.Message, BaseTitle, MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

    private void RenderCurrentFile(bool fitToWindow)
    {
        if (currentFileData is null || string.IsNullOrWhiteSpace(currentFileExtension))
        {
            return;
        }

        Bitmap bitmap = DecodeByExtension(currentFileExtension, currentFileData, showAttributes);
        ReplaceSourceBitmap(bitmap);
        if (fitToWindow)
        {
            FitToWindow();
        }
        else
        {
            SetZoom(zoom);
        }
    }

    private static Bitmap DecodeByExtension(string extension, ReadOnlySpan<byte> data, bool withAttributes)
    {
        return extension switch
        {
            ".scr" => ZxSpectrumScrDecoder.Decode(data, useAttributes: withAttributes),
            ".chr" => ZxSpectrumChrDecoder.Decode(data),
            _ => throw new InvalidDataException($"Unsupported file type '{extension}'. Supported types are .scr and .chr.")
        };
    }

    private void ReplaceSourceBitmap(Bitmap bitmap)
    {
        Bitmap? previousSource = sourceBitmap;
        sourceBitmap = bitmap;
        previousSource?.Dispose();
        RefreshDisplayedBitmap();
    }

    private void RefreshDisplayedBitmap()
    {
        if (sourceBitmap is null)
        {
            return;
        }

        Bitmap rendered = invertPixels ? CreateInvertedBitmap(sourceBitmap) : (Bitmap)sourceBitmap.Clone();
        if (showGrid)
        {
            DrawAttributeGrid(rendered);
        }

        Bitmap? previous = currentBitmap;
        currentBitmap = rendered;
        pictureBox.Image = currentBitmap;
        previous?.Dispose();
    }

    private static Bitmap CreateInvertedBitmap(Bitmap original)
    {
        Bitmap inverted = new(original.Width, original.Height);
        for (int y = 0; y < original.Height; y++)
        {
            for (int x = 0; x < original.Width; x++)
            {
                Color pixel = original.GetPixel(x, y);
                inverted.SetPixel(x, y, Color.FromArgb(pixel.A, 255 - pixel.R, 255 - pixel.G, 255 - pixel.B));
            }
        }

        return inverted;
    }

    private static void DrawAttributeGrid(Bitmap target)
    {
        using Graphics graphics = Graphics.FromImage(target);
        using Pen pen = new(Color.FromArgb(90, 156, 163, 175));

        for (int x = 0; x < target.Width; x += 8)
        {
            graphics.DrawLine(pen, x, 0, x, target.Height - 1);
        }

        for (int y = 0; y < target.Height; y += 8)
        {
            graphics.DrawLine(pen, 0, y, target.Width - 1, y);
        }
    }

    private void UpdateInvertButtonState()
    {
        invertButton.Text = invertPixels ? "Invert ON" : "Invert";
        invertButton.BackColor = invertPixels ? AccentColor : SecondaryButtonColor;
        invertButton.FlatAppearance.BorderColor = invertPixels ? AccentColor : ControlBorderColor;
    }

    private void UpdateAttributesButtonState()
    {
        bool canToggleAttributes = string.Equals(currentFileExtension, ".scr", StringComparison.OrdinalIgnoreCase);
        attributesButton.Enabled = canToggleAttributes;
        attributesButton.Text = canToggleAttributes
            ? (showAttributes ? "Attr ON" : "Attr OFF")
            : "Attr N/A";
        attributesButton.BackColor = showAttributes && canToggleAttributes ? AccentColor : SecondaryButtonColor;
        attributesButton.FlatAppearance.BorderColor = showAttributes && canToggleAttributes ? AccentColor : ControlBorderColor;
    }

    private void UpdateGridButtonState()
    {
        gridButton.Text = showGrid ? "Grid ON" : "Grid OFF";
        gridButton.BackColor = showGrid ? AccentColor : SecondaryButtonColor;
        gridButton.FlatAppearance.BorderColor = showGrid ? AccentColor : ControlBorderColor;
    }

    private void ChangeZoom(float factor) => SetZoom(zoom * factor);

    private void SetZoom(float newZoom)
    {
        if (currentBitmap is null)
        {
            return;
        }

        float clampedZoom = Math.Clamp(newZoom, MinZoom, MaxZoom);
        if (Math.Abs(clampedZoom - zoom) < 0.0001f && pictureBox.Width > 0 && pictureBox.Height > 0)
        {
            return;
        }

        Point oldScroll = imagePanel.AutoScrollPosition;
        int oldOffsetX = -oldScroll.X;
        int oldOffsetY = -oldScroll.Y;
        float oldCenterX = (oldOffsetX + imagePanel.ClientSize.Width / 2f) / Math.Max(zoom, MinZoom);
        float oldCenterY = (oldOffsetY + imagePanel.ClientSize.Height / 2f) / Math.Max(zoom, MinZoom);

        zoom = clampedZoom;

        int width = Math.Max(1, (int)Math.Round(currentBitmap.Width * zoom));
        int height = Math.Max(1, (int)Math.Round(currentBitmap.Height * zoom));
        pictureBox.Size = new Size(width, height);

        int newOffsetX = Math.Max(0, (int)Math.Round(oldCenterX * zoom - imagePanel.ClientSize.Width / 2f));
        int newOffsetY = Math.Max(0, (int)Math.Round(oldCenterY * zoom - imagePanel.ClientSize.Height / 2f));
        imagePanel.AutoScrollPosition = new Point(newOffsetX, newOffsetY);

        zoomLabel.Text = $"{zoom * 100f:0}%";
    }

    private void FitToWindow()
    {
        if (currentBitmap is null || imagePanel.ClientSize.Width <= 0 || imagePanel.ClientSize.Height <= 0)
        {
            return;
        }

        float scaleX = imagePanel.ClientSize.Width / (float)currentBitmap.Width;
        float scaleY = imagePanel.ClientSize.Height / (float)currentBitmap.Height;
        SetZoom(Math.Min(scaleX, scaleY));
    }
}
