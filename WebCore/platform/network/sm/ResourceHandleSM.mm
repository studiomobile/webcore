//
//  ResourceHandleSM.cpp
//  smWebCore
//
//  Created by Andrey Verbin on 7/8/11.
//  Copyright 2011 Studio Mobile. All rights reserved.
//

#include "config.h"
#include "SharedBuffer.h"
#include "ResourceHandle.h"
#include "ResourceHandleInternal.h"
#include "ResourceHandleClient.h"
#include "BlockExceptions.h"


using namespace WebCore;

@interface WebCoreResourceHandleAsDelegate : NSObject <NSURLConnectionDelegate> {
    ResourceHandle* m_handle;
    DataTransformation *m_transformation;
}
- (id)initWithHandle:(ResourceHandle *)handle transformation:(PassRefPtr<DataTransformation>)converter;
- (void)detachHandle;
@end

class WebCoreSynchronousLoaderClient : public ResourceHandleClient {
public:
    static PassOwnPtr<WebCoreSynchronousLoaderClient> create()
    {
        return adoptPtr(new WebCoreSynchronousLoaderClient);
    }
    
    virtual ~WebCoreSynchronousLoaderClient();
    
    void setAllowStoredCredentials(bool allow) { m_allowStoredCredentials = allow; }
    NSURLResponse *response() { return m_response; }
    NSMutableData *data() { return m_data; }
    NSError *error() { return m_error; }
    bool isDone() { return m_isDone; }
    
private:
    WebCoreSynchronousLoaderClient()
    : m_allowStoredCredentials(false)
    , m_response(0)
    , m_data(0)
    , m_error(0)
    , m_isDone(false)
    {
    }
    
    virtual void willSendRequest(ResourceHandle*, ResourceRequest&, const ResourceResponse& /*redirectResponse*/);
    virtual bool shouldUseCredentialStorage(ResourceHandle*);
    virtual void didReceiveAuthenticationChallenge(ResourceHandle*, const AuthenticationChallenge&);
    virtual void didReceiveResponse(ResourceHandle*, const ResourceResponse&);
    virtual void didReceiveData(ResourceHandle*, const char*, int, int /*encodedDataLength*/);
    virtual void didFinishLoading(ResourceHandle*, double /*finishTime*/);
    virtual void didFail(ResourceHandle*, const ResourceError&);
#if USE(PROTECTION_SPACE_AUTH_CALLBACK)
    virtual bool canAuthenticateAgainstProtectionSpace(ResourceHandle*, const ProtectionSpace&);
#endif
    
    bool m_allowStoredCredentials;
    NSURLResponse *m_response;
    NSMutableData *m_data;
    NSError *m_error;
    bool m_isDone;
};

namespace WebCore {
    void ResourceHandle::createNSURLConnection(id delegate, bool shouldUseCredentialStorage, bool shouldContentSniff)
    {    
        NSURLRequest *nsRequest = firstRequest().nsURLRequest();
        
        d->m_connection.adoptNS([[NSURLConnection alloc] initWithRequest:nsRequest 
                                                                delegate:delegate 
                                                        startImmediately:NO]);
        return;
        
    }
    
    ResourceHandleInternal::~ResourceHandleInternal()
    {
    }
    
    ResourceHandle::~ResourceHandle()
    {
    }
    
    bool ResourceHandle::start(NetworkingContext* context)
    {
        if (!context)
            return false;
        
        BEGIN_BLOCK_OBJC_EXCEPTIONS;
        
        // If NetworkingContext is invalid then we are no longer attached to a Page,
        // this must be an attempted load from an unload event handler, so let's just block it.
        if (!context->isValid())
            return false;
        
        bool shouldUseCredentialStorage = NO;
        
        d->m_needsSiteSpecificQuirks = NO;


            createNSURLConnection(
                              ResourceHandle::delegate(context),
                              shouldUseCredentialStorage,
                              d->m_shouldContentSniff || context->localFileContentSniffingEnabled());
        
        bool scheduled = false;
        if (SchedulePairHashSet* scheduledPairs = context->scheduledRunLoopPairs()) {
            SchedulePairHashSet::iterator end = scheduledPairs->end();
            for (SchedulePairHashSet::iterator it = scheduledPairs->begin(); it != end; ++it) {
                if (NSRunLoop *runLoop = (*it)->nsRunLoop()) {
                    [connection() scheduleInRunLoop:runLoop forMode:(NSString *)(*it)->mode()];
                    scheduled = true;
                }
            }
        }
        
        // Start the connection if we did schedule with at least one runloop.
        // We can't start the connection until we have one runloop scheduled.
        if (scheduled)
            [connection() start];
        else
            d->m_startWhenScheduled = true;
        
        if (d->m_connection) {
            if (d->m_defersLoading) {
                NSLog(@"OOPSS!!! here should be a call to wkSetNSURLConnectionDefersCallbacks");
                //wkSetNSURLConnectionDefersCallbacks(connection(), YES);
            }
            
            return true;
        }
        
        END_BLOCK_OBJC_EXCEPTIONS;
        
        return false;
    }
    
