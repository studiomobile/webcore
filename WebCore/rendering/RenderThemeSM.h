//
//  RenderThemeSM.h
//  smWebCore
//
//  Created by Andrey Verbin on 7/11/11.
//  Copyright 2011 Studio Mobile. All rights reserved.
//

#ifndef smWebCore_RenderThemeSM_h
#define smWebCore_RenderThemeSM_h

#import <UIKit/UIKit.h>
#include "RenderTheme.h"

namespace WebCore {
    class RenderThemeSM : public RenderTheme {
    public:
        static void setDefaultSelectionBackgroundColor(Color c);

        static PassRefPtr<RenderTheme> create();  
        
        virtual void systemFont(int cssValueId, FontDescription&) const;
        
        void setPlatformActiveSelectionBackgroundColor(Color c);
        virtual Color platformActiveSelectionBackgroundColor() const;
        virtual Color platformInactiveSelectionBackgroundColor() const;
        virtual Color platformActiveSelectionForegroundColor() const;
        virtual Color platformInactiveSelectionForegroundColor() const;
        
    private:
        Color m_selectionBackgroundColor;
    };
    
}

#endif
