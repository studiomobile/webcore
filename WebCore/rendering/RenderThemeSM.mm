/*
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#import <CoreText/CoreText.h>
#import "config.h"
#import "RenderThemeSM.h"

#import "BitmapImage.h"
#import "CSSStyleSelector.h"
#import "CSSValueKeywords.h"
#import "Document.h"
#import "Element.h"
#import "FrameView.h"
#import "GraphicsContextCG.h"
#import "HTMLInputElement.h"
#import "HTMLMediaElement.h"
#import "HTMLNames.h"
#import "Image.h"
#import "ImageBuffer.h"
#import "LocalizedStrings.h"
#import "MediaControlElements.h"
#import "PaintInfo.h"
#import "RenderMedia.h"
#import "RenderMediaControls.h"
#import "RenderSlider.h"
#import "RenderView.h"
#import "SharedBuffer.h"
#import "StringTruncator.h"
#import "TimeRanges.h"
#import "UserAgentStyleSheets.h"
#import <wtf/RetainPtr.h>
#import <wtf/StdLibExtras.h>
#import <math.h>

#import "RenderProgress.h"

#if ENABLE(METER_TAG)
#include "RenderMeter.h"
#include "HTMLMeterElement.h"
#endif


using namespace std;


namespace WebCore {
    
    PassRefPtr<RenderTheme> RenderTheme::themeForPage(Page*)
    {
        static RenderTheme* rt = RenderThemeSM::create().releaseRef();
        return rt;
    }
    
    
    PassRefPtr<RenderTheme> RenderThemeSM::create()
    {
        return adoptRef(new RenderThemeSM);
    }
    
    static FontWeight toFontWeight(CGFloat fontWeight)
    {
        ASSERT(fontWeight >= -1 && fontWeight <= 1);
        
        static FontWeight fontWeights[] = {
            FontWeight100,
            FontWeight100,
            FontWeight200,
            FontWeight300,
            FontWeight400,
            FontWeight500,
            FontWeight600,
            FontWeight600,
            FontWeight700,
            FontWeight800,
            FontWeight800,
            FontWeight900,
            FontWeight900,
            FontWeight900
        };
        //map font size in range of -1..+1 into fontWeights array
        int idx = ((fontWeight+1)*(sizeof(fontWeights) - 1))/2;
        return fontWeights[idx];
    }
    
    void RenderThemeSM::systemFont(int cssValueId, FontDescription& fontDescription) const
    {
        DEFINE_STATIC_LOCAL(FontDescription, systemFont, ());
        DEFINE_STATIC_LOCAL(FontDescription, smallSystemFont, ());
        DEFINE_STATIC_LOCAL(FontDescription, menuFont, ());
        DEFINE_STATIC_LOCAL(FontDescription, labelFont, ());
        DEFINE_STATIC_LOCAL(FontDescription, miniControlFont, ());
        DEFINE_STATIC_LOCAL(FontDescription, smallControlFont, ());
        DEFINE_STATIC_LOCAL(FontDescription, controlFont, ());
        
        FontDescription* cachedDesc;
        CTFontRef font = nil;
        switch (cssValueId) {
            case CSSValueSmallCaption:
                cachedDesc = &smallSystemFont;
                if (!smallSystemFont.isAbsoluteSize())
                    font = CTFontCreateUIFontForLanguage(kCTFontSmallSystemFontType, 0, NULL);
                break;
            case CSSValueMenu:
                cachedDesc = &menuFont;
                if (!menuFont.isAbsoluteSize())
                    font = CTFontCreateUIFontForLanguage(kCTFontMenuItemFontType, 0, NULL);
                break;
            case CSSValueStatusBar:
                cachedDesc = &labelFont;
                if (!labelFont.isAbsoluteSize())
                    font = CTFontCreateUIFontForLanguage(kCTFontLabelFontType, 0, NULL);
                break;
            case CSSValueWebkitMiniControl:
                cachedDesc = &miniControlFont;
                if (!miniControlFont.isAbsoluteSize())
                    font = CTFontCreateUIFontForLanguage(kCTFontMiniSystemFontType, 0, NULL);
                break;
            case CSSValueWebkitSmallControl:
                cachedDesc = &smallControlFont;
                if (!smallControlFont.isAbsoluteSize())
                    font = CTFontCreateUIFontForLanguage(kCTFontSmallSystemFontType, 0, NULL);
                break;
            case CSSValueWebkitControl:
                cachedDesc = &controlFont;
                if (!controlFont.isAbsoluteSize())
                    font = CTFontCreateUIFontForLanguage(kCTFontControlContentFontType, 0, NULL);
                break;
            default:
                cachedDesc = &systemFont;
                if (!systemFont.isAbsoluteSize())
                    font = CTFontCreateUIFontForLanguage(kCTFontSystemFontType, 0, NULL);
        }
        
        if (font) {
            cachedDesc->setIsAbsoluteSize(true);
            cachedDesc->setGenericFamily(FontDescription::NoFamily);
            
            CFStringRef fontFamilyName = CTFontCopyFamilyName(font);
            cachedDesc->firstFamily().setFamily((NSString*)fontFamilyName);
            CFRelease(fontFamilyName);
            
            cachedDesc->setSpecifiedSize(CTFontGetSize(font));
            
            CFDictionaryRef traits = CTFontCopyTraits(font);
            CFNumberRef cfweight = (CFNumberRef)CFDictionaryGetValue(traits, kCTFontWeightTrait);
            float weight;
            CFNumberGetValue(cfweight, kCFNumberFloatType, &weight);
            cachedDesc->setWeight(toFontWeight(weight));
            CFRelease(traits);
            
            CTFontSymbolicTraits symTraits = CTFontGetSymbolicTraits(font);
            cachedDesc->setItalic(symTraits & kCTFontItalicTrait);
            
            CFRelease(font);
        }
        fontDescription = *cachedDesc;
    }

    
    Color RenderThemeSM::platformActiveSelectionBackgroundColor() const
    {
        return Color(181, 213, 255);
    }
    
    Color RenderThemeSM::platformInactiveSelectionBackgroundColor() const
    {
        return Color(212, 212, 212);
    }

    
    Color RenderThemeSM::platformActiveSelectionForegroundColor() const
    {
        // relying on default behavior to use text color if return value of this one is invalid
        // e.g. InlineTextBox
        return Color(); 
    }
    
    Color RenderThemeSM::platformInactiveSelectionForegroundColor() const
    {
        // relying on default behavior to use text color if return value of this one is invalid
        // e.g. InlineTextBox
        return Color(); 
    }

} // namespace WebCore
