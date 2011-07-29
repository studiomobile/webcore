#import "config.h"
#import "Theme.h"

namespace WebCore {
    
    Theme* platformTheme()
    {
        DEFINE_STATIC_LOCAL(Theme, theme, ());
        return &theme;
    }
    
}
