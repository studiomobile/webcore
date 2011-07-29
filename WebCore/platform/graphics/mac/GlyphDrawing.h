#ifndef smWebCore_GlyphFix_h
#define smWebCore_GlyphFix_h

#include <CoreGraphics/CoreGraphics.h>

size_t CMFontGetGlyphsForUnichars(CGFontRef cgFont, const UniChar buffer[], CGGlyph glyphs[], size_t numGlyphs);

#endif
