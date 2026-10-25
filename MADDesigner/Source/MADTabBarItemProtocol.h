//
//  MADTabBarItemProtocol.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADTabBarItemProtocol_h
#define MAD_MADTabBarItemProtocol_h

#import <Foundation/NSObject.h>

@class UIImage, NSString;

@protocol MADTabBarImageProtocol <NSObject>

@required
+ (UIImage *)TabBarImage;
@optional
+ (NSString *)Title;

@end

#endif /* MADTabBarItemProtocol_h */
