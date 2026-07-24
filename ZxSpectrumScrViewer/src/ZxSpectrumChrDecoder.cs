using System.Drawing;

namespace ZxSpectrumScrViewer;

public static class ZxSpectrumChrDecoder
{
    private const int GlyphWidth = 8;
    private const int GlyphHeight = 8;
    private const int BytesPerGlyph = GlyphHeight;
    private const int Columns = 16;

    public static Bitmap Decode(ReadOnlySpan<byte> chrData)
    {
        if (chrData.Length == 0 || chrData.Length % BytesPerGlyph != 0)
        {
            throw new InvalidDataException($"Invalid CHR file size ({chrData.Length} bytes). Expected a non-zero multiple of {BytesPerGlyph} bytes.");
        }

        int glyphCount = chrData.Length / BytesPerGlyph;
        int rows = (glyphCount + Columns - 1) / Columns;
        Bitmap bitmap = new(Columns * GlyphWidth, rows * GlyphHeight);

        using Graphics graphics = Graphics.FromImage(bitmap);
        graphics.Clear(Color.White);

        for (int glyphIndex = 0; glyphIndex < glyphCount; glyphIndex++)
        {
            int glyphColumn = glyphIndex % Columns;
            int glyphRow = glyphIndex / Columns;
            int glyphStartX = glyphColumn * GlyphWidth;
            int glyphStartY = glyphRow * GlyphHeight;
            int glyphOffset = glyphIndex * BytesPerGlyph;

            for (int y = 0; y < GlyphHeight; y++)
            {
                byte rowBits = chrData[glyphOffset + y];
                for (int x = 0; x < GlyphWidth; x++)
                {
                    bool pixelOn = (rowBits & (1 << (7 - x))) != 0;
                    if (pixelOn)
                    {
                        bitmap.SetPixel(glyphStartX + x, glyphStartY + y, Color.Black);
                    }
                }
            }
        }

        return bitmap;
    }
}
