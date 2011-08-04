/*
 * Copyright (C) 2004, 2005, 2006, 2008, 2010 Apple Inc. All rights reserved.
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
#import "ClipboardSM.h"

//#import "DOMElementInternal.h"
#import "DragClient.h"
#import "DragController.h"
#import "DragData.h"
#import "Editor.h"
#import "FileList.h"
#import "Frame.h"
#import "Image.h"
#import "Page.h"
#import "Pasteboard.h"
#import "RenderImage.h"
#import "ScriptExecutionContext.h"
#import "SecurityOrigin.h"
//#import "WebCoreSystemInterface.h"


namespace WebCore {

PassRefPtr<Clipboard> Clipboard::create(ClipboardAccessPolicy policy, DragData* dragData, Frame* frame)
{
    return ClipboardSM::create(DragAndDrop, policy, frame);
}

ClipboardSM::ClipboardSM(ClipboardType clipboardType, ClipboardAccessPolicy policy, Frame *frame)
    : Clipboard(policy, clipboardType)
    , m_frame(frame)
{
    m_changeCount = 0;
}

ClipboardSM::~ClipboardSM()
{
}

bool ClipboardSM::hasData()
{
    return false;
}
    
void ClipboardSM::clearData(const String& type)
{
}

void ClipboardSM::clearAllData()
{
}

String ClipboardSM::getData(const String& type, bool& success) const
{
    return String();
}

bool ClipboardSM::setData(const String &type, const String &data)
{
    return false;
}

HashSet<String> ClipboardSM::types() const
{
    HashSet<String> result;
    return result;
}

// FIXME: We could cache the computed fileList if necessary
// Currently each access gets a new copy, setData() modifications to the
// clipboard are not reflected in any FileList objects the page has accessed and stored
PassRefPtr<FileList> ClipboardSM::files() const
{
    RefPtr<FileList> fileList = FileList::create();
    return fileList.release(); // We will always return a FileList, sometimes empty
}

// The rest of these getters don't really have any impact on security, so for now make no checks

void ClipboardSM::setDragImage(CachedImage* img, const IntPoint &loc)
{
    setDragImage(img, 0, loc);
}

void ClipboardSM::setDragImageElement(Node *node, const IntPoint &loc)
{
    setDragImage(0, node, loc);
}

void ClipboardSM::setDragImage(CachedImage* image, Node *node, const IntPoint &loc)
{
}
    
void ClipboardSM::writeRange(Range* range, Frame* frame)
{
    ASSERT(range);
    ASSERT(frame);
//    Pasteboard::writeSelection(m_pasteboard.get(), 0, range, frame->editor()->smartInsertDeleteEnabled() && frame->selection()->granularity() == WordGranularity, frame);
}

void ClipboardSM::writePlainText(const String& text)
{
//    Pasteboard::writePlainText(m_pasteboard.get(), text);
}

void ClipboardSM::writeURL(const KURL& url, const String& title, Frame* frame)
{   
    ASSERT(frame);
//    ASSERT(m_pasteboard);
//    Pasteboard::writeURL(m_pasteboard.get(), nil, url, title, frame);
}
    
#if ENABLE(DRAG_SUPPORT)
void ClipboardSM::declareAndWriteDragImage(Element* element, const KURL& url, const String& title, Frame* frame)
{
    ASSERT(frame);
//    if (Page* page = frame->page())
//        page->dragController()->client()->declareAndWriteDragImage(m_pasteboard.get(), kit(element), url, title, frame);
}
#endif // ENABLE(DRAG_SUPPORT)
    
DragImageRef ClipboardSM::createDragImage(IntPoint& loc) const
{
    CGPoint cgloc = {loc.x(), loc.y()};
    DragImageRef result = dragUIImage(cgloc);
    loc = (IntPoint)cgloc;
    return result;
}
    
UIImage *ClipboardSM::dragUIImage(CGPoint& loc) const
{
    UIImage *result = nil;
//    if (m_dragImageElement) {
//        if (m_frame) {
//            NSRect imageRect;
//            NSRect elementRect;
//            result = m_frame->snapshotDragImage(m_dragImageElement.get(), &imageRect, &elementRect);
//            // Client specifies point relative to element, not the whole image, which may include child
//            // layers spread out all over the place.
//            loc.x = elementRect.origin.x - imageRect.origin.x + m_dragLoc.x();
//            loc.y = elementRect.origin.y - imageRect.origin.y + m_dragLoc.y();
//            loc.y = imageRect.size.height - loc.y;
//        }
//    } else if (m_dragImage) {
//        result = m_dragImage->image()->getNSImage();
//        
//        loc = m_dragLoc;
//        loc.y = [result size].height - loc.y;
//    }
    return result;
}

}
