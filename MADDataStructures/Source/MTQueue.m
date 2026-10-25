//
//  MTQueue.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueue.h"
#import <Foundation/NSArray.h>
#import "MTLinkedListNode.h"

@interface MTQueue ()

@property (nonatomic, strong) MTLinkedListNode *head;
@property (nonatomic, strong) MTLinkedListNode *tail;
@property (nonatomic, assign) NSUInteger counter;

@end

@implementation MTQueue

- (instancetype)init {
	if (self = [super init]) {
		_head = nil;
		_tail = nil;
		_counter = 0;
	}
	return self;
}

- (void)enqueue:(id)object {
	@synchronized(self) {
		MTLinkedListNode *newNode = [[MTLinkedListNode alloc] initWithData:object];
		if (self.tail) {
			self.tail.next = newNode;
			newNode.prev = self.tail;
		} else {
			// Queue is empty; the new node becomes both head and tail.
			self.head = newNode;
		}
		self.tail = newNode;
		self.counter++;
	}
}

- (id)dequeue {
	@synchronized(self) {
		if (!self.head) {
			return nil; // Queue is empty.
		}
		
		id dequeuedValue = self.head.data;
		self.head = self.head.next;
		if (self.head) {
			self.head.prev = nil;
		} else {
			// Queue becomes empty; tail also needs to be nil.
			self.tail = nil;
		}
		self.counter--;
		return dequeuedValue;
	}
}

- (NSUInteger)count {
	@synchronized(self) {
		return self.counter;
	}
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])stackbuf
									count:(NSUInteger)len {
	@synchronized(self) {
		MTLinkedListNode *currentNode = nil;
		
		// First call: Initialize mutationsPtr and start from head
		if (state->state == 0) {
			state->mutationsPtr = &_counter; // Track mutations via queue's counter
			state->state = 1; // Signal that enumeration has started
			currentNode = self.head;
		} else {
			// Subsequent calls: Resume from the last saved node
			currentNode = (__bridge MTLinkedListNode *)(void *)state->extra[0];
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
		
		return index; // Return the number of items added to the buffer
	}
}

- (NSString *)toStringHumanReadable { return nil; }

- (NSString *)toString { return nil; }

- (NSString *)toStringDebug { return nil; }

@end
