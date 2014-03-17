//
//  UIDevice+Hack.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIDevice+Hack.h"

const int MTModernOSMajorVersion = 7;

@implementation UIDevice (Hack)

+ (NSUInteger)deviceSystemMajorVersion {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
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

+ (BOOL)isLagacyOS {
    static BOOL _isLagacyOS;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _isLagacyOS = [UIDevice deviceSystemMajorVersion] < MTModernOSMajorVersion;
    });
    return _isLagacyOS;
}

+ (BOOL)isModernOS {
    static BOOL _isModernOS;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _isModernOS = [UIDevice deviceSystemMajorVersion] >= MTModernOSMajorVersion;
    });
    return _isModernOS;
}

+ (BOOL)isRetnaDisplay {
    static BOOL _retnaDisplay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _retnaDisplay = [[UIScreen mainScreen] scale] > 1.5;
    });
    return _retnaDisplay;
}

@end
