/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
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
#import "DragData.h"

#if ENABLE(DRAG_SUPPORT)
#import "Document.h"
#import "MIMETypeRegistry.h"
#import "Range.h"
#import "DocumentFragment.h"

namespace WebCore {

DragData::DragData(DragDataRef data, const IntPoint& clientPosition, const IntPoint& globalPosition, 
    DragOperation sourceOperationMask, DragApplicationFlags flags)
    : m_clientPosition(clientPosition)
    , m_globalPosition(globalPosition)
    , m_platformDragData(data)
    , m_draggingSourceOperationMask(sourceOperationMask)
    , m_applicationFlags(flags)
{
}

DragData::DragData(const String& dragStorageName, const IntPoint& clientPosition, const IntPoint& globalPosition,
    DragOperation sourceOperationMask, DragApplicationFlags flags)
    : m_clientPosition(clientPosition)
    , m_globalPosition(globalPosition)
    , m_platformDragData(0)
    , m_draggingSourceOperationMask(sourceOperationMask)
    , m_applicationFlags(flags)
{
}
    
bool DragData::canSmartReplace() const
{
    return false;
}

bool DragData::containsColor() const
{
    return false;
}

bool DragData::containsFiles() const
{
    return false;
}

void DragData::asFilenames(Vector<String>& result) const
{
}

bool DragData::containsPlainText() const
{
    return false;
}

String DragData::asPlainText(Frame *frame) const
{
    return String();
}

Color DragData::asColor() const
{
    return makeRGBA(0, 0, 0, 0);
}

bool DragData::containsCompatibleContent() const
{
    return false;
}
    
bool DragData::containsURL(Frame* frame, FilenameConversionPolicy filenamePolicy) const
{
    return false;
}
    
String DragData::asURL(Frame* frame, FilenameConversionPolicy filenamePolicy, String* title) const
{
    return String();
}

PassRefPtr<DocumentFragment> DragData::asFragment(Frame* frame, PassRefPtr<Range> range, bool allowPlainText, bool& chosePlainText) const
{
    
    return WTF::PassRefPtr<DocumentFragment>();
//    Pasteboard pasteboard(m_pasteboard.get());
//    
//    return pasteboard.documentFragment(frame, range, allowPlainText, chosePlainText);
}
    
} // namespace WebCore

#endif // ENABLE(DRAG_SUPPORT)
