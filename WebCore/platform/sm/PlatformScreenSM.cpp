#include "PlatformScreen.h"

namespace WebCore {

bool screenIsMonochrome(Widget*) {
    return 0;
}

    
int screenDepthPerComponent(Widget*)
{
    return 8;
}

int screenDepth(Widget*)
{
    return 32;
}
    
    
    
FloatRect screenAvailableRect(Widget* widget)
{
    return FloatRect(0,0,0,0);
}
    
    
    FloatRect screenRect(Widget* widget)
    {
        return FloatRect(0,0,0,0);
    }



}


