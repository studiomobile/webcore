/*
 * Copyright (C) 2006, 2007 Apple Inc. All rights reserved.
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
 *
 */

#include "config.h"
#include "RenderFileUploadControl.h"

#include "FileList.h"
#include "GraphicsContext.h"
#include "HTMLInputElement.h"
#include "HTMLNames.h"
#include "Icon.h"
#include "LocalizedStrings.h"
#include "PaintInfo.h"
#include "RenderButton.h"
#include "RenderText.h"
#include "RenderTheme.h"
#include "ShadowRoot.h"
#include "TextRun.h"
#include "VisiblePosition.h"
#include <math.h>

using namespace std;

namespace WebCore {

using namespace HTMLNames;

const int afterButtonSpacing = 4;
const int iconHeight = 16;
const int iconWidth = 16;
const int iconFilenameSpacing = 2;
const int defaultWidthNumChars = 34;
const int buttonShadowHeight = 2;

RenderFileUploadControl::RenderFileUploadControl(HTMLInputElement* input)
    : RenderBlock(input)
{
}

RenderFileUploadControl::~RenderFileUploadControl()
{
}

void RenderFileUploadControl::updateFromElement()
{
    if (HTMLInputElement* button = uploadButton())
        button->setDisabled(!theme()->isEnabled(this));
}

static int nodeWidth(Node* node)
{
    return node ? node->renderBox()->width() : 0;
}

int RenderFileUploadControl::maxFilenameWidth() const
{
    HTMLInputElement* input = static_cast<HTMLInputElement*>(node());
    return max(0, contentWidth() - nodeWidth(uploadButton()) - afterButtonSpacing
        - (input->icon() ? iconWidth + iconFilenameSpacing : 0));
}

void RenderFileUploadControl::paintObject(PaintInfo& paintInfo, const IntPoint& paintOffset)
{
    if (style()->visibility() != VISIBLE)
        return;
    
    // Push a clip.
    GraphicsContextStateSaver stateSaver(*paintInfo.context, false);
    if (paintInfo.phase == PaintPhaseForeground || paintInfo.phase == PaintPhaseChildBlockBackgrounds) {
        IntRect clipRect(paintOffset.x() + borderLeft(), paintOffset.y() + borderTop(),
                         width() - borderLeft() - borderRight(), height() - borderBottom() - borderTop() + buttonShadowHeight);
        if (clipRect.isEmpty())
            return;
        stateSaver.save();
        paintInfo.context->clip(clipRect);
    }

    if (paintInfo.phase == PaintPhaseForeground) {
        const String& displayedFilename = fileTextValue();
        const Font& font = style()->font();
        TextRun textRun = constructTextRun(this, font, displayedFilename, style(), TextRun::AllowTrailingExpansion, RespectDirection | RespectDirectionOverride);

        // Determine where the filename should be placed
        int contentLeft = paintOffset.x() + borderLeft() + paddingLeft();
        HTMLInputElement* button = uploadButton();
        if (!button)
            return;

        HTMLInputElement* input = static_cast<HTMLInputElement*>(node());
        int buttonWidth = nodeWidth(button);
        int buttonAndIconWidth = buttonWidth + afterButtonSpacing
            + (input->icon() ? iconWidth + iconFilenameSpacing : 0);
        int textX;
        if (style()->isLeftToRightDirection())
            textX = contentLeft + buttonAndIconWidth;
        else
            textX = contentLeft + contentWidth() - buttonAndIconWidth - font.width(textRun);
        // We want to match the button's baseline
        RenderButton* buttonRenderer = toRenderButton(button->renderer());
        int textY = buttonRenderer->absoluteBoundingBoxRect().y()
            + buttonRenderer->marginTop() + buttonRenderer->borderTop() + buttonRenderer->paddingTop()
            + buttonRenderer->baselinePosition(AlphabeticBaseline, true, HorizontalLine, PositionOnContainingLine);

        paintInfo.context->setFillColor(style()->visitedDependentColor(CSSPropertyColor), style()->colorSpace());
        
        // Draw the filename
        paintInfo.context->drawBidiText(font, textRun, IntPoint(textX, textY));
        
        if (input->icon()) {
            // Determine where the icon should be placed
            int iconY = paintOffset.y() + borderTop() + paddingTop() + (contentHeight() - iconHeight) / 2;
            int iconX;
            if (style()->isLeftToRightDirection())
                iconX = contentLeft + buttonWidth + afterButtonSpacing;
            else
                iconX = contentLeft + contentWidth() - buttonWidth - afterButtonSpacing - iconWidth;

            // Draw the file icon
            input->icon()->paint(paintInfo.context, IntRect(iconX, iconY, iconWidth, iconHeight));
        }
    }

    // Paint the children.
    RenderBlock::paintObject(paintInfo, paintOffset);
}

void RenderFileUploadControl::computePreferredLogicalWidths()
{
    ASSERT(preferredLogicalWidthsDirty());

    m_minPreferredLogicalWidth = 0;
    m_maxPreferredLogicalWidth = 0;

    RenderStyle* style = this->style();
    ASSERT(style);

    const Font& font = style->font();
    if (style->width().isFixed() && style->width().value() > 0)
        m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth = computeContentBoxLogicalWidth(style->width().value());
    else {
        // Figure out how big the filename space needs to be for a given number of characters
        // (using "0" as the nominal character).
        const UChar ch = '0';
        float charWidth = font.width(constructTextRun(this, font, String(&ch, 1), style, TextRun::AllowTrailingExpansion));
        m_maxPreferredLogicalWidth = (int)ceilf(charWidth * defaultWidthNumChars);
    }

    if (style->minWidth().isFixed() && style->minWidth().value() > 0) {
        m_maxPreferredLogicalWidth = max(m_maxPreferredLogicalWidth, computeContentBoxLogicalWidth(style->minWidth().value()));
        m_minPreferredLogicalWidth = max(m_minPreferredLogicalWidth, computeContentBoxLogicalWidth(style->minWidth().value()));
    } else if (style->width().isPercent() || (style->width().isAuto() && style->height().isPercent()))
        m_minPreferredLogicalWidth = 0;
    else
        m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth;

    if (style->maxWidth().isFixed() && style->maxWidth().value() != undefinedLength) {
        m_maxPreferredLogicalWidth = min(m_maxPreferredLogicalWidth, computeContentBoxLogicalWidth(style->maxWidth().value()));
        m_minPreferredLogicalWidth = min(m_minPreferredLogicalWidth, computeContentBoxLogicalWidth(style->maxWidth().value()));
    }

    int toAdd = borderAndPaddingWidth();
    m_minPreferredLogicalWidth += toAdd;
    m_maxPreferredLogicalWidth += toAdd;

    setPreferredLogicalWidthsDirty(false);
}

VisiblePosition RenderFileUploadControl::positionForPoint(const IntPoint&)
{
    return VisiblePosition();
}

HTMLInputElement* RenderFileUploadControl::uploadButton() const
{
    HTMLInputElement* input = static_cast<HTMLInputElement*>(node());

    ASSERT(input->shadowRoot());

    Node* buttonNode = input->shadowRoot()->firstChild();
    return buttonNode && buttonNode->isHTMLElement() && buttonNode->hasTagName(inputTag) ? static_cast<HTMLInputElement*>(buttonNode) : 0;
}

String RenderFileUploadControl::buttonValue()
{
    if (HTMLInputElement* button = uploadButton())
        return button->value();
    
    return String();
}

String RenderFileUploadControl::fileTextValue() const
{
    HTMLInputElement* input = static_cast<HTMLInputElement*>(node());
    ASSERT(input->files());
    return theme()->fileListNameForWidth(input->files()->filenames(), style()->font(), maxFilenameWidth());
}
    
} // namespace WebCore
