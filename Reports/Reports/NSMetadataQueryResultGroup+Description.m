//
//  NSMetadataQueryResultGroup+Description.m
//  MAD
//
//  Created by Michael Thomason on 3/23/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSMetadataQueryResultGroup+Description.h"

@implementation NSMetadataQueryResultGroup (Description)

- (NSString *)description {
    return [NSString stringWithFormat:@"<NSMetadataQueryResultGroup (\"%@\")>",
            [self value]];
}

@end
