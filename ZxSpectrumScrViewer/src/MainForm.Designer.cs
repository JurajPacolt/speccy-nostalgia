namespace ZxSpectrumScrViewer;

partial class MainForm
{
    /// <summary>
    ///  Required designer variable.
    /// </summary>
    private System.ComponentModel.IContainer components = null;

    /// <summary>
    ///  Clean up any resources being used.
    /// </summary>
    /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
    protected override void Dispose(bool disposing)
    {
        if (disposing && (components != null))
        {
            components.Dispose();
        }
        base.Dispose(disposing);
    }

    #region Windows Form Designer generated code

    /// <summary>
    ///  Required method for Designer support - do not modify
    ///  the contents of this method with the code editor.
    /// </summary>
    private void InitializeComponent()
    {
        this.components = new System.ComponentModel.Container();
        this.topPanel = new FlowLayoutPanel();
        this.openButton = new Button();
        this.zoomOutButton = new Button();
        this.zoomInButton = new Button();
        this.actualSizeButton = new Button();
        this.fitButton = new Button();
        this.invertButton = new Button();
        this.attributesButton = new Button();
        this.gridButton = new Button();
        this.zoomLabel = new Label();
        this.imagePanel = new Panel();
        this.pictureBox = new PictureBox();
        this.topPanel.SuspendLayout();
        this.imagePanel.SuspendLayout();
        ((System.ComponentModel.ISupportInitialize)this.pictureBox).BeginInit();
        this.SuspendLayout();
        // 
        // topPanel
        // 
        this.topPanel.AutoSize = true;
        this.topPanel.Controls.Add(this.openButton);
        this.topPanel.Controls.Add(this.zoomOutButton);
        this.topPanel.Controls.Add(this.zoomInButton);
        this.topPanel.Controls.Add(this.actualSizeButton);
        this.topPanel.Controls.Add(this.fitButton);
        this.topPanel.Controls.Add(this.invertButton);
        this.topPanel.Controls.Add(this.attributesButton);
        this.topPanel.Controls.Add(this.gridButton);
        this.topPanel.Controls.Add(this.zoomLabel);
        this.topPanel.Dock = DockStyle.Top;
        this.topPanel.Location = new Point(0, 0);
        this.topPanel.Name = "topPanel";
        this.topPanel.Padding = new Padding(8);
        this.topPanel.Size = new Size(1000, 52);
        this.topPanel.TabIndex = 0;
        this.topPanel.WrapContents = false;
        // 
        // openButton
        // 
        this.openButton.AutoSize = true;
        this.openButton.Location = new Point(11, 11);
        this.openButton.Name = "openButton";
        this.openButton.Size = new Size(89, 33);
        this.openButton.TabIndex = 0;
        this.openButton.Text = "Open file";
        this.openButton.UseVisualStyleBackColor = true;
        this.openButton.Click += this.openButton_Click;
        // 
        // zoomOutButton
        // 
        this.zoomOutButton.AutoSize = true;
        this.zoomOutButton.Location = new Point(106, 11);
        this.zoomOutButton.Name = "zoomOutButton";
        this.zoomOutButton.Size = new Size(33, 33);
        this.zoomOutButton.TabIndex = 1;
        this.zoomOutButton.Text = "-";
        this.zoomOutButton.UseVisualStyleBackColor = true;
        this.zoomOutButton.Click += this.zoomOutButton_Click;
        // 
        // zoomInButton
        // 
        this.zoomInButton.AutoSize = true;
        this.zoomInButton.Location = new Point(145, 11);
        this.zoomInButton.Name = "zoomInButton";
        this.zoomInButton.Size = new Size(33, 33);
        this.zoomInButton.TabIndex = 2;
        this.zoomInButton.Text = "+";
        this.zoomInButton.UseVisualStyleBackColor = true;
        this.zoomInButton.Click += this.zoomInButton_Click;
        // 
        // actualSizeButton
        // 
        this.actualSizeButton.AutoSize = true;
        this.actualSizeButton.Location = new Point(184, 11);
        this.actualSizeButton.Name = "actualSizeButton";
        this.actualSizeButton.Size = new Size(52, 33);
        this.actualSizeButton.TabIndex = 3;
        this.actualSizeButton.Text = "100%";
        this.actualSizeButton.UseVisualStyleBackColor = true;
        this.actualSizeButton.Click += this.actualSizeButton_Click;
        // 
        // fitButton
        // 
        this.fitButton.AutoSize = true;
        this.fitButton.Location = new Point(242, 11);
        this.fitButton.Name = "fitButton";
        this.fitButton.Size = new Size(39, 33);
        this.fitButton.TabIndex = 4;
        this.fitButton.Text = "Fit";
        this.fitButton.UseVisualStyleBackColor = true;
        this.fitButton.Click += this.fitButton_Click;
        // 
        // invertButton
        // 
        this.invertButton.AutoSize = true;
        this.invertButton.Location = new Point(287, 11);
        this.invertButton.Name = "invertButton";
        this.invertButton.Size = new Size(53, 33);
        this.invertButton.TabIndex = 5;
        this.invertButton.Text = "Invert";
        this.invertButton.UseVisualStyleBackColor = true;
        this.invertButton.Click += this.invertButton_Click;
        // 
        // attributesButton
        // 
        this.attributesButton.AutoSize = true;
        this.attributesButton.Location = new Point(346, 11);
        this.attributesButton.Name = "attributesButton";
        this.attributesButton.Size = new Size(81, 33);
        this.attributesButton.TabIndex = 6;
        this.attributesButton.Text = "Attr ON";
        this.attributesButton.UseVisualStyleBackColor = true;
        this.attributesButton.Click += this.attributesButton_Click;
        // 
        // gridButton
        // 
        this.gridButton.AutoSize = true;
        this.gridButton.Location = new Point(433, 11);
        this.gridButton.Name = "gridButton";
        this.gridButton.Size = new Size(65, 33);
        this.gridButton.TabIndex = 7;
        this.gridButton.Text = "Grid";
        this.gridButton.UseVisualStyleBackColor = true;
        this.gridButton.Click += this.gridButton_Click;
        // 
        // zoomLabel
        // 
        this.zoomLabel.AutoSize = true;
        this.zoomLabel.Location = new Point(504, 18);
        this.zoomLabel.Name = "zoomLabel";
        this.zoomLabel.Size = new Size(35, 15);
        this.zoomLabel.TabIndex = 8;
        this.zoomLabel.Text = "100%";
        this.zoomLabel.TextAlign = ContentAlignment.MiddleLeft;
        // 
        // imagePanel
        // 
        this.imagePanel.AutoScroll = true;
        this.imagePanel.BackColor = Color.FromArgb(30, 30, 30);
        this.imagePanel.Controls.Add(this.pictureBox);
        this.imagePanel.Dock = DockStyle.Fill;
        this.imagePanel.Location = new Point(0, 52);
        this.imagePanel.Name = "imagePanel";
        this.imagePanel.Size = new Size(1000, 648);
        this.imagePanel.TabIndex = 1;
        this.imagePanel.MouseEnter += this.imagePanel_MouseEnter;
        this.imagePanel.MouseWheel += this.imagePanel_MouseWheel;
        // 
        // pictureBox
        // 
        this.pictureBox.Location = new Point(0, 0);
        this.pictureBox.Name = "pictureBox";
        this.pictureBox.Size = new Size(256, 192);
        this.pictureBox.SizeMode = PictureBoxSizeMode.StretchImage;
        this.pictureBox.TabIndex = 0;
        this.pictureBox.TabStop = false;
        this.pictureBox.MouseEnter += this.imagePanel_MouseEnter;
        this.pictureBox.MouseWheel += this.imagePanel_MouseWheel;
        // 
        // MainForm
        // 
        this.AutoScaleDimensions = new SizeF(7F, 15F);
        this.AutoScaleMode = AutoScaleMode.Font;
        this.ClientSize = new Size(1000, 700);
        this.Controls.Add(this.imagePanel);
        this.Controls.Add(this.topPanel);
        this.MinimumSize = new Size(620, 420);
        this.Name = "MainForm";
        this.Text = "ZX Spectrum SCR/CHR Viewer";
        this.topPanel.ResumeLayout(false);
        this.topPanel.PerformLayout();
        this.imagePanel.ResumeLayout(false);
        ((System.ComponentModel.ISupportInitialize)this.pictureBox).EndInit();
        this.ResumeLayout(false);
        this.PerformLayout();
    }

    #endregion

    private FlowLayoutPanel topPanel;
    private Button openButton;
    private Button zoomOutButton;
    private Button zoomInButton;
    private Button actualSizeButton;
    private Button fitButton;
    private Button invertButton;
    private Button attributesButton;
    private Button gridButton;
    private Label zoomLabel;
    private Panel imagePanel;
    private PictureBox pictureBox;
}
