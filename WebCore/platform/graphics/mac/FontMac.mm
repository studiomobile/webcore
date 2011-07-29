/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2006, 2007, 2008, 2009, 2010 Apple Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#import "config.h"
#import "Font.h"

#import "GlyphBuffer.h"
#import "GraphicsContext.h"
#import "Logging.h"
#import "SimpleFontData.h"
#import <CoreText/CoreText.h>

#import "BitmapImage.h"
#import "SharedBuffer.h"
#import <wtf/StdLibExtras.h>
#import <wtf/Threading.h>

#define SYNTHETIC_OBLIQUE_ANGLE 14

#ifdef __LP64__
#define URefCon void*
#else
#define URefCon UInt32
#endif

using namespace std;

namespace WebCore {

bool Font::canReturnFallbackFontsForComplexText()
{
    return true;
}

    
    bool Font::canExpandAroundIdeographsInComplexText()
    {
        return true;
    }
    

static void showGlyphsWithAdvances(const FontPlatformData& font, CGContextRef context, const CGGlyph* glyphs, const CGSize* advances, size_t count)
{
    if (!font.isColorBitmapFont())
        CGContextShowGlyphsWithAdvances(context, glyphs, advances, count);
    else {
        if (!count)
            return;

        Vector<CGPoint, 256> positions(count);
        CGAffineTransform matrix = CGAffineTransformInvert(CGContextGetTextMatrix(context));
        positions[0] = CGPointZero;
        for (size_t i = 1; i < count; ++i) {
            CGSize advance = CGSizeApplyAffineTransform(advances[i - 1], matrix);
            positions[i].x = positions[i - 1].x + advance.width;
            positions[i].y = positions[i - 1].y + advance.height;
        }
        CTFontDrawGlyphs(font.ctFont(), glyphs, positions.data(), count, context);
    }
}

    
//    void Font::drawGlyphs(GraphicsContext*, const SimpleFontData*, const GlyphBuffer&, int from, int to, const FloatPoint&) const {}
//    void Font::drawGlyphBuffer(GraphicsContext*, const TextRun&, const GlyphBuffer&, const FloatPoint&) const {}

void Font::drawGlyphs(GraphicsContext* context, const SimpleFontData* font, const GlyphBuffer& glyphBuffer, int from, int numGlyphs, const FloatPoint& anchorPoint) const
{
    CGContextRef cgContext = context->platformContext();

    bool newShouldUseFontSmoothing = shouldUseSmoothing();

    switch(fontDescription().fontSmoothing()) {
    case Antialiased: {
        context->setShouldAntialias(true);
        newShouldUseFontSmoothing = false;
        break;
    }
    case SubpixelAntialiased: {
        context->setShouldAntialias(true);
        newShouldUseFontSmoothing = true;
        break;
    }
    case NoSmoothing: {
        context->setShouldAntialias(false);
        newShouldUseFontSmoothing = false;
        break;
    }
    case AutoSmoothing: {
        // For the AutoSmooth case, don't do anything! Keep the default settings.
        break; 
    }
    default: 
        ASSERT_NOT_REACHED();
    }


    const FontPlatformData& platformData = font->platformData();

    CGContextSetFont(cgContext, platformData.cgFont());
    FloatPoint point = anchorPoint;
    float fontSize = platformData.size();

    CGAffineTransform matrix = platformData.isColorBitmapFont() ? CGAffineTransformIdentity : CGAffineTransformMakeScale(fontSize, fontSize);
    matrix.b = -matrix.b;
    matrix.d = -matrix.d;

    if (platformData.m_syntheticOblique)
        matrix = CGAffineTransformConcat(matrix, CGAffineTransformMake(1, 0, -tanf(SYNTHETIC_OBLIQUE_ANGLE * acosf(0) / 90), 1, 0, 0)); 
    CGContextSetTextMatrix(cgContext, matrix);

    CGContextSetFontSize(cgContext, 1.0f);


    FloatSize shadowSizeFloat;
    float shadowBlurFloat;
    Color shadowColor;
    ColorSpace fillColorSpace = context->fillColorSpace();
    ColorSpace shadowColorSpace;
    context->getShadow(shadowSizeFloat, shadowBlurFloat, shadowColor, shadowColorSpace);

    IntSize shadowSize(shadowSizeFloat.width(), shadowSizeFloat.height());
    int shadowBlur = shadowBlurFloat;

    bool hasSimpleShadow = context->textDrawingMode() == /* TODO - ???? cTextFill  && */ shadowColor.isValid() && !shadowBlur && !platformData.isColorBitmapFont();
    if (hasSimpleShadow) {
        // Paint simple shadows ourselves instead of relying on CG shadows, to avoid losing subpixel antialiasing.
        context->clearShadow();
        Color fillColor = context->fillColor();
        Color shadowFillColor(shadowColor.red(), shadowColor.green(), shadowColor.blue(), shadowColor.alpha() * fillColor.alpha() / 255);
        context->setFillColor(shadowFillColor, fillColorSpace);
        CGContextSetTextPosition(cgContext, point.x() + shadowSize.width(), point.y() + shadowSize.height());
        showGlyphsWithAdvances(platformData, cgContext, glyphBuffer.glyphs(from), glyphBuffer.advances(from), numGlyphs);
        if (font->syntheticBoldOffset()) {
            CGContextSetTextPosition(cgContext, point.x() + shadowSize.width() + font->syntheticBoldOffset(), point.y() + shadowSize.height());
            showGlyphsWithAdvances(platformData, cgContext, glyphBuffer.glyphs(from), glyphBuffer.advances(from), numGlyphs);
        }
        context->setFillColor(fillColor, fillColorSpace);
    }

    CGContextSetTextPosition(cgContext, point.x(), point.y());
    showGlyphsWithAdvances(platformData, cgContext, glyphBuffer.glyphs(from), glyphBuffer.advances(from), numGlyphs);
    if (font->syntheticBoldOffset()) {
        CGContextSetTextPosition(cgContext, point.x() + font->syntheticBoldOffset(), point.y());
        showGlyphsWithAdvances(platformData, cgContext, glyphBuffer.glyphs(from), glyphBuffer.advances(from), numGlyphs);
    }

    if (hasSimpleShadow)
        context->setShadow(shadowSize, shadowBlur, shadowColor, fillColorSpace);

}

}
