#include "DNS.h"

namespace WebCore {

#if !USE(SOUP)
void prefetchDNS(const String& hostname) {};
#endif

}