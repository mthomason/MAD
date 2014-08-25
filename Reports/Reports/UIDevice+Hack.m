//
//  UIDevice+Hack.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIDevice+Hack.h"

const int MTModernOSMajorVersion = 8;

@implementation UIDevice (Hack)

+ (NSUInteger)deviceSystemMajorVersion {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *versionComponents = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
        NSString *versionComponentMajor = versionComponents[0];
        _deviceSystemMajorVersion = [versionComponentMajor integerValue];
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
    return [UIDevice deviceSystemMajorVersion] < MTModernOSMajorVersion;
}

+ (BOOL)isModernOS {
    return [UIDevice deviceSystemMajorVersion] >= MTModernOSMajorVersion;
}

+ (BOOL)isRetnaDisplay {
    return [[UIScreen mainScreen] scale] > 1.5;
}

@end
