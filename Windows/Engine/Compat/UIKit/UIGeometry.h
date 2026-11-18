//
//  UIGeometry.h
//  Linux/Compat/UIKit
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  UIKit's geometry header is CoreGraphics' geometry plus a couple of
//  aliases; off Apple the frameworks that import it use only CGPoint, CGSize
//  and CGRect (docs/project/MAD_LINUX.md §5.2: the geometry tail is plain struct math).
//  UIEdgeInsets lives in the CoreGraphics shim beside this one.
//

#ifndef MADCompat_UIKit_UIGeometry_h
#define MADCompat_UIKit_UIGeometry_h

#if !__APPLE__
#import <CoreGraphics/CGGeometry.h>
#import <Foundation/NSGeometry.h>
#endif

#endif /* MADCompat_UIKit_UIGeometry_h */
