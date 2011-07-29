//
//  ResourceRequestSM.cpp
//  smWebCore
//
//  Created by Andrey Verbin on 7/8/11.
//  Copyright 2011 Studio Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "config.h"
#include "ResourceRequest.h"
#include "HTTPHeaderMap.h"

namespace WebCore {
    NSURLRequest* ResourceRequest::nsURLRequest() const
    { 
        updatePlatformRequest();
        
        return [[m_nsRequest.get() retain] autorelease]; 
    }
    
    
    void ResourceRequest::doUpdateResourceRequest()
    {
        m_url = [m_nsRequest.get() URL];
        m_cachePolicy = (ResourceRequestCachePolicy)[m_nsRequest.get() cachePolicy];
        m_timeoutInterval = [m_nsRequest.get() timeoutInterval];
        m_firstPartyForCookies = [m_nsRequest.get() mainDocumentURL];
        
        if (NSString* method = [m_nsRequest.get() HTTPMethod])
            m_httpMethod = method;
        m_allowCookies = [m_nsRequest.get() HTTPShouldHandleCookies];
                
        NSDictionary *headers = [m_nsRequest.get() allHTTPHeaderFields];
        NSEnumerator *e = [headers keyEnumerator];
        NSString *name;
        m_httpHeaderFields.clear();
        while ((name = [e nextObject]))
            m_httpHeaderFields.set(name, [headers objectForKey:name]);
    }
    
    void ResourceRequest::doUpdatePlatformRequest()
    {
        if (isNull()) {
            m_nsRequest = nil;
            return;
        }
        
        NSMutableURLRequest* nsRequest = [m_nsRequest.get() mutableCopy];
        
        if (nsRequest)
            [nsRequest setURL:url()];
        else
            nsRequest = [[NSMutableURLRequest alloc] initWithURL:url()];
        
        
        [nsRequest setCachePolicy:(NSURLRequestCachePolicy)cachePolicy()];
        
        double timeoutInterval = ResourceRequestBase::timeoutInterval();
        if (timeoutInterval)
            [nsRequest setTimeoutInterval:timeoutInterval];
        // Otherwise, respect NSURLRequest default timeout.
        
        [nsRequest setMainDocumentURL:firstPartyForCookies()];
        if (!httpMethod().isEmpty())
            [nsRequest setHTTPMethod:httpMethod()];
        [nsRequest setHTTPShouldHandleCookies:allowCookies()];
        
        // Cannot just use setAllHTTPHeaderFields here, because it does not remove headers.
        NSArray *oldHeaderFieldNames = [[nsRequest allHTTPHeaderFields] allKeys];
        for (unsigned i = [oldHeaderFieldNames count]; i != 0; --i)
            [nsRequest setValue:nil forHTTPHeaderField:[oldHeaderFieldNames objectAtIndex:i - 1]];
        HTTPHeaderMap::const_iterator end = httpHeaderFields().end();
        for (HTTPHeaderMap::const_iterator it = httpHeaderFields().begin(); it != end; ++it)
            [nsRequest setValue:it->second forHTTPHeaderField:it->first];
        
        m_nsRequest.adoptNS(nsRequest);
    }

}

