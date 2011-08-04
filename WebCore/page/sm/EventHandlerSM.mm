/*
 * Copyright (C) 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

#include "config.h"
#include "EventHandler.h"

#include "AXObjectCache.h"
#include "BlockExceptions.h"
#include "DragController.h"
#include "EventNames.h"
#include "FocusController.h"
#include "Frame.h"
#include "FrameLoader.h"
#include "FrameView.h"
#include "KeyboardEvent.h"
#include "MouseEventWithHitTestResults.h"
#include "NotImplemented.h"
#include "Page.h"
#include "PlatformKeyboardEvent.h"
#include "PlatformWheelEvent.h"
#include "RenderWidget.h"
#include "RuntimeApplicationChecks.h"
#include "Scrollbar.h"
#include "Settings.h"
//#include <objc/objc-runtime.h>
#include <wtf/StdLibExtras.h>
#include "ClipboardSM.h"

#if !(defined(OBJC_API_VERSION) && OBJC_API_VERSION > 0)
static inline IMP method_setImplementation(Method m, IMP i)
{
    IMP oi = m->method_imp;
    m->method_imp = i;
    return oi;
}
#endif

namespace WebCore {

#if ENABLE(DRAG_SUPPORT)
const double EventHandler::TextDragDelay = 0.15;
#endif

static RetainPtr<UIEvent>& currentUIEventSlot()
{
    DEFINE_STATIC_LOCAL(RetainPtr<UIEvent>, event, ());
    return event;
}

class CurrentEventScope {
     WTF_MAKE_NONCOPYABLE(CurrentEventScope);
public:
    CurrentEventScope(UIEvent *);
    ~CurrentEventScope();

private:
    RetainPtr<UIEvent> m_savedCurrentEvent;
#ifndef NDEBUG
    RetainPtr<UIEvent> m_event;
#endif
};

inline CurrentEventScope::CurrentEventScope(UIEvent *event)
    : m_savedCurrentEvent(currentUIEventSlot())
#ifndef NDEBUG
    , m_event(event)
#endif
{
    currentUIEventSlot() = event;
}

inline CurrentEventScope::~CurrentEventScope()
{
    ASSERT(currentUIEventSlot() == m_event);
    currentUIEventSlot() = m_savedCurrentEvent;
}

void EventHandler::focusDocumentView()
{
    Page* page = m_frame->page();
    if (!page)
        return;

    page->focusController()->setFocusedFrame(m_frame);
}

bool EventHandler::passWidgetMouseDownEventToWidget(const MouseEventWithHitTestResults& event)
{
    // Figure out which view to send the event to.
    RenderObject* target = targetNode(event) ? targetNode(event)->renderer() : 0;
    if (!target || !target->isWidget())
        return false;
    
    // Double-click events don't exist in Cocoa. Since passWidgetMouseDownEventToWidget will
    // just pass currentEvent down to the widget, we don't want to call it for events that
    // don't correspond to Cocoa events.  The mousedown/ups will have already been passed on as
    // part of the pressed/released handling.
    return passMouseDownEventToWidget(toRenderWidget(target)->widget());
}

bool EventHandler::passWidgetMouseDownEventToWidget(RenderWidget* renderWidget)
{
    return passMouseDownEventToWidget(renderWidget->widget());
}

static bool lastEventIsMouseUp()
{
    // Many AppKit widgets run their own event loops and consume events while the mouse is down.
    // When they finish, currentEvent is the mouseUp that they exited on. We need to update
    // the WebCore state with this mouseUp, which we never saw. This method lets us detect
    // that state. Handling this was critical when we used AppKit widgets for form elements.
    // It's not clear in what cases this is helpful now -- it's possible it can be removed. 

    return false;
}

bool EventHandler::passMouseDownEventToWidget(Widget* pWidget)
{
    return false;
}
    
#if ENABLE(DRAG_SUPPORT)
bool EventHandler::eventLoopHandleMouseDragged(const MouseEventWithHitTestResults&)
{
    return false;
}
#endif // ENABLE(DRAG_SUPPORT)
    
bool EventHandler::eventLoopHandleMouseUp(const MouseEventWithHitTestResults&)
{
    return true;
}
    
bool EventHandler::passSubframeEventToSubframe(MouseEventWithHitTestResults& event, Frame* subframe, HitTestResult* hoveredNode)
{
    return false;
}

bool EventHandler::passWheelEventToWidget(PlatformWheelEvent& wheelEvent, Widget* widget)
{
    return false;
}

static bool frameHasPlatformWidget(Frame* frame)
{
    if (FrameView* frameView = frame->view()) {
        if (frameView->platformWidget())
            return true;
    }

    return false;
}

bool EventHandler::passMousePressEventToSubframe(MouseEventWithHitTestResults& mev, Frame* subframe)
{
    // WebKit1 code path.
    if (frameHasPlatformWidget(m_frame))
        return passSubframeEventToSubframe(mev, subframe);

    // WebKit2 code path.
    subframe->eventHandler()->handleMousePressEvent(mev.event());
    return true;
}

bool EventHandler::passMouseMoveEventToSubframe(MouseEventWithHitTestResults& mev, Frame* subframe, HitTestResult* hoveredNode)
{
    return true;
}

bool EventHandler::passMouseReleaseEventToSubframe(MouseEventWithHitTestResults& mev, Frame* subframe)
{
    // WebKit1 code path.
    if (frameHasPlatformWidget(m_frame))
        return passSubframeEventToSubframe(mev, subframe);

    // WebKit2 code path.
    subframe->eventHandler()->handleMouseReleaseEvent(mev.event());
    return true;
}

PlatformMouseEvent EventHandler::currentPlatformMouseEvent() const
{
    return PlatformMouseEvent();
}

bool EventHandler::eventActivatedView(const PlatformMouseEvent& event) const
{
    return m_activationEventNumber == event.eventNumber();
}

#if ENABLE(DRAG_SUPPORT)

PassRefPtr<Clipboard> EventHandler::createDraggingClipboard() const
{
//    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
//    // Must be done before ondragstart adds types and data to the pboard,
//    // also done for security, as it erases data from the last drag
//    [pasteboard declareTypes:[NSArray array] owner:nil];
    return ClipboardSM::create(Clipboard::DragAndDrop, ClipboardWritable, m_frame);
}

#endif

bool EventHandler::tabsToAllFormControls(KeyboardEvent* event) const
{
    return true;
}

bool EventHandler::needsKeyboardEventDisambiguationQuirks() const
{
    Document* document = m_frame->document();

    // RSS view needs arrow key keypress events.
    if (applicationIsSafari() && (document->url().protocolIs("feed") || document->url().protocolIs("feeds")))
        return true;
    Settings* settings = m_frame->settings();
    if (!settings)
        return false;

#if ENABLE(DASHBOARD_SUPPORT)
    if (settings->usesDashboardBackwardCompatibilityMode())
        return true;
#endif
        
    if (settings->needsKeyboardEventDisambiguationQuirks())
        return true;

    return false;
}

unsigned EventHandler::accessKeyModifiers()
{
    // Control+Option key combinations are usually unused on Mac OS X, but not when VoiceOver is enabled.
    // So, we use Control in this case, even though it conflicts with Emacs-style key bindings.
    // See <https://bugs.webkit.org/show_bug.cgi?id=21107> for more detail.
    if (AXObjectCache::accessibilityEnhancedUserInterfaceEnabled())
        return PlatformKeyboardEvent::CtrlKey;

    return PlatformKeyboardEvent::CtrlKey | PlatformKeyboardEvent::AltKey;
}

}