    WebCoreResourceHandleAsDelegate *ResourceHandle::delegate(NetworkingContext *context)
    {
        if (!d->m_delegate) {
            NSURLRequest *nsRequest = firstRequest().nsURLRequest();
            DataTransformationProvider *provider = context->dataTransformationProvider().get();
            RefPtr<DataTransformation> t;
            if (provider) {
                t = provider->transformationForURL(nsRequest.URL);
            }
            WebCoreResourceHandleAsDelegate *delegate = [[WebCoreResourceHandleAsDelegate alloc] initWithHandle:this transformation:t];
            d->m_delegate = delegate;
            [delegate release];
        }
        return d->m_delegate.get();
    }
    
    bool ResourceHandle::willLoadFromCache(ResourceRequest& request, Frame*)
    {
        request.setCachePolicy(ReturnCacheDataDontLoad);
        NSURLResponse *nsURLResponse = nil;
        BEGIN_BLOCK_OBJC_EXCEPTIONS;
        
        [NSURLConnection sendSynchronousRequest:request.nsURLRequest() returningResponse:&nsURLResponse error:nil];
        
        END_BLOCK_OBJC_EXCEPTIONS;
        
        return nsURLResponse;
    }
    
    bool ResourceHandle::supportsBufferedData() {
        return NO;
    }

    PassRefPtr<SharedBuffer> ResourceHandle::bufferedData()
    {
        return 0;
    }
    
    unsigned initializeMaximumHTTPConnectionCountPerHost()
    {
        // This is used by the loader to control the number of issued parallel load requests. 
        // Four seems to be a common default in HTTP frameworks.
        return 4;
    }
    
    NSURLConnection *ResourceHandle::connection() const
    {
        return d->m_connection.get();
    }
    
    bool ResourceHandle::shouldUseCredentialStorage()
    {
        return false;
    }
    
    void ResourceHandle::loadResourceSynchronously(NetworkingContext* context, const ResourceRequest& request, StoredCredentials storedCredentials, ResourceError& error, ResourceResponse& response, Vector<char>& data)
    {
#if ENABLE(BLOB)
        if (request.url().protocolIs("blob"))
            if (blobRegistry().loadResourceSynchronously(request, error, response, data))
                return;
#endif
        
        NSError *nsError = nil;
        NSURLResponse *nsURLResponse = nil;
        NSData *result = nil;
        
        ASSERT(!request.isEmpty());
        
        OwnPtr<WebCoreSynchronousLoaderClient> client = WebCoreSynchronousLoaderClient::create();
        client->setAllowStoredCredentials(storedCredentials == AllowStoredCredentials);
        
        RefPtr<ResourceHandle> handle = adoptRef(new ResourceHandle(request, client.get(), false /*defersLoading*/, true /*shouldContentSniff*/));
        
        if (context && handle->d->m_scheduledFailureType != NoFailure) {
            error = context->blockedError(request);
            return;
        }
        
        handle->createNSURLConnection(
                                      handle->delegate(context), // A synchronous request cannot turn into a download, so there is no need to proxy the delegate.
                                      storedCredentials == AllowStoredCredentials,
                                      handle->shouldContentSniff() || (context && context->localFileContentSniffingEnabled()));
        
        [handle->connection() scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(NSString *)synchronousLoadRunLoopMode()];
        [handle->connection() start];
        
        while (!client->isDone())
            [[NSRunLoop currentRunLoop] runMode:(NSString *)synchronousLoadRunLoopMode() beforeDate:[NSDate distantFuture]];
        
        result = client->data();
        nsURLResponse = client->response();
        nsError = client->error();
        
        [handle->connection() cancel];
        
        
        if (!nsError)
            response = nsURLResponse;
        else {
            response = ResourceResponse(request.url(), String(), 0, String(), String());
            if ([nsError domain] == NSURLErrorDomain)
                switch ([nsError code]) {
                    case NSURLErrorUserCancelledAuthentication:
                        // FIXME: we should really return the actual HTTP response, but sendSynchronousRequest doesn't provide us with one.
                        response.setHTTPStatusCode(401);
                        break;
                    default:
                        response.setHTTPStatusCode([nsError code]);
                }
            else
                response.setHTTPStatusCode(404);
        }
        
        data.resize([result length]);
        memcpy(data.data(), [result bytes], [result length]);
        
        error = nsError;
    }
    
