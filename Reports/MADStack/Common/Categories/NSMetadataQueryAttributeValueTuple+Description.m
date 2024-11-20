//
//  NSMetadataQueryAttributeValueTuple+Description.m
//  MAD
//
//  Created by Michael Thomason on 3/23/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSMetadataQueryAttributeValueTuple+Description.h"
#import <Foundation/NSString.h>

@implementation NSMetadataQueryAttributeValueTuple (Description)

- (NSString *)description {
    return [NSString stringWithFormat:@"<NSMetadataQueryResultGroup (\"%@\":\"%@\")>",
            self.attribute, self.value];
}

@end
