//
//  MADSchemaFieldSelectorModel.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
