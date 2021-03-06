/*
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef SVGAnimatorFactory_h
#define SVGAnimatorFactory_h

#if ENABLE(SVG) && ENABLE(SVG_ANIMATION)
#include "SVGAnimatedAngle.h"
#include "SVGAnimatedColor.h"
#include "SVGAnimatedLength.h"
#include "SVGAnimatedNumber.h"
#include "SVGAnimatedPointList.h"
#include "SVGAnimatedRect.h"

namespace WebCore {

class SVGAnimationElement;
    
class SVGAnimatorFactory {
public:
    static PassOwnPtr<SVGAnimatedTypeAnimator> create(SVGAnimationElement* animationElement, SVGElement* contextElement, AnimatedAttributeType attributeType)
    {
        ASSERT(animationElement);
        ASSERT(contextElement);

        // FIXME: Add animation support for all SVG units.
        switch (attributeType) {
        case AnimatedAngle:
            return adoptPtr(new SVGAnimatedAngleAnimator(animationElement, contextElement));
        case AnimatedColor:
            return adoptPtr(new SVGAnimatedColorAnimator(animationElement, contextElement));
        case AnimatedLength:
            return adoptPtr(new SVGAnimatedLengthAnimator(animationElement, contextElement));
        case AnimatedNumber:
            return adoptPtr(new SVGAnimatedNumberAnimator(animationElement, contextElement));
        case AnimatedPoints:
            return adoptPtr(new SVGAnimatedPointListAnimator(animationElement, contextElement));
        case AnimatedRect:
            return adoptPtr(new SVGAnimatedRectAnimator(animationElement, contextElement));
        default:
            ASSERT_NOT_REACHED();
            return adoptPtr(new SVGAnimatedLengthAnimator(animationElement, contextElement));
        }
    }

private:
    SVGAnimatorFactory() { }

};
    
} // namespace WebCore

#endif // ENABLE(SVG) && ENABLE(SVG_ANIMATION)
#endif // SVGAnimatorFactory_h
