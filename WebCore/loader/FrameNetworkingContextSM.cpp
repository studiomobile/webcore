#import "FrameNetworkingContextSM.h"


namespace WebCore {

bool FrameNetworkingContextSM::needsSiteSpecificQuirks() const
{
    return false;
}

bool FrameNetworkingContextSM::localFileContentSniffingEnabled() const
{
    return false;
}

SchedulePairHashSet* FrameNetworkingContextSM::scheduledRunLoopPairs() const
{
    return frame() && frame()->page() ? frame()->page()->scheduledRunLoopPairs() : 0;
}

ResourceError FrameNetworkingContextSM::blockedError(const ResourceRequest& request) const
{
    return frame()->loader()->client()->blockedError(request);
}

}