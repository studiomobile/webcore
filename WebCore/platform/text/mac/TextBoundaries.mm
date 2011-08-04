/*
 * Copyright (C) 2004, 2006 Apple Computer, Inc.  All rights reserved.
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
#import "TextBoundaries.h"

using namespace WTF::Unicode;

namespace WebCore {

void findWordBoundary(const UChar* chars, int len, int position, int* start, int* end)
{
    NSString* string = [[NSString alloc] initWithCharactersNoCopy:const_cast<unichar*>(chars)
        length:len freeWhenDone:NO];
    
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(NULL, (CFStringRef)string, CFRangeMake(0, string.length), 
                                                     kCFStringTokenizerUnitWordBoundary, 
                                                     NULL);
    
    CFStringTokenizerTokenType tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, (position >= len) ? len - 1 : position);
    if (tokenType == kCFStringTokenizerTokenNone) {
        *start = position;
        *end = position;
    } else {
        CFRange wordRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        *start = wordRange.location;
        *end = wordRange.location + wordRange.length;
    }

    CFRelease(tokenizer);
    [string release];
}

int findNextWordFromIndex(const UChar* chars, int len, int position, bool forward)
{   
    NSString* string = [[NSString alloc] initWithCharactersNoCopy:const_cast<unichar*>(chars)
        length:len freeWhenDone:NO];
    // TODO - implement with CFStringTokenizerRef !!!
//    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(NULL, (CFStringRef)string, CFRangeMake(0, string.length), 
//                                                             kCFStringTokenizerUnitWord, 
//                                                             NULL);
//    CFStringTokenizerGoToTokenAtIndex(tokenizer, position);
//    CFStringTokenizerAdvanceToNextToken(tokenizer);
//    CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);

    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:string];
    int result = position + 1;//(int)[attr nextWordFromIndex:position forward:forward];
    [attr release];
    [string release];
    return result;
}

}
