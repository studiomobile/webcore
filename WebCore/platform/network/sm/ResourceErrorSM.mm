//
//  ResourceErrorSM.mm
//  smWebCore
//
//  Created by Andrey Verbin on 7/8/11.
//  Copyright 2011 Studio Mobile. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "config.h"
#include "ResourceError.h"

namespace WebCore {
        
    ResourceError::ResourceError(NSError *error)
    : m_dataIsUpToDate(false)
    , m_platformError(error)
    {
        m_isNull = !error;
    }
    
    NSError *ResourceError::nsError() const
    {
        if (m_isNull) {
            ASSERT(!m_platformError);
            return nil;
        }
        if (!m_platformNSError) {
            CFErrorRef error = (CFErrorRef)m_platformError.get();
            RetainPtr<NSDictionary> userInfo(AdoptCF, (NSDictionary *) CFErrorCopyUserInfo(error));
            m_platformNSError.adoptNS([[NSError alloc] initWithDomain:(NSString *)CFErrorGetDomain(error) code:CFErrorGetCode(error) userInfo:userInfo.get()]);
        }
        return m_platformNSError.get();
    }
    
    ResourceError::operator NSError *() const
    {
        return nsError();
    }

}
