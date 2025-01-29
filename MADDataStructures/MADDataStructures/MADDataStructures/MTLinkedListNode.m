//
//  MTLinkedListNode.m
//  MADDataStructures
//
//  Created by Michael on 11/23/24.
//  Copyright © 2025 Michael Thomason. All rights reserved.
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
