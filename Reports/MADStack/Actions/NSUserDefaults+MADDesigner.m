//
//  NSUserDefaults+MADDesigner.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/26/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSUserDefaults+MADDesigner.h"

static NSString * const MADAppConfigurationApplicationGroupsPrimary
                                                        = @"group.everydayapps.mad.primary";

@implementation NSUserDefaults (MADDesigner)

+ (instancetype)newUserDefaultsMADDesigner {
    NSUserDefaults *prefs;
    prefs = [[NSUserDefaults alloc] initWithSuiteName:MADAppConfigurationApplicationGroupsPrimary];
    return prefs;
}

@end
