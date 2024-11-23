//
//  MTLinkedListNode.m
//  MADDataStructures
//
//  Created by Michael on 11/23/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
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
