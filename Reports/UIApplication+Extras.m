//
//  UIApplication+Extras.m
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "UIApplication+Extras.h"

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

@end
