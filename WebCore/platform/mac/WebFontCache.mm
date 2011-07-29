/*
 * Copyright (C) 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
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

#import "config.h"
#import "WebFontCache.h"

#import "FontTraitsMask.h"
#import <math.h>
#import <wtf/UnusedParam.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

using namespace WebCore;

#define SYNTHESIZED_FONT_TRAITS (kCTFontBoldTrait | kCTFontItalicTrait)

#define IMPORTANT_FONT_TRAITS (0 \
    | kCTFontCondensedTrait \
    | kCTFontExpandedTrait \
    | kCTFontItalicTrait \
)

static BOOL acceptableChoice(CTFontSymbolicTraits desiredTraits, CTFontSymbolicTraits candidateTraits)
{
    desiredTraits &= ~SYNTHESIZED_FONT_TRAITS;
    return (candidateTraits & desiredTraits) == desiredTraits;
}

static BOOL betterChoice(CTFontSymbolicTraits desiredTraits, int desiredWeight,
    CTFontSymbolicTraits chosenTraits, int chosenWeight,
    CTFontSymbolicTraits candidateTraits, int candidateWeight)
{
    if (!acceptableChoice(desiredTraits, candidateTraits))
        return NO;

    // A list of the traits we care about.
    // The top item in the list is the worst trait to mismatch; if a font has this
    // and we didn't ask for it, we'd prefer any other font in the family.
    const CTFontSymbolicTraits masks[] = {
        kCTFontItalicTrait,
        kCTFontCondensedTrait,
        kCTFontExpandedTrait,
        0
    };

    int i = 0;
    CTFontSymbolicTraits mask;
    while ((mask = masks[i++])) {
        BOOL desired = (desiredTraits & mask) != 0;
        BOOL chosenHasUnwantedTrait = desired != ((chosenTraits & mask) != 0);
        BOOL candidateHasUnwantedTrait = desired != ((candidateTraits & mask) != 0);
        if (!candidateHasUnwantedTrait && chosenHasUnwantedTrait)
            return YES;
        if (!chosenHasUnwantedTrait && candidateHasUnwantedTrait)
            return NO;
    }

    int chosenWeightDeltaMagnitude = abs(chosenWeight - desiredWeight);
    int candidateWeightDeltaMagnitude = abs(candidateWeight - desiredWeight);

    // If both are the same distance from the desired weight, prefer the candidate if it is further from medium.
    if (chosenWeightDeltaMagnitude == candidateWeightDeltaMagnitude)
        return abs(candidateWeight - 6) > abs(chosenWeight - 6);

    // Otherwise, prefer the one closer to the desired weight.
    return candidateWeightDeltaMagnitude < chosenWeightDeltaMagnitude;
}


static inline FontTraitsMask toTraitsMask(CTFontSymbolicTraits appKitTraits, NSInteger appKitWeight)
{
    return static_cast<FontTraitsMask>(((appKitTraits & kCTFontItalicTrait) ? FontStyleItalicMask : FontStyleNormalMask)
        | FontVariantNormalMask
        | (appKitWeight <= 1 ? FontWeight100Mask :
              appKitWeight == 2 ? FontWeight200Mask :
              appKitWeight <= 4 ? FontWeight300Mask :
              appKitWeight == 5 ? FontWeight400Mask :
              appKitWeight == 6 ? FontWeight500Mask :
              appKitWeight <= 8 ? FontWeight600Mask :
              appKitWeight == 9 ? FontWeight700Mask :
              appKitWeight <= 11 ? FontWeight800Mask :
                                   FontWeight900Mask));
}


static NSInteger fontWeightFromTraits(CFDictionaryRef traits) {
    CGFloat fontWeightNormalized;
    CFNumberRef fontWeightNormalizedNum = (CFNumberRef)CFDictionaryGetValue(traits, kCTFontWeightTrait);
    CFNumberGetValue(fontWeightNormalizedNum, kCFNumberFloatType, &fontWeightNormalized);
    NSInteger fontWeight = round(5*(fontWeightNormalized + 1));
    return fontWeight;
}

static CFDictionaryRef copyFontTraits(NSString *fontFullName) {
    CTFontRef font = CTFontCreateWithName((CFStringRef)fontFullName, 12, NULL);
    CFDictionaryRef result = CTFontCopyTraits(font);
    CFRelease(font);
    return result;
}

static CFArrayRef availableFontsArray() {
    CFStringRef keys[] = {kCTFontCollectionRemoveDuplicatesOption};
    int val = 1;
    CFNumberRef cfval = CFNumberCreate(NULL, kCFNumberIntType, &val);
    CFNumberRef values[] = {cfval};
    CFDictionaryRef options = CFDictionaryCreate(NULL, 
                                                 (const void**)&keys, (const void**)&values, 
                                                 1l, 
                                                 &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFRelease(cfval);
    CTFontCollectionRef fonts = CTFontCollectionCreateFromAvailableFonts(options);
    CFRelease(options);
    CFArrayRef fontDescriptors = CTFontCollectionCreateMatchingFontDescriptors(fonts);
    CFRelease(fonts);
    return fontDescriptors;
}

static CTFontSymbolicTraits fontSymbolicTraintsFromTraits(CFDictionaryRef traits) {
    CFNumberRef sTraitsNum = (CFNumberRef)CFDictionaryGetValue(traits, kCTFontSymbolicTrait);
    CTFontSymbolicTraits symbolicFontTraits;
    CFNumberGetValue(sTraitsNum, kCFNumberSInt32Type, &symbolicFontTraits);
    return symbolicFontTraits;
}

static CTFontRef copyFontToHaveTrait(CTFontDescriptorRef fontDesc, CGFloat size, 
                                        CTFontSymbolicTraits desiredTraitsForNameMatch) {
    CTFontRef origFont = CTFontCreateWithFontDescriptor(fontDesc, size, NULL);
    CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(origFont, size, NULL, 
                                                           desiredTraitsForNameMatch,
                                                           desiredTraitsForNameMatch);
    if (newFont) {
        CFRelease(origFont);
        return newFont;
    } else {
        return origFont;
    }
}

@implementation WebFontCache

    // TODO - CSSFontSelector uses this 
+ (void)getTraits:(Vector<unsigned>&)traitsMasks inFamily:(NSString *)desiredFamily
{
    NSArray *familyNames = [UIFont familyNames];
    NSEnumerator *e = [familyNames objectEnumerator];
    NSString *availableFamily;
    while ((availableFamily = [e nextObject])) {
        if ([desiredFamily caseInsensitiveCompare:availableFamily] == NSOrderedSame)
            break;
    }
    
    if (!availableFamily) {
            // Match by PostScript name.
        CFArrayRef availableFonts = availableFontsArray();
        NSUInteger count = CFArrayGetCount(availableFonts);
        CFStringRef cfDesiredFamily = (CFStringRef)desiredFamily;
        BOOL found = NO;
        for (int i = 0; i < count; ++i) {
            CTFontDescriptorRef font = (CTFontDescriptorRef)CFArrayGetValueAtIndex(availableFonts, 
                                                                                            i);
            CFStringRef availableFontName = (CFStringRef)CTFontDescriptorCopyAttribute(font, 
                                                                          kCTFontNameAttribute);
            
            if (CFStringCompare(cfDesiredFamily, availableFontName, kCFCompareCaseInsensitive)== kCFCompareEqualTo) {
                CFDictionaryRef traits = (CFDictionaryRef)CTFontDescriptorCopyAttribute(font, kCTFontTraitsAttribute);
                traitsMasks.append(toTraitsMask(fontSymbolicTraintsFromTraits(traits), 
                                                fontWeightFromTraits(traits)));
                CFRelease(traits);
                found = YES;
            }
            CFRelease(availableFontName);
            if (found) {
                break;
            }
        }
        CFRelease(availableFonts);
        if (found) {
            return;
        }
    }

    NSArray *fontNames = [UIFont fontNamesForFamilyName:availableFamily];    
    unsigned n = [fontNames count];
    unsigned i;
    for (i = 0; i < n; i++) {
        NSString *fontFullName = [fontNames objectAtIndex:i];

        CFDictionaryRef traits = copyFontTraits(fontFullName);
        traitsMasks.append(toTraitsMask(fontSymbolicTraintsFromTraits(traits), 
                                        fontWeightFromTraits(traits)));
        CFRelease(traits);
    }
}

// Family name is somewhat of a misnomer here.  We first attempt to find an exact match
// comparing the desiredFamily to the PostScript name of the installed fonts.  If that fails
// we then do a search based on the family names of the installed fonts.
+ (CTFontRef)internalFontWithFamily:(NSString *)desiredFamily traits:(CTFontSymbolicTraits)desiredTraits weight:(int)desiredWeight size:(float)size
{
    NSArray *familyNames = [UIFont familyNames];
    NSEnumerator *e = [familyNames objectEnumerator];
    NSString *availableFamily;
    while ((availableFamily = [e nextObject])) {
        if ([desiredFamily caseInsensitiveCompare:availableFamily] == NSOrderedSame)
            break;
    }

    CTFontRef result = NULL;
    if (!availableFamily) {
        // Match by PostScript name.
        CTFontSymbolicTraits desiredTraitsForNameMatch = desiredTraits | (desiredWeight >= 7 ? kCTFontBoldTrait : 0);
        
        CFArrayRef availableFonts = availableFontsArray();
        NSUInteger count = CFArrayGetCount(availableFonts);
        CFStringRef cfDesiredFamily = (CFStringRef)desiredFamily;
        BOOL found = NO;
        for (int i = 0; i < count; ++i) {
            CTFontDescriptorRef fontDesc = (CTFontDescriptorRef)CFArrayGetValueAtIndex(availableFonts, 
                                                                                   i);
            CFStringRef fontName = (CFStringRef)CTFontDescriptorCopyAttribute(fontDesc, 
                                                                                       kCTFontNameAttribute);
            if (CFStringCompare(fontName, cfDesiredFamily, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                found = YES;
                availableFamily = [[desiredFamily copy] autorelease];
                // Special case Osaka-Mono.  According to <rdar://problem/3999467>, we need to 
                // treat Osaka-Mono as fixed pitch.
                if ([desiredFamily caseInsensitiveCompare:@"Osaka-Mono"] == NSOrderedSame && desiredTraitsForNameMatch == 0) {
                    result = CTFontCreateWithName(cfDesiredFamily, size, NULL);
                } else {
                    CFDictionaryRef traits = (CFDictionaryRef)CTFontDescriptorCopyAttribute(fontDesc, kCTFontTraitsAttribute);
                    CTFontSymbolicTraits symTraits = fontSymbolicTraintsFromTraits(traits);
                    
                    if ((symTraits & desiredTraitsForNameMatch) == desiredTraitsForNameMatch) { 
                        result = copyFontToHaveTrait(fontDesc, size, desiredTraitsForNameMatch);
                    }
                }
            }
            
            CFRelease(fontName);
            if (found) {
                break;
            }
        }
        
        CFRelease(availableFonts);
        if (result) {
            return result;
        }
    }

    // Found a family, now figure out what weight and traits to use.
    BOOL choseFont = false;
    int chosenWeight = 0;
    CTFontSymbolicTraits chosenTraits = 0;
    CFStringRef chosenFullName = NULL;

    NSArray *familyFontNames = [UIFont fontNamesForFamilyName:availableFamily];
    for (NSString *fontName in familyFontNames) {
        CTFontDescriptorRef desc = CTFontDescriptorCreateWithNameAndSize((CFStringRef)fontName,
                                                                         size);
        
        CFStringRef fontFullName = (CFStringRef)CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute);
        CFDictionaryRef traits = (CFDictionaryRef)CTFontDescriptorCopyAttribute(desc, 
                                                                                kCTFontTraitsAttribute);
        NSInteger fontWeight = fontWeightFromTraits(traits);
        CTFontSymbolicTraits fontTraits = fontSymbolicTraintsFromTraits(traits);
        
        BOOL newWinner;
        if (!choseFont)
            newWinner = acceptableChoice(desiredTraits, fontTraits);
        else
            newWinner = betterChoice(desiredTraits, desiredWeight, chosenTraits, chosenWeight, fontTraits, fontWeight);
        
        if (newWinner) {
            choseFont = YES;
            chosenWeight = fontWeight;
            chosenTraits = fontTraits;
            if (chosenFullName) {
                CFRelease(chosenFullName);
            }
            chosenFullName = CFStringCreateCopy(NULL, fontFullName);
            
            if (chosenWeight == desiredWeight && (chosenTraits & IMPORTANT_FONT_TRAITS) == (desiredTraits & IMPORTANT_FONT_TRAITS))
                break;
        }
        
        CFRelease(traits);
        CFRelease(fontFullName);
        CFRelease(desc);
    }

    if (!choseFont)
        return nil;

    result = CTFontCreateWithName(chosenFullName, size, NULL);

    if (!result)
        return nil;

    CTFontSymbolicTraits actualSTraits = 0;
    CFDictionaryRef traits = CTFontCopyTraits(result);
    if (desiredTraits & kCTFontItalicTrait) {        
        actualSTraits = fontSymbolicTraintsFromTraits(traits);
    }
    int actualWeight = fontWeightFromTraits(traits);
    CFRelease(traits);
    
    bool syntheticBold = desiredWeight >= 7 && actualWeight < 7;
    bool syntheticOblique = (desiredTraits & kCTFontItalicTrait) && !(actualSTraits & kCTFontItalicTrait);

    // There are some malformed fonts that will be correctly returned by -fontWithFamily:traits:weight:size: as a match for a particular trait,
    // though -[NSFontManager traitsOfFont:] incorrectly claims the font does not have the specified trait. This could result in applying 
    // synthetic bold on top of an already-bold font, as reported in <http://bugs.webkit.org/show_bug.cgi?id=6146>. To work around this
    // problem, if we got an apparent exact match, but the requested traits aren't present in the matched font, we'll try to get a font from 
    // the same family without those traits (to apply the synthetic traits to later).
    CTFontSymbolicTraits nonSyntheticTraits = desiredTraits;

    if (syntheticBold)
        nonSyntheticTraits &= ~kCTFontBoldTrait;

    if (syntheticOblique)
        nonSyntheticTraits &= ~kCTFontItalicTrait;

    if (nonSyntheticTraits != desiredTraits) {
        CFRelease(result);
        
        CFNumberRef weight = CFNumberCreate(NULL, kCFNumberIntType, &chosenWeight);
        CFNumberRef symTraits = CFNumberCreate(NULL, kCFNumberIntType, &nonSyntheticTraits);
        
        CFStringRef traitKeys[] = {kCTFontWeightTrait, kCTFontSymbolicTrait};
        CFTypeRef traitValues[] = {weight, symTraits};
        CFDictionaryRef traits = CFDictionaryCreate(NULL, (const void**)&traitKeys, 
                                                    (const void**)&traitValues, 
                                                    2, NULL, NULL);        
        
        
        CFStringRef keys[] = {kCTFontFamilyNameAttribute, kCTFontTraitsAttribute};
        CFTypeRef values[] = {(CFStringRef)availableFamily, traits};
        CFDictionaryRef options = CFDictionaryCreate(NULL, (const void**)&keys, 
                                                     (const void**)&values, 
                                                     2, NULL, NULL);
        CTFontDescriptorRef desc = CTFontDescriptorCreateWithAttributes(options);
        CTFontRef fontWithoutSyntheticTraits = CTFontCreateWithFontDescriptor(desc, size, NULL);
        if (fontWithoutSyntheticTraits)
            result = fontWithoutSyntheticTraits;
        
        CFRelease(weight);
        CFRelease(symTraits);
        CFRelease(traits);
        CFRelease(options);
        CFRelease(desc);
    }

    return result;
}


+ (CTFontRef)createFontWithFamily:(NSString *)family traits:(CTFontSymbolicTraits)desiredTraits weight:(int)desiredWeight size:(float)size
{
    return [self internalFontWithFamily:family traits:desiredTraits weight:desiredWeight size:size];
}

@end
