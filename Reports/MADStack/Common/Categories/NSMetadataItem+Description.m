//
//  NSMetadataItem+Description.m
//  MAD
//
//  Created by Michael Thomason on 3/22/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSMetadataItem+Description.h"

@implementation NSMetadataItem (Description)

- (NSString *)description {
    return [NSString stringWithFormat:@"<NSMetadataItem (\"%@\")>",
            [self valueForAttribute:NSMetadataItemFSNameKey]];
}

@end
