/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007 Rob Buis <buis@kde.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

#if ENABLE(SVG)
#include "SVGPatternElement.h"

#include "AffineTransform.h"
#include "Attribute.h"
#include "Document.h"
#include "FloatConversion.h"
#include "GraphicsContext.h"
#include "ImageBuffer.h"
#include "PatternAttributes.h"
#include "RenderSVGContainer.h"
#include "RenderSVGResourcePattern.h"
#include "SVGElementInstance.h"
#include "SVGNames.h"
#include "SVGRenderSupport.h"
#include "SVGSVGElement.h"
#include "SVGStyledTransformableElement.h"
#include "SVGTransformable.h"

namespace WebCore {

// Animated property definitions
DEFINE_ANIMATED_LENGTH(SVGPatternElement, SVGNames::xAttr, X, x)
DEFINE_ANIMATED_LENGTH(SVGPatternElement, SVGNames::yAttr, Y, y)
DEFINE_ANIMATED_LENGTH(SVGPatternElement, SVGNames::widthAttr, Width, width)
DEFINE_ANIMATED_LENGTH(SVGPatternElement, SVGNames::heightAttr, Height, height)
DEFINE_ANIMATED_ENUMERATION(SVGPatternElement, SVGNames::patternUnitsAttr, PatternUnits, patternUnits, SVGUnitTypes::SVGUnitType)
DEFINE_ANIMATED_ENUMERATION(SVGPatternElement, SVGNames::patternContentUnitsAttr, PatternContentUnits, patternContentUnits, SVGUnitTypes::SVGUnitType)
DEFINE_ANIMATED_TRANSFORM_LIST(SVGPatternElement, SVGNames::patternTransformAttr, PatternTransform, patternTransform) 
DEFINE_ANIMATED_STRING(SVGPatternElement, XLinkNames::hrefAttr, Href, href)
DEFINE_ANIMATED_BOOLEAN(SVGPatternElement, SVGNames::externalResourcesRequiredAttr, ExternalResourcesRequired, externalResourcesRequired)
DEFINE_ANIMATED_RECT(SVGPatternElement, SVGNames::viewBoxAttr, ViewBox, viewBox)
DEFINE_ANIMATED_PRESERVEASPECTRATIO(SVGPatternElement, SVGNames::preserveAspectRatioAttr, PreserveAspectRatio, preserveAspectRatio) 

inline SVGPatternElement::SVGPatternElement(const QualifiedName& tagName, Document* document)
    : SVGStyledElement(tagName, document)
    , m_x(LengthModeWidth)
    , m_y(LengthModeHeight)
    , m_width(LengthModeWidth)
    , m_height(LengthModeHeight)
    , m_patternUnits(SVGUnitTypes::SVG_UNIT_TYPE_OBJECTBOUNDINGBOX)
    , m_patternContentUnits(SVGUnitTypes::SVG_UNIT_TYPE_USERSPACEONUSE)
{
    ASSERT(hasTagName(SVGNames::patternTag));
}

PassRefPtr<SVGPatternElement> SVGPatternElement::create(const QualifiedName& tagName, Document* document)
{
    return adoptRef(new SVGPatternElement(tagName, document));
}

bool SVGPatternElement::isSupportedAttribute(const QualifiedName& attrName)
{
    DEFINE_STATIC_LOCAL(HashSet<QualifiedName>, supportedAttributes, ());
    if (supportedAttributes.isEmpty()) {
        SVGURIReference::addSupportedAttributes(supportedAttributes);
        SVGTests::addSupportedAttributes(supportedAttributes);
        SVGLangSpace::addSupportedAttributes(supportedAttributes);
        SVGExternalResourcesRequired::addSupportedAttributes(supportedAttributes);
        SVGFitToViewBox::addSupportedAttributes(supportedAttributes);
        supportedAttributes.add(SVGNames::patternUnitsAttr);
        supportedAttributes.add(SVGNames::patternContentUnitsAttr);
        supportedAttributes.add(SVGNames::patternTransformAttr);
        supportedAttributes.add(SVGNames::xAttr);
        supportedAttributes.add(SVGNames::yAttr);
        supportedAttributes.add(SVGNames::widthAttr);
        supportedAttributes.add(SVGNames::heightAttr);
    }
    return supportedAttributes.contains(attrName);
}

void SVGPatternElement::parseMappedAttribute(Attribute* attr)
{
    if (!isSupportedAttribute(attr->name())) {
        SVGStyledElement::parseMappedAttribute(attr);
        return;
    }

    if (attr->name() == SVGNames::patternUnitsAttr) {
        SVGUnitTypes::SVGUnitType propertyValue = SVGPropertyTraits<SVGUnitTypes::SVGUnitType>::fromString(attr->value());
        if (propertyValue > 0)
            setPatternUnitsBaseValue(propertyValue);
        return;
    }

    if (attr->name() == SVGNames::patternContentUnitsAttr) {
        SVGUnitTypes::SVGUnitType propertyValue = SVGPropertyTraits<SVGUnitTypes::SVGUnitType>::fromString(attr->value());
        if (propertyValue > 0)
            setPatternContentUnitsBaseValue(propertyValue);
        return;
    }

    if (attr->name() == SVGNames::patternTransformAttr) {
        SVGTransformList newList;
        if (!SVGTransformable::parseTransformAttribute(newList, attr->value()))
            newList.clear();

        detachAnimatedPatternTransformListWrappers(newList.size());
        setPatternTransformBaseValue(newList);
        return;
    }

    if (attr->name() == SVGNames::xAttr) {
        setXBaseValue(SVGLength(LengthModeWidth, attr->value()));
        return;
    }

    if (attr->name() == SVGNames::yAttr) {
        setYBaseValue(SVGLength(LengthModeHeight, attr->value()));
        return;
    }

    if (attr->name() == SVGNames::widthAttr) {
        setWidthBaseValue(SVGLength(LengthModeWidth, attr->value()));
        if (widthBaseValue().value(this) < 0)
            document()->accessSVGExtensions()->reportError("A negative value for pattern attribute <width> is not allowed");
        return;
    }

    if (attr->name() == SVGNames::heightAttr) {
        setHeightBaseValue(SVGLength(LengthModeHeight, attr->value()));
        if (heightBaseValue().value(this) < 0)
            document()->accessSVGExtensions()->reportError("A negative value for pattern attribute <height> is not allowed");
        return;
    }

    if (SVGURIReference::parseMappedAttribute(attr))
        return;
    if (SVGTests::parseMappedAttribute(attr))
        return;
    if (SVGLangSpace::parseMappedAttribute(attr))
        return;
    if (SVGExternalResourcesRequired::parseMappedAttribute(attr))
        return;
    if (SVGFitToViewBox::parseMappedAttribute(document(), attr))
        return;

    ASSERT_NOT_REACHED();
}

void SVGPatternElement::svgAttributeChanged(const QualifiedName& attrName)
{
    if (!isSupportedAttribute(attrName)) {
        SVGStyledElement::svgAttributeChanged(attrName);
        return;
    }

    SVGElementInstance::InvalidationGuard invalidationGuard(this);
    
    if (attrName == SVGNames::xAttr
        || attrName == SVGNames::yAttr
        || attrName == SVGNames::widthAttr
        || attrName == SVGNames::heightAttr)
        updateRelativeLengthsInformation();

    if (RenderObject* object = renderer())
        object->setNeedsLayout(true);
}

void SVGPatternElement::synchronizeProperty(const QualifiedName& attrName)
{    
    if (attrName == anyQName()) {
        synchronizePatternUnits();
        synchronizePatternContentUnits();
        synchronizePatternTransform();
        synchronizeX();
        synchronizeY();
        synchronizeWidth();
        synchronizeHeight();
        synchronizeExternalResourcesRequired();
        synchronizeHref();
        SVGFitToViewBox::synchronizeProperties(attrName);
        SVGTests::synchronizeProperties(this, attrName);
        SVGStyledElement::synchronizeProperty(attrName);
        return;
    }

    if (!isSupportedAttribute(attrName)) {
        SVGStyledElement::synchronizeProperty(attrName);
        return;
    }

    if (attrName == SVGNames::patternUnitsAttr) {
        synchronizePatternUnits();
        return;
    }

    if (attrName == SVGNames::patternContentUnitsAttr) {
        synchronizePatternContentUnits();
        return;
    }

    if (attrName == SVGNames::patternTransformAttr) {
        synchronizePatternTransform();
        return;
    }

    if (attrName == SVGNames::xAttr) {
        synchronizeX();
        return;
    }

    if (attrName == SVGNames::yAttr) {
        synchronizeY();
        return;
    }

    if (attrName == SVGNames::widthAttr) {
        synchronizeWidth();
        return;
    }

    if (attrName == SVGNames::heightAttr) {
        synchronizeHeight();
        return;
    }

    if (SVGExternalResourcesRequired::isKnownAttribute(attrName)) {
        synchronizeExternalResourcesRequired();
        return;
    }

    if (SVGFitToViewBox::isKnownAttribute(attrName)) {
        SVGFitToViewBox::synchronizeProperties(attrName);
        return;
    }

    if (SVGURIReference::isKnownAttribute(attrName)) {
        synchronizeHref();
        return;
    }

    if (SVGTests::isKnownAttribute(attrName)) {
        SVGTests::synchronizeProperties(this, attrName);
        return;
    }

    ASSERT_NOT_REACHED();
}

AttributeToPropertyTypeMap& SVGPatternElement::attributeToPropertyTypeMap()
{
    DEFINE_STATIC_LOCAL(AttributeToPropertyTypeMap, s_attributeToPropertyTypeMap, ());
    return s_attributeToPropertyTypeMap;
}

void SVGPatternElement::fillAttributeToPropertyTypeMap()
{
    AttributeToPropertyTypeMap& attributeToPropertyTypeMap = this->attributeToPropertyTypeMap();

    SVGStyledElement::fillPassedAttributeToPropertyTypeMap(attributeToPropertyTypeMap);
    attributeToPropertyTypeMap.set(SVGNames::xAttr, AnimatedLength);
    attributeToPropertyTypeMap.set(SVGNames::yAttr, AnimatedLength);
    attributeToPropertyTypeMap.set(SVGNames::widthAttr, AnimatedLength);
    attributeToPropertyTypeMap.set(SVGNames::heightAttr, AnimatedLength);
    attributeToPropertyTypeMap.set(SVGNames::patternUnitsAttr, AnimatedEnumeration);
    attributeToPropertyTypeMap.set(SVGNames::patternContentUnitsAttr, AnimatedEnumeration);
    attributeToPropertyTypeMap.set(SVGNames::patternTransformAttr, AnimatedTransformList);
    attributeToPropertyTypeMap.set(XLinkNames::hrefAttr, AnimatedString);
    attributeToPropertyTypeMap.set(SVGNames::viewBoxAttr, AnimatedRect);
    attributeToPropertyTypeMap.set(SVGNames::preserveAspectRatioAttr, AnimatedPreserveAspectRatio);
}

void SVGPatternElement::childrenChanged(bool changedByParser, Node* beforeChange, Node* afterChange, int childCountDelta)
{
    SVGStyledElement::childrenChanged(changedByParser, beforeChange, afterChange, childCountDelta);

    if (changedByParser)
        return;

    if (RenderObject* object = renderer())
        object->setNeedsLayout(true);
}

RenderObject* SVGPatternElement::createRenderer(RenderArena* arena, RenderStyle*)
{
    return new (arena) RenderSVGResourcePattern(this);
}

void SVGPatternElement::collectPatternAttributes(PatternAttributes& attributes) const
{
    HashSet<const SVGPatternElement*> processedPatterns;

    const SVGPatternElement* current = this;
    while (current) {
        if (!attributes.hasX() && current->hasAttribute(SVGNames::xAttr))
            attributes.setX(current->x());

        if (!attributes.hasY() && current->hasAttribute(SVGNames::yAttr))
            attributes.setY(current->y());

        if (!attributes.hasWidth() && current->hasAttribute(SVGNames::widthAttr))
            attributes.setWidth(current->width());

        if (!attributes.hasHeight() && current->hasAttribute(SVGNames::heightAttr))
            attributes.setHeight(current->height());

        if (!attributes.hasViewBox() && current->hasAttribute(SVGNames::viewBoxAttr))
            attributes.setViewBox(current->viewBox());

        if (!attributes.hasPreserveAspectRatio() && current->hasAttribute(SVGNames::preserveAspectRatioAttr))
            attributes.setPreserveAspectRatio(current->preserveAspectRatio());

        if (!attributes.hasBoundingBoxMode() && current->hasAttribute(SVGNames::patternUnitsAttr))
            attributes.setBoundingBoxMode(current->patternUnits() == SVGUnitTypes::SVG_UNIT_TYPE_OBJECTBOUNDINGBOX);

        if (!attributes.hasBoundingBoxModeContent() && current->hasAttribute(SVGNames::patternContentUnitsAttr))
            attributes.setBoundingBoxModeContent(current->patternContentUnits() == SVGUnitTypes::SVG_UNIT_TYPE_OBJECTBOUNDINGBOX);

        if (!attributes.hasPatternTransform() && current->hasAttribute(SVGNames::patternTransformAttr)) {
            AffineTransform transform;
            current->patternTransform().concatenate(transform);
            attributes.setPatternTransform(transform);
        }

        if (!attributes.hasPatternContentElement() && current->hasChildNodes())
            attributes.setPatternContentElement(current);

        processedPatterns.add(current);

        // Respect xlink:href, take attributes from referenced element
        Node* refNode = treeScope()->getElementById(SVGURIReference::getTarget(current->href()));
        if (refNode && refNode->hasTagName(SVGNames::patternTag)) {
            current = static_cast<const SVGPatternElement*>(const_cast<const Node*>(refNode));

            // Cycle detection
            if (processedPatterns.contains(current)) {
                current = 0;
                break;
            }
        } else
            current = 0;
    }
}

bool SVGPatternElement::selfHasRelativeLengths() const
{
    return x().isRelative()
        || y().isRelative()
        || width().isRelative()
        || height().isRelative();
}

}

#endif // ENABLE(SVG)
