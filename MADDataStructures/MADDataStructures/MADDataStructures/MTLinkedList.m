//
//  MNLinkedList.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2024 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTLinkedList.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

@interface MTLinkedListNode : NSObject

@property (nonatomic, strong) id data;
@property (nonatomic, strong) MTLinkedListNode *next;
@property (nonatomic, strong) MTLinkedListNode *prev;

- (instancetype)initWithData:(id)data;

@end

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
	_currentNode = _tailNode;
}

- (id)head {
	return _headNode ? _headNode.data : nil;
}

- (id)getNext {
	MTLinkedListNode *strongCurrentNode = _currentNode;
	if (strongCurrentNode && strongCurrentNode.next) {
		MTLinkedListNode *strongNextNode = strongCurrentNode.next;
		_currentNode = strongNextNode;
		return strongNextNode.data;
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
- (id)getTop {
	return _tailNode ? _tailNode.data : nil;
}

- (id)getBottom {
	return _headNode ? _headNode.data : nil;
}

- (BOOL)isNext {
	MTLinkedListNode *strongCurrentNode = _currentNode;
	return strongCurrentNode && strongCurrentNode.next;
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
		_headNode = temp.prev;
		_tailNode = temp;
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
	if (state->state >= _count) {
		return 0;
	}

	NSUInteger batchCount = 0;
	MTLinkedListNode *node = (state->state == 0) ? _headNode : (__bridge MTLinkedListNode *)(void *)state->extra[0];
	while (node && batchCount < len) {
		stackbuf[batchCount] = node.data;
		node = node.next;
		batchCount++;
	}

	state->state += batchCount;
	state->itemsPtr = stackbuf;
	state->mutationsPtr = &state->extra[1];
	state->extra[0] = (unsigned long)(__bridge void *)node;

	return batchCount;
}

@end