    CFStringRef ResourceHandle::synchronousLoadRunLoopMode()
    {
        return CFSTR("WebCoreSynchronousLoaderRunLoopMode");
    }
    
    void ResourceHandle::receivedCredential(const AuthenticationChallenge& challenge, const Credential& credential)
    {
        clearAuthentication();
    }
    
    void ResourceHandle::receivedRequestToContinueWithoutCredential(const AuthenticationChallenge& challenge)
    {
        clearAuthentication();
    }
    
    void ResourceHandle::receivedCancellation(const AuthenticationChallenge& challenge)
    {
        if (challenge != d->m_currentWebChallenge)
            return;
        
        if (client())
            client()->receivedCancellation(this, challenge);
    }
    
    void ResourceHandle::cancel()
    {
        // Leaks were seen on HTTP tests without this; can be removed once <rdar://problem/6886937> is fixed.
        if (d->m_currentMacChallenge)
            [[d->m_currentMacChallenge sender] cancelAuthenticationChallenge:d->m_currentMacChallenge];
        
        [d->m_connection.get() cancel];
    }

}


@implementation WebCoreResourceHandleAsDelegate

- (id)initWithHandle:(ResourceHandle *)handle transformation:(PassRefPtr<DataTransformation>)dtRef {
    self = [self init];
    if (!self)
        return nil;
    m_handle = handle;
    DataTransformation *dt = dtRef.get();
    if (dt) {
        dt->ref();
    }
    m_transformation = dt;
    return self;
}


- (void)detachHandle
{
    m_handle = 0;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)newRequest redirectResponse:(NSURLResponse *)redirectResponse
{
    
    // the willSendRequest call may cancel this load, in which case self could be deallocated
    RetainPtr<WebCoreResourceHandleAsDelegate> protect(self);
    
    if (!m_handle || !m_handle->client())
        return nil;
    
    return newRequest;
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    if (!m_handle)
        return NO;
    
    return m_handle->shouldUseCredentialStorage();
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!m_handle) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }
    //m_handle->didReceiveAuthenticationChallenge(NULL);
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!m_handle)
        return;
    //m_handle->didCancelAuthenticationChallenge(NULL);
}

