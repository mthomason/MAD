//
//  MTLinkedListNode.m
//  MADDataStructures
//
//  Created by Michael on 11/23/24.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTLinkedListNode.h"

@implementation MTLinkedListNode

- (instancetype)initWithData:(id)data {
	if (self = [super init]) {
		_data = data;
		_next = nil;
		_prev = nil;
	}
	return self;
}

@end
