using System.Drawing;

namespace ZxSpectrumScrViewer;

public static class ZxSpectrumScrDecoder
{
    private const int Width = 256;
    private const int Height = 192;
    private const int PixelBytes = 6144;
    private const int AttributeBytes = 768;
    private const int FileSize = PixelBytes + AttributeBytes;

    public static Bitmap Decode(ReadOnlySpan<byte> scrData, bool useAttributes = true)
    {
        int minSize = useAttributes ? FileSize : PixelBytes;
        if (scrData.Length < minSize)
        {
            throw new InvalidDataException($"Invalid SCR file size ({scrData.Length} bytes). Expected at least {minSize} bytes.");
        }

        ReadOnlySpan<byte> pixelData = scrData.Slice(0, PixelBytes);
        ReadOnlySpan<byte> attributeData = useAttributes
            ? scrData.Slice(PixelBytes, AttributeBytes)
            : ReadOnlySpan<byte>.Empty;

        Bitmap bitmap = new(Width, Height);

        for (int y = 0; y < Height; y++)
        {
            int rowBase = ((y & 0b1100_0000) << 5) | ((y & 0b0000_0111) << 8) | ((y & 0b0011_1000) << 2);
            int attributeRowBase = (y >> 3) * 32;

            for (int xByte = 0; xByte < 32; xByte++)
            {
                byte pixelByte = pixelData[rowBase + xByte];
                Color inkColor;
                Color paperColor;

                if (useAttributes)
                {
                    byte attribute = attributeData[attributeRowBase + xByte];
                    int ink = attribute & 0b0000_0111;
                    int paper = (attribute >> 3) & 0b0000_0111;
                    bool bright = (attribute & 0b0100_0000) != 0;
                    bool flash = (attribute & 0b1000_0000) != 0;
                    if (flash)
                    {
                        (ink, paper) = (paper, ink);
                    }

                    inkColor = GetColor(ink, bright);
                    paperColor = GetColor(paper, bright);
                }
                else
                {
                    inkColor = Color.White;
                    paperColor = Color.Black;
                }

                int xStart = xByte * 8;

                for (int bit = 0; bit < 8; bit++)
                {
                    bool pixelOn = (pixelByte & (1 << (7 - bit))) != 0;
                    bitmap.SetPixel(xStart + bit, y, pixelOn ? inkColor : paperColor);
                }
            }
        }

        return bitmap;
    }

    private static Color GetColor(int colorIndex, bool bright)
    {
        return colorIndex switch
        {
            0 => Color.Black,
            1 => bright ? Color.FromArgb(0, 0, 255) : Color.FromArgb(0, 0, 205),
            2 => bright ? Color.FromArgb(255, 0, 0) : Color.FromArgb(205, 0, 0),
            3 => bright ? Color.FromArgb(255, 0, 255) : Color.FromArgb(205, 0, 205),
            4 => bright ? Color.FromArgb(0, 255, 0) : Color.FromArgb(0, 205, 0),
            5 => bright ? Color.FromArgb(0, 255, 255) : Color.FromArgb(0, 205, 205),
            6 => bright ? Color.FromArgb(255, 255, 0) : Color.FromArgb(205, 205, 0),
            7 => bright ? Color.FromArgb(255, 255, 255) : Color.FromArgb(205, 205, 205),
            _ => Color.Black
        };
    }
}
