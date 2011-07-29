/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
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

#include "config.h"

#if ENABLE(SVG) && ENABLE(FILTERS)
#include "SVGFEOffsetElement.h"

#include "Attribute.h"
#include "FilterEffect.h"
#include "SVGElementInstance.h"
#include "SVGFilterBuilder.h"
#include "SVGNames.h"

namespace WebCore {

// Animated property definitions
DEFINE_ANIMATED_STRING(SVGFEOffsetElement, SVGNames::inAttr, In1, in1)
DEFINE_ANIMATED_NUMBER(SVGFEOffsetElement, SVGNames::dxAttr, Dx, dx)
DEFINE_ANIMATED_NUMBER(SVGFEOffsetElement, SVGNames::dyAttr, Dy, dy)

inline SVGFEOffsetElement::SVGFEOffsetElement(const QualifiedName& tagName, Document* document)
    : SVGFilterPrimitiveStandardAttributes(tagName, document)
{
    ASSERT(hasTagName(SVGNames::feOffsetTag));
}

PassRefPtr<SVGFEOffsetElement> SVGFEOffsetElement::create(const QualifiedName& tagName, Document* document)
{
    return adoptRef(new SVGFEOffsetElement(tagName, document));
}

bool SVGFEOffsetElement::isSupportedAttribute(const QualifiedName& attrName)
{
    DEFINE_STATIC_LOCAL(HashSet<QualifiedName>, supportedAttributes, ());
    if (supportedAttributes.isEmpty()) {
        supportedAttributes.add(SVGNames::inAttr);
        supportedAttributes.add(SVGNames::dxAttr);
        supportedAttributes.add(SVGNames::dyAttr);
    }
    return supportedAttributes.contains(attrName);
}

void SVGFEOffsetElement::parseMappedAttribute(Attribute* attr)
{
    if (!isSupportedAttribute(attr->name())) {
        SVGFilterPrimitiveStandardAttributes::parseMappedAttribute(attr);
        return;
    }

    const AtomicString& value = attr->value();
    if (attr->name() == SVGNames::dxAttr) {
        setDxBaseValue(value.toFloat());
        return;
    }

    if (attr->name() == SVGNames::dyAttr) {
        setDyBaseValue(value.toFloat());
        return;
    }

    if (attr->name() == SVGNames::inAttr) {
        setIn1BaseValue(value);
        return;
    }

    ASSERT_NOT_REACHED();
}

void SVGFEOffsetElement::svgAttributeChanged(const QualifiedName& attrName)
{
    if (!isSupportedAttribute(attrName)) {
        SVGFilterPrimitiveStandardAttributes::svgAttributeChanged(attrName);
        return;
    }

    SVGElementInstance::InvalidationGuard invalidationGuard(this);
    
    if (attrName == SVGNames::inAttr || attrName == SVGNames::dxAttr || attrName == SVGNames::dyAttr) {
        invalidate();
        return;
    }

    ASSERT_NOT_REACHED();
}

void SVGFEOffsetElement::synchronizeProperty(const QualifiedName& attrName)
{
    if (attrName == anyQName()) {
        synchronizeDx();
        synchronizeDy();
        synchronizeIn1();
        SVGFilterPrimitiveStandardAttributes::synchronizeProperty(attrName);
        return;
    }

    if (!isSupportedAttribute(attrName)) {
        SVGFilterPrimitiveStandardAttributes::synchronizeProperty(attrName);
        return;
    }

    if (attrName == SVGNames::dxAttr) {
        synchronizeDx();
        return;
    }

    if (attrName == SVGNames::dyAttr) {
        synchronizeDy();
        return;
    }

    if (attrName == SVGNames::inAttr) {
        synchronizeIn1();
        return;
    }

    ASSERT_NOT_REACHED();
}

AttributeToPropertyTypeMap& SVGFEOffsetElement::attributeToPropertyTypeMap()
{
    DEFINE_STATIC_LOCAL(AttributeToPropertyTypeMap, s_attributeToPropertyTypeMap, ());
    return s_attributeToPropertyTypeMap;
}

void SVGFEOffsetElement::fillAttributeToPropertyTypeMap()
{
    AttributeToPropertyTypeMap& attributeToPropertyTypeMap = this->attributeToPropertyTypeMap();

    SVGFilterPrimitiveStandardAttributes::fillPassedAttributeToPropertyTypeMap(attributeToPropertyTypeMap);
    attributeToPropertyTypeMap.set(SVGNames::inAttr, AnimatedString);
    attributeToPropertyTypeMap.set(SVGNames::dxAttr, AnimatedNumber);
    attributeToPropertyTypeMap.set(SVGNames::dyAttr, AnimatedNumber);
}

PassRefPtr<FilterEffect> SVGFEOffsetElement::build(SVGFilterBuilder* filterBuilder, Filter* filter)
{
    FilterEffect* input1 = filterBuilder->getEffectById(in1());

    if (!input1)
        return 0;

    RefPtr<FilterEffect> effect = FEOffset::create(filter, dx(), dy());
    effect->inputEffects().append(input1);
    return effect.release();
}

}

#endif // ENABLE(SVG)