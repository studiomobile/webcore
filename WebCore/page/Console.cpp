/*
 * Copyright (C) 2007 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "Console.h"

#include "Frame.h"
#include "FrameLoader.h"
#include "FrameTree.h"
#include "MemoryInfo.h"
#include "Page.h"
#include "PageGroup.h"
#include "PlatformString.h"
#include <stdio.h>
#include <wtf/UnusedParam.h>
#include <wtf/text/CString.h>

namespace WebCore {

Console::Console(Frame* frame)
    : m_frame(frame)
{
}

Console::~Console()
{
}

Frame* Console::frame() const
{
    return m_frame;
}

void Console::disconnectFrame()
{
    m_frame = 0;
}

static void printSourceURLAndLine(const String& sourceURL, unsigned lineNumber)
{
    if (!sourceURL.isEmpty()) {
        if (lineNumber > 0)
            printf("%s:%d: ", sourceURL.utf8().data(), lineNumber);
        else
            printf("%s: ", sourceURL.utf8().data());
    }
}

static void printMessageSourceAndLevelPrefix(MessageSource source, MessageLevel level)
{
    const char* sourceString;
    switch (source) {
    case HTMLMessageSource:
        sourceString = "HTML";
        break;
    case XMLMessageSource:
        sourceString = "XML";
        break;
    case JSMessageSource:
        sourceString = "JS";
        break;
    case CSSMessageSource:
        sourceString = "CSS";
        break;
    case OtherMessageSource:
        sourceString = "OTHER";
        break;
    default:
        ASSERT_NOT_REACHED();
        sourceString = "UNKNOWN";
        break;
    }

    const char* levelString;
    switch (level) {
    case TipMessageLevel:
        levelString = "TIP";
        break;
    case LogMessageLevel:
        levelString = "LOG";
        break;
    case WarningMessageLevel:
        levelString = "WARN";
        break;
    case ErrorMessageLevel:
        levelString = "ERROR";
        break;
    case DebugMessageLevel:
        levelString = "DEBUG";
        break;
    default:
        ASSERT_NOT_REACHED();
        levelString = "UNKNOWN";
        break;
    }

    printf("%s %s:", sourceString, levelString);
}

void Console::addMessage(MessageSource source, MessageType type, MessageLevel level, const String& message, unsigned lineNumber, const String& sourceURL)
{    
    if (!Console::shouldPrintExceptions())
        return;
    
    printSourceURLAndLine(sourceURL, lineNumber);
    printMessageSourceAndLevelPrefix(source, level);
    
    printf(" %s\n", message.utf8().data());
}

void Console::time(const String& title)
{
}

void Console::groupEnd()
{
}

bool Console::shouldCaptureFullStackTrace() const
{
    return false;
}

static bool printExceptions = false;

bool Console::shouldPrintExceptions()
{
    return printExceptions;
}

void Console::setShouldPrintExceptions(bool print)
{
    printExceptions = print;
}

Page* Console::page() const
{
    if (!m_frame)
        return 0;
    return m_frame->page();
}

} // namespace WebCore
