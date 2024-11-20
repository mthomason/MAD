//
//  NSMetadataItem+Description.m
//  MAD
//
//  Created by Michael Thomason on 3/22/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSMetadataItem+Description.h"
#import <Foundation/NSString.h>

@implementation NSMetadataItem (Description)

- (NSString *)description {
    return [NSString stringWithFormat:@"<NSMetadataItem (\"%@\")>",
            [self valueForAttribute:NSMetadataItemFSNameKey]];
}

@end
