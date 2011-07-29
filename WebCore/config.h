/*
 * Copyright (C) 2004, 2005, 2006 Apple Inc.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#if defined(HAVE_CONFIG_H) && HAVE_CONFIG_H
#ifdef BUILDING_WITH_CMAKE
#include "cmakeconfig.h"
#else
#include "autotoolsconfig.h"
#endif
#endif

#include <wtf/Platform.h>

/* See note in wtf/Platform.h for more info on EXPORT_MACROS. */
#if USE(EXPORT_MACROS)

#include <wtf/ExportMacros.h>

#if defined(BUILDING_JavaScriptCore) || defined(BUILDING_WTF)
#define WTF_EXPORT_PRIVATE WTF_EXPORT
#define JS_EXPORT_PRIVATE WTF_EXPORT
#else
#define WTF_EXPORT_PRIVATE WTF_IMPORT
#define JS_EXPORT_PRIVATE WTF_IMPORT
#endif

#define JS_EXPORTDATA JS_EXPORT_PRIVATE
#define JS_EXPORTCLASS JS_EXPORT_PRIVATE

#define WEBKIT_EXPORTDATA WTF_EXPORT

#else /* !USE(EXPORT_MACROS) */

#if !PLATFORM(CHROMIUM) && OS(WINDOWS) && !defined(BUILDING_WX__) && !COMPILER(GCC)
#if defined(BUILDING_JavaScriptCore) || defined(BUILDING_WTF)
#define JS_EXPORTDATA __declspec(dllexport)
#else
#define JS_EXPORTDATA __declspec(dllimport)
#endif
#if defined(BUILDING_WebCore) || defined(BUILDING_WebKit)
#define WEBKIT_EXPORTDATA __declspec(dllexport)
#else
#define WEBKIT_EXPORTDATA __declspec(dllimport)
#endif
#define WTF_EXPORT_PRIVATE
#define JS_EXPORT_PRIVATE
#define JS_EXPORTCLASS JS_EXPORTDATA
#else
#define JS_EXPORTDATA
#define JS_EXPORTCLASS
#define WEBKIT_EXPORTDATA
#define WTF_EXPORT_PRIVATE
#define JS_EXPORT_PRIVATE
#endif

#endif /* USE(EXPORT_MACROS) */

#ifdef __APPLE__
#define HAVE_FUNC_USLEEP 1
#endif /* __APPLE__ */

#ifdef __cplusplus

// These undefs match up with defines in WebCorePrefix.h for Mac OS X.
// Helps us catch if anyone uses new or delete by accident in code and doesn't include "config.h".
#undef new
#undef delete
#include <wtf/FastMalloc.h>

#endif

// this breaks compilation of <QFontDatabase>, at least, so turn it off for now
// Also generates errors on wx on Windows, presumably because these functions
// are used from wx headers. On GTK+ for Mac many GTK+ files include <libintl.h>
// or <glib/gi18n-lib.h>, which in turn include <xlocale/_ctype.h> which uses
// isacii(). 
#if !PLATFORM(QT) && !PLATFORM(WX) && !PLATFORM(CHROMIUM) && !(OS(DARWIN) && PLATFORM(GTK))
#include <wtf/DisallowCType.h>
#endif

#if COMPILER(MSVC)
#define SKIP_STATIC_CONSTRUCTORS_ON_MSVC 1
#elif !COMPILER(WINSCW)
#define SKIP_STATIC_CONSTRUCTORS_ON_GCC 1
#endif

#if PLATFORM(MAC)
// New theme
#define WTF_USE_NEW_THEME 1
#endif // PLATFORM(MAC)

#if OS(UNIX) || OS(WINDOWS)
#define WTF_USE_OS_RANDOMNESS 1
#endif

#if USE(CG)
#ifndef CGFLOAT_DEFINED
#ifdef __LP64__
typedef double CGFloat;
#else
typedef float CGFloat;
#endif
#define CGFLOAT_DEFINED 1
#endif
#endif /* USE(CG) */


// CoreAnimation is available to IOS, Mac and Windows if using CG
#if PLATFORM(MAC) || PLATFORM(IOS) || (PLATFORM(WIN) && USE(CG))
#define WTF_USE_CA 1
#endif

#define USE_SYSTEM_MALLOC 1

#define NULL_METHOD_RESULT(...) NULL


#define ENABLE_SVG 1
