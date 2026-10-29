//
//  MADFontDescriptor
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MAD_UIFontDescriptor__DocumentObject_h
#define Reports_MAD_UIFontDescriptor__DocumentObject_h

#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/NSFontDescriptor.h>
typedef NSFontDescriptor MADPlatformFontDescriptor;
@interface NSFontDescriptor (MADAdditions)
#else
#import <UIKit/UIFontDescriptor.h>
typedef UIFontDescriptor MADPlatformFontDescriptor;
@interface UIFontDescriptor (MADAdditions)
#endif

+ (instancetype)newFontDescriptorForFontName:(NSString *)fontname
									fontSize:(double)fontSize
										bold:(BOOL)bold
									  italic:(BOOL)italic;

@end

#endif
