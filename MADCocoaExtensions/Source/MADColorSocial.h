//
//  MADColorSocial.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_CocoaExtensions_MADColorSocial_h
#define MAD_CocoaExtensions_MADColorSocial_h

#import <MADCocoaExtensions/MADColor.h>
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
#import <AppKit/NSColor.h>
#else
#import <UIKit/UIColor.h>
#endif

@interface MADColorSocial : MADColor

// Returns a plain platform color: newColorWitColors() builds a UIColor/NSColor, not a MADColor.
+ (MADPlatformColor *)newBlueTwitter;

@end

#endif
