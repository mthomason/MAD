//
//  UIApplication+Extras.h
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Extras)

+ (NSString *)version;
+ (BOOL)isMadDesigner;
+ (BOOL)isMadViewer;

@end
