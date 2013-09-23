//
//  UIApplication+Extras.m
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "UIApplication+Extras.h"
#import "AppDelegate.h"

@implementation UIApplication (Extras)

+ (NSString *)version {
    static NSString *version;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        version = [infoDict objectForKey:@"CFBundleVersion"];
    });
    return version;
}

+ (BOOL)isMadDesigner {
    static BOOL isMadDesigner;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isMadDesigner = [[AppDelegate bundleId] isEqualToString:MTBundleIdDesigner];
    });
    return isMadDesigner;
}

+ (BOOL)isMadViewer {
    static BOOL isMadViewer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isMadViewer = [[AppDelegate bundleId] isEqualToString:MTBundleIdViewer];
    });
    return isMadViewer;
}

@end
