//
//  UIDevice+Hack.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Hack)

+ (NSUInteger)deviceSystemMajorVersion;
+ (BOOL)isPad;

+ (BOOL)isLagacyOS;
+ (BOOL)isModernOS;
@end
