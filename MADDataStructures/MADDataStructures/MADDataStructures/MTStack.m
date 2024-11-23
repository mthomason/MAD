//
//  MTStack.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
	NSAssert(self.counter > 0, @"Underflow error. Nothing to pop.");
	id result = self.top.data;
	self.top = self.top.next; // Move the top pointer to the next node
	self.counter--;
	return result;
}

- (BOOL)isEmpty {
	return self.counter == 0;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])stackbuf
									count:(NSUInteger)len {
	// Handle initial state
	if (state->state == 0) {
		state->mutationsPtr = &state->extra[1];
		state->state = 1; // Indicate that enumeration has started
	}

	// Get the current node (using state->extra[0] to track position)
	MTStackNode *currentNode = (__bridge MTStackNode *)(void *)state->extra[0];
	if (!currentNode) {
		currentNode = self.top; // Start at the top of the stack
	}

	// Fill the buffer with elements
	NSUInteger count = 0;
	while (currentNode && count < len) {
		stackbuf[count] = currentNode.data;
		currentNode = currentNode.next;
		count++;
	}

	// Save the next node for subsequent calls
	state->extra[0] = (unsigned long)(__bridge void *)currentNode;

	// Return the number of objects filled in this call
	return count;
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
