/*
 * Copyright (C) 2007, 2009 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

#import "config.h"
#import "DragImage.h"

#if ENABLE(DRAG_SUPPORT)
#import "CachedImage.h"
#import "Font.h"
#import "FontCache.h"
#import "FontDescription.h"
#import "FontSelector.h"
#import "GraphicsContext.h"
#import "Image.h"
#import "KURL.h"
#import "ResourceResponse.h"
#import "Settings.h"
#import "StringTruncator.h"
#import "TextRun.h"

namespace WebCore {

IntSize dragImageSize(DragImageRef image)
{
    return IntSize(0, 0);
}

void deleteDragImage(DragImageRef)
{
    // Since this is a RetainPtr, there's nothing additional we need to do to
    // delete it. It will be released when it falls out of scope.
}

DragImageRef scaleDragImage(DragImageRef image, FloatSize scale)
{
    return image;
}
    
DragImageRef dissolveDragImageToFraction(DragImageRef image, float delta)
{
    return image;
}
        
DragImageRef createDragImageFromImage(Image* image)
{
    return 0;
}
    
DragImageRef createDragImageIconForCachedImage(CachedImage* image)
{
    return 0;
}


const float DragLabelBorderX = 4;
//Keep border_y in synch with DragController::LinkDragBorderInset
const float DragLabelBorderY = 2;
const float DragLabelRadius = 5;
const float LabelBorderYOffset = 2;

const float MinDragLabelWidthBeforeClip = 120;
const float MaxDragLabelWidth = 320;

const float DragLinkLabelFontsize = 11;
const float DragLinkUrlFontSize = 10;

//static void drawAtPoint(NSString *string, NSPoint point, NSFont *font, NSColor *textColor)
//{
//}
//    
//static void drawDoubledAtPoint(NSString *string, NSPoint textPoint, NSColor *topColor, NSColor *bottomColor, NSFont *font)
//{
//}

DragImageRef createDragImageForLink(KURL& url, const String& title, Frame* frame)
{
    return 0;
}
   
} // namespace WebCore

#endif // ENABLE(DRAG_SUPPORT)
