//
//  UIDevice+Hack.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "UIDevice+Hack.h"

@implementation UIDevice (Hack)

+ (NSUInteger)deviceSystemMajorVersion {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
    });
    return _deviceSystemMajorVersion;
}

+ (BOOL)isPad {
    static BOOL _isPad;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    });
    return _isPad;
}

@end
