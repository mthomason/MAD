//
//  UIDevice+Hack.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDevice.h"

const int MTModernOSMajorVersion = 8;

@implementation MADDevice

+ (int)deviceSystemMajorVersion {
    NSArray *versionComponents = [[self currentDevice].systemVersion componentsSeparatedByString:@"."];
    NSString *versionComponentMajor = versionComponents[0];
    return [versionComponentMajor intValue];
}

+ (BOOL)isPad {
    static BOOL _isPad;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _isPad = [[self currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    });
    return _isPad;
}

+ (BOOL)isLagacyOS {
    return [self deviceSystemMajorVersion] < MTModernOSMajorVersion;
}

+ (BOOL)isModernOS {
    return [self deviceSystemMajorVersion] >= MTModernOSMajorVersion;
}

+ (BOOL)isRetnaDisplay {
    return [[UIScreen mainScreen] scale] > 1.5;
}

@end
