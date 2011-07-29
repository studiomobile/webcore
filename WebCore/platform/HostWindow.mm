#include "HostWindow.h"

#import <UIKit/UIKit.h>

namespace WebCore {

HostWindow::HostWindow() : m_client([[UIView alloc] init]) {
    
}

HostWindow::~HostWindow() {
    [m_client release];
}

}

