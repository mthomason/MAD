//
//  MADSchemaFieldSelectorModel.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADSchemaFieldSelectorModel.h"

@implementation MADSchemaFieldSelectorModel

- (instancetype)init {
    if (self = [super init]) {
        _open = NO;
    }
    return self;
}

@end
