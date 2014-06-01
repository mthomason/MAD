//
//  UIApplication+Extras.m
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "UIApplication+Extras.h"
#import "MTApplicationInstance.h"
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
    return [[MTApplicationInstance bundleId] isEqualToString:MTBundleIdDesigner];
}

+ (BOOL)isMadViewer {
    return [[MTApplicationInstance bundleId] isEqualToString:MTBundleIdViewer];
}

@end
