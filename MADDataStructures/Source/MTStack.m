//
//  MTStack.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTStack.h"
#import <Foundation/NSException.h>

@interface MTStackNode : NSObject

@property (nonatomic, strong) id data;
@property (nonatomic, strong, nullable) MTStackNode *next;

- (instancetype)initWithData:(id)data;

@end

@implementation MTStackNode

- (instancetype)initWithData:(id)data {
	if (self = [super init]) {
		_data = data;
		_next = nil;
	}
	return self;
}

@end

@interface MTStack ()

@property (nonatomic, strong, nullable) MTStackNode *top;
@property (nonatomic, assign) NSUInteger counter;

@end

@implementation MTStack

- (instancetype)init {
	if (self = [super init]) {
		_top = nil;
		_counter = 0;
	}
	return self;
}

- (instancetype)initWithObject:(id)object {
	if (self = [super init]) {
		MTStackNode *node = [[MTStackNode alloc] initWithData:object];
		_top = node;
		_counter = 1;
	}
	return self;
}

- (void)push:(id)object {
	MTStackNode *newNode = [[MTStackNode alloc] initWithData:object];
	newNode.next = self.top;
	self.top = newNode;
	self.counter++;
}

- (id)pop {
	id result = nil;
	if (!self.isEmpty) {
		result = self.top.data;
		self.top = self.top.next;
		self.counter--;
	}
	return result;
}

- (BOOL)isEmpty {
	return self.counter == 0;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								 objects:(id __unsafe_unretained [])stackbuf
								   count:(NSUInteger)len {
	@synchronized(self) {
		MTStackNode *currentNode = nil;
		
		// First call: Initialize mutationsPtr and start from top
		if (state->state == 0) {
			state->mutationsPtr = &_counter; // Track mutations via the stack's counter
			state->state = 1; // Signal enumeration has started
			currentNode = self.top;
		} else {
			// Subsequent calls: Resume from the last saved node
			currentNode = (__bridge MTStackNode *)(void *)state->extra[0];
		}
		
		NSUInteger index = 0;
		// Fill the buffer with up to 'len' items from the current node
		while (currentNode && index < len) {
			stackbuf[index] = currentNode.data;
			currentNode = currentNode.next;
			index++;
		}
		
		// Save the current node for the next iteration (even if nil)
		state->extra[0] = (unsigned long)(__bridge void *)currentNode;
		state->itemsPtr = stackbuf;
		
		return index; // Number of items added to the buffer
	}
}

- (NSString *)toStringHumanReadable {
	return nil;
}

- (NSString *)toString {
	return nil;
}

- (NSString *)toStringDebug {
	return [NSString stringWithFormat:@"%@", self];
}

@end
