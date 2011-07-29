/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "ShadowContentElement.h"

#include "HTMLNames.h"
#include "ShadowContentSelector.h"

namespace WebCore {

PassRefPtr<ShadowContentElement> ShadowContentElement::create(Document* document)
{
    DEFINE_STATIC_LOCAL(QualifiedName, tagName, (nullAtom, "webkitShadowContent", HTMLNames::divTag.namespaceURI()));
    return adoptRef(new ShadowContentElement(tagName, document));
}

ShadowContentElement::ShadowContentElement(const QualifiedName& name, Document* document)
    : StyledElement(name, document, CreateHTMLElement)
{
}

ShadowContentElement::~ShadowContentElement()
{
}

void ShadowContentElement::attach()
{
    ASSERT(!firstChild()); // Currently doesn't support any light child.
    StyledElement::attach();
    if (ShadowContentSelector* selector = ShadowContentSelector::currentInstance()) {
        selector->willAttachContentFor(this);
        selector->selectInclusion(m_inclusions);
        for (size_t i = 0; i < m_inclusions.size(); ++i)
            m_inclusions[i]->detach();
        for (size_t i = 0; i < m_inclusions.size(); ++i)
            m_inclusions[i]->attach();
        selector->didAttachContent();
    }
}

void ShadowContentElement::detach()
{
    m_inclusions.clear();
    StyledElement::detach();
}

bool ShadowContentElement::shouldInclude(Node*)
{
    return true;
}

}