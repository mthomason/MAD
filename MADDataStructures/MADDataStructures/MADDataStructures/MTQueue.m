//
//  MTQueue.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
		if (state->state == 0) {
			state->mutationsPtr = &state->extra[0];
			state->state = 1;
			MTLinkedListNode *currentNode = self.head;
			NSUInteger index = 0;

			while (currentNode && index < len) {
				stackbuf[index] = currentNode.data;
				currentNode = currentNode.next;
				index++;
			}

			state->itemsPtr = stackbuf;
			return index;
		} else {
			return 0; // No more items to enumerate.
		}
	}
}

- (NSString *)toStringHumanReadable {
	return nil;
}

- (NSString *)toString {
	return nil;
}

- (NSString *)toStringDebug {
	return nil;
}

@end
