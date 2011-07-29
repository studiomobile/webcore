/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
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
#include "MIMETypeRegistry.h"

#include <wtf/Assertions.h>
#include <wtf/MainThread.h>

#import <MobileCoreServices/MobileCoreServices.h>

namespace WebCore 
{

String MIMETypeRegistry::getMIMETypeForExtension(const String &ext)
{
    NSString *nsExt = ext;
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)nsExt, NULL);
    
    CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
    
    String str = String(mime);
    
    CFRelease(uti);
    CFRelease(mime);
    
    return str;
}

Vector<String> MIMETypeRegistry::getExtensionsForMIMEType(const String& type)
{
    NSMutableArray *stringsArray = [NSMutableArray array];
    
    NSArray *utis = (NSArray*)UTTypeCreateAllIdentifiersForTag(kUTTagClassMIMEType, (CFStringRef)((NSString*)type), NULL);
    for (NSString *uti in utis) {
        [stringsArray addObject:(NSString*)UTTypeCopyPreferredTagWithClass((CFStringRef)uti, kUTTagClassFilenameExtension)];
    }
    [utis release];
    
    Vector<String> stringsVector = Vector<String>();
    unsigned count = [stringsArray count];
    if (count > 0) {
        NSEnumerator* enumerator = [stringsArray objectEnumerator];
        NSString* string;
        while ((string = [enumerator nextObject]) != nil)
            stringsVector.append(string);
    }
    return stringsVector;
}

String MIMETypeRegistry::getPreferredExtensionForMIMEType(const String& type)
{
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)((NSString *)type), NULL);
    
    CFStringRef ext = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
    
    String str = String(ext);
    
    CFRelease(uti);
    CFRelease(ext);
    
    return str;
}

bool MIMETypeRegistry::isApplicationPluginMIMEType(const String&)
{
    return false;
}

}
