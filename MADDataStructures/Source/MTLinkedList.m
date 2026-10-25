//
//  MNLinkedList.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTLinkedList.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import "MTLinkedListNode.h"

@interface MTLinkedList ()

	@property (nonatomic, strong) MTLinkedListNode *headNode;
	@property (nonatomic, strong) MTLinkedListNode *tailNode;
	@property (nonatomic) NSUInteger count;
	@property (nonatomic, weak) MTLinkedListNode *currentNode;

@end

@implementation MTLinkedList

- (instancetype)init {
	if (self = [super init]) {
		_headNode = nil;
		_tailNode = nil;
		_currentNode = nil;
		_count = 0;
	}
	return self;
}

- (void)insert:(id)object {
	if (!object) return;

	MTLinkedListNode *newNode = [[MTLinkedListNode alloc] initWithData:object];
	if (!_headNode) {
		_headNode = _tailNode = newNode;
	} else {
		newNode.next = _headNode;
		_headNode.prev = newNode;
		_headNode = newNode;
	}
	_count++;
}

- (void)add:(id)object {
	if (!object) return;

	MTLinkedListNode *newNode = [[MTLinkedListNode alloc] initWithData:object];
	if (!_tailNode) {
		_headNode = _tailNode = newNode;
	} else {
		newNode.prev = _tailNode;
		_tailNode.next = newNode;
		_tailNode = newNode;
	}
	_count++;

	if (!_currentNode) {
		_currentNode = _headNode;
	}
}

- (id)head {
	return _headNode ? _headNode.data : nil;
}

- (id)getNext {
	MTLinkedListNode *strongCurrentNode = _currentNode;
	if (!strongCurrentNode) {
		_currentNode = _headNode;
		strongCurrentNode = _headNode;
	}
	if (strongCurrentNode && strongCurrentNode.next) {
		_currentNode = strongCurrentNode.next;
		MTLinkedListNode *resultNode = _currentNode;
		return resultNode.data;
	}
	return nil;
}

- (id)getPrevious {
	MTLinkedListNode *strongCurrentNode = _currentNode;
	if (strongCurrentNode && strongCurrentNode.prev) {
		MTLinkedListNode *strongPrevNode = strongCurrentNode.prev;
		_currentNode = strongPrevNode;
		return strongPrevNode.data;
	}
	return nil;
}

- (id)getTop { return _headNode ? _headNode.data : nil; }

- (id)getBottom { return _tailNode ? _tailNode.data : nil; }

- (BOOL)isNext {
	MTLinkedListNode *strongCurrentNode = _currentNode;
	if (!strongCurrentNode) {
		return _headNode != nil;
	}
	return strongCurrentNode.next != nil;
}

- (BOOL)isPrevious {
	MTLinkedListNode *strongCurrentNode = _currentNode;
	return strongCurrentNode && strongCurrentNode.prev;
}

- (id)objectAtIndex:(NSUInteger)index {
	if (index >= _count) return nil;

	MTLinkedListNode *node = _headNode;
	for (NSUInteger i = 0; i < index; i++) {
		node = node.next;
	}
	return node.data;
}

- (void)reverse {
	MTLinkedListNode *current = _headNode;
	MTLinkedListNode *temp = nil;

	while (current) {
		temp = current.prev;
		current.prev = current.next;
		current.next = temp;
		current = current.prev;
	}

	if (temp) {
		_tailNode = _headNode;
		_headNode = temp.prev;
	}
}

- (NSArray *)toArray {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:_count];
	MTLinkedListNode *node = _headNode;
	while (node) {
		[array addObject:node.data];
		node = node.next;
	}
	return [array copy];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])stackbuf
									count:(NSUInteger)len {
	if (state->state >= self.count) {
		return 0;
	}

	state->mutationsPtr = &_count;

	NSUInteger batchCount = 0;
	MTLinkedListNode *node = (state->state == 0) ?
		_headNode :
		(__bridge MTLinkedListNode *)(void *)state->extra[0];

	while (node && batchCount < len) {
		stackbuf[batchCount] = node.data;
		node = node.next;
		batchCount++;
	}

	state->state += batchCount;
	state->itemsPtr = stackbuf;
	state->extra[0] = (unsigned long)(__bridge void *)node;

	return batchCount;
}

@end
