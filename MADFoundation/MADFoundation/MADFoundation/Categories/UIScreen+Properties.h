//
//  UIScreen+Properties.h
//  MADFoundation
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Foundation_UIScreen_Properties_h
#define MAD_Foundation_UIScreen_Properties_h

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST || TARGET_OS_IOS
#import <UIKit/UIKit.h>
@interface UIScreen (Properties)
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
@interface NSScreen (Properties)
#endif

- (BOOL)isRetinaDisplay;

@end

#endif

