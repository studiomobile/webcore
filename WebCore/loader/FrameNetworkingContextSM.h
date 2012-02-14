
#ifndef smWebCore_FrameNetworkingContextSM_h
#define smWebCore_FrameNetworkingContextSM_h

#include "FrameNetworkingContext.h"

#include  "FrameLoaderClient.h"
#include  "Page.h"
#include  "ResourceError.h"
#include  "Settings.h"
#include  "SchedulePair.h"

namespace WebCore {

    class FrameNetworkingContextSM : public FrameNetworkingContext {
        
    public:
        FrameNetworkingContextSM(Frame *f, PassRefPtr<DataTransformationProvider> provider) : FrameNetworkingContext(f) {
            m_dataConverterProvider = provider;
        }
        
    virtual bool needsSiteSpecificQuirks() const;
    virtual bool localFileContentSniffingEnabled() const;
    virtual SchedulePairHashSet* scheduledRunLoopPairs() const;
    virtual ResourceError blockedError(const ResourceRequest&) const;
    virtual PassRefPtr<DataTransformationProvider> dataTransformationProvider() const;

    private:
    RefPtr<DataTransformationProvider> m_dataConverterProvider;
};

}
#endif
