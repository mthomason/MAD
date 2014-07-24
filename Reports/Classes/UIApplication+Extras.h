//
//  UIApplication+Extras.h
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIApplication_Extras_h
#define Reports_UIApplication_Extras_h

#import <UIKit/UIKit.h>

@interface UIApplication (Extras)

+ (NSString *)version;
+ (BOOL)isMadDesigner;
+ (BOOL)isMadViewer;

- (void)startNetworkActivityIndicator;
- (void)stopNetworkActivityIndicator;

@end

#endif
