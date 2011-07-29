//
//  ImageSM.mm
//  smWebCore
//
//  Created by Andrey Verbin on 7/8/11.
//  Copyright 2011 Studio Mobile. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <Foundation/Foundation.h>
#import "config.h"
#import "Image.h"
#import "SharedBuffer.h"
#import "BitmapImage.h"

@interface WebCoreBundleFinder : NSObject
@end

@implementation WebCoreBundleFinder
@end

namespace WebCore {

    void BitmapImage::initPlatformData()
    {
    }
    
    PassRefPtr<Image> Image::loadPlatformResource(const char *name)
    {
        NSBundle *bundle = [NSBundle bundleForClass:[WebCoreBundleFinder class]];
        NSString *imagePath = [bundle pathForResource:[NSString stringWithUTF8String:name] ofType:@"tiff"];
        NSData *namedImageData = [NSData dataWithContentsOfFile:imagePath];
        if (namedImageData) {
            RefPtr<Image> image = BitmapImage::create();
            image->setData(SharedBuffer::wrapNSData(namedImageData), true);
            return image.release();
        }
        
        // We have reports indicating resource loads are failing, but we don't yet know the root cause(s).
        // Two theories are bad installs (image files are missing), and too-many-open-files.
        // See rdar://5607381
        ASSERT_NOT_REACHED();
        return Image::nullImage();
    }
}
