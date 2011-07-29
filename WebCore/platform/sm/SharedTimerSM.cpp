#include "config.h"
#include "SharedTimer.h"

namespace WebCore {
    void setSharedTimerFiredFunction(void (*f)())
    {
    }
    
    static void timerFired(CFRunLoopTimerRef, void*)
    {
    }
    
    void setSharedTimerFireTime(double fireTime)
    {
    }
    
    void stopSharedTimer()
    {
    }
    
} // namespace WebCore