#if USE(PROTECTION_SPACE_AUTH_CALLBACK)
- (BOOL)connection:(NSURLConnection *)unusedConnection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    if (!m_handle)
        return NO;
    
    return NO;//m_handle->canAuthenticateAgainstProtectionSpace(NULL);
}
#endif

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)r
{
    if (!m_handle || !m_handle->client())
        return;
    
    m_handle->client()->didReceiveResponse(m_handle, r);
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data lengthReceived:(long long)lengthReceived
{
    if (!m_handle || !m_handle->client())
        return;
    // FIXME: If we get more than 2B bytes in a single chunk, this code won't do the right thing.
    // However, with today's computers and networking speeds, this won't happen in practice.
    // Could be an issue with a giant local file.
    
    // FIXME: https://bugs.webkit.org/show_bug.cgi?id=19793
    // -1 means we do not provide any data about transfer size to inspector so it would use
    // Content-Length headers or content size to show transfer size.
    void const *bytes = data.bytes;
    NSUInteger length = data.length;
    NSMutableData *transformed = nil;
    if (m_transformation) {
        transformed = [NSMutableData new];
        m_transformation->transform(bytes, length, transformed);
        bytes = transformed.bytes;
        length = transformed.length;
    }

    m_handle->client()->didReceiveData(m_handle, (const char*)bytes, length, -1);

    if (m_transformation) {
        [transformed release];
    }
}

- (void)connection:(NSURLConnection *)connection willStopBufferingData:(NSData *)data
{
    if (!m_handle || !m_handle->client())
        return;
    // FIXME: If we get a resource with more than 2B bytes, this code won't do the right thing.
    // However, with today's computers and networking speeds, this won't happen in practice.
    // Could be an issue with a giant local file.
    m_handle->client()->willStopBufferingData(m_handle, (const char*)[data bytes], static_cast<int>([data length]));
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (!m_handle || !m_handle->client())
        return;
    m_handle->client()->didSendData(m_handle, totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (!m_handle || !m_handle->client())
        return;
    
    m_handle->client()->didFinishLoading(m_handle, 0);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (!m_handle || !m_handle->client())
        return;
    
    m_handle->client()->didFail(m_handle, error);
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    if (!m_handle || !m_handle->client())
        return nil;
    
    NSCachedURLResponse *newResponse = m_handle->client()->willCacheResponse(m_handle, cachedResponse);
    if (newResponse != cachedResponse)
        return newResponse;
    
    CacheStoragePolicy policy = static_cast<CacheStoragePolicy>([newResponse storagePolicy]);
    
    m_handle->client()->willCacheResponse(m_handle, policy);
    
    if (static_cast<NSURLCacheStoragePolicy>(policy) != [newResponse storagePolicy])
        newResponse = [[[NSCachedURLResponse alloc] initWithResponse:[newResponse response]
                                                                data:[newResponse data]
                                                            userInfo:[newResponse userInfo]
                                                       storagePolicy:static_cast<NSURLCacheStoragePolicy>(policy)] autorelease];
        
        return newResponse;
}


- (void)dealloc {
    if (m_transformation) {
        m_transformation->deref();
    }

    [super dealloc];
}

@end

WebCoreSynchronousLoaderClient::~WebCoreSynchronousLoaderClient()
{
    [m_response release];
    [m_data release];
    [m_error release];
}

void ResourceHandle::schedule(SchedulePair* pair)
{
    NSRunLoop *runLoop = pair->nsRunLoop();
    if (!runLoop)
        return;
    [d->m_connection.get() scheduleInRunLoop:runLoop forMode:(NSString *)pair->mode()];
    if (d->m_startWhenScheduled) {
        [d->m_connection.get() start];
        d->m_startWhenScheduled = false;
    }
}

void ResourceHandle::unschedule(SchedulePair* pair)
{
    if (NSRunLoop *runLoop = pair->nsRunLoop())
        [d->m_connection.get() unscheduleFromRunLoop:runLoop forMode:(NSString *)pair->mode()];
}

void WebCoreSynchronousLoaderClient::willSendRequest(ResourceHandle* handle, ResourceRequest& request, const ResourceResponse& /*redirectResponse*/)
{
    // FIXME: This needs to be fixed to follow the redirect correctly even for cross-domain requests.
    if (!protocolHostAndPortAreEqual(handle->firstRequest().url(), request.url())) {
        ASSERT(!m_error);
        m_error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
        m_isDone = true;
        request = (NSURLRequest*)0;
        return;
    }
}

bool WebCoreSynchronousLoaderClient::shouldUseCredentialStorage(ResourceHandle*)
{
    // FIXME: We should ask FrameLoaderClient whether using credential storage is globally forbidden.
    return m_allowStoredCredentials;
}

#if USE(PROTECTION_SPACE_AUTH_CALLBACK)
bool WebCoreSynchronousLoaderClient::canAuthenticateAgainstProtectionSpace(ResourceHandle*, const ProtectionSpace&)
{
    // FIXME: We should ask FrameLoaderClient.
    return true;
}
#endif

void WebCoreSynchronousLoaderClient::didReceiveAuthenticationChallenge(ResourceHandle*, const AuthenticationChallenge& challenge)
{
    // FIXME: The user should be asked for credentials, as in async case.
    //[challenge.sender() continueWithoutCredentialForAuthenticationChallenge:challenge.nsURLAuthenticationChallenge()];
}

void WebCoreSynchronousLoaderClient::didReceiveResponse(ResourceHandle*, const ResourceResponse& response)
{
    [m_response release];
    m_response = [response.nsURLResponse() copy];
}

void WebCoreSynchronousLoaderClient::didReceiveData(ResourceHandle*, const char* data, int length, int /*encodedDataLength*/)
{
    if (!m_data)
        m_data = [[NSMutableData alloc] init];
    [m_data appendBytes:data length:length];
}

void WebCoreSynchronousLoaderClient::didFinishLoading(ResourceHandle *h, double)
{
    m_isDone = true;
}

void WebCoreSynchronousLoaderClient::didFail(ResourceHandle*, const ResourceError& error)
{
    ASSERT(!m_error);
    
    m_error = [error copy];
    m_isDone = true;
}
