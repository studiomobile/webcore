//
//  ResourceResponseSM.mm
//  smWebCore
//
//  Created by Andrey Verbin on 7/8/11.
//  Copyright 2011 Studio Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "config.h"
#include "ResourceResponse.h"

namespace WebCore {
    
    
    NSURLResponse *ResourceResponse::nsURLResponse() const
    {
        if (!m_nsResponse && !m_isNull) {
            // Work around a mistake in the NSURLResponse class.
            // The init function takes an NSInteger, even though the accessor returns a long long.
            // For values that won't fit in an NSInteger, pass -1 instead.
            NSInteger expectedContentLength;
            if (m_expectedContentLength < 0 || m_expectedContentLength > std::numeric_limits<NSInteger>::max())
                expectedContentLength = -1;
            else
                expectedContentLength = static_cast<NSInteger>(m_expectedContentLength);
            const_cast<ResourceResponse*>(this)->m_nsResponse.adoptNS([[NSURLResponse alloc] initWithURL:m_url MIMEType:m_mimeType expectedContentLength:expectedContentLength textEncodingName:m_textEncodingName]);
        }
        return m_nsResponse.get();
    }
    
}
