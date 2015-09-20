//
//  UIFont+Helpers.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/22/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIFont+Helpers.h"

@implementation UIFont (Helpers)

+ (void)LogFonts {
#if DEBUG
    for (NSString* family in [UIFont familyNames]) {
        NSLog(@"%@", family);
        
        for (NSString* name in [UIFont fontNamesForFamilyName: family]) {
            NSLog(@"  %@", name);
        }
    }
#endif
}

@end
