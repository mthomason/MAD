//
//  MTTree.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTTree.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>

@implementation MTTree

- (instancetype)init {
	return [self initWithData:nil leftTree:nil rightTree:nil];
}

- (instancetype)initWithData:(nullable id)data
				   leftTree:(nullable MTTree *)left
				  rightTree:(nullable MTTree *)right {
	if (self = [super init]) {
		self.data = data;
		self.leftNode = left;
		self.rightNode = right;
	}
	return self;
}

- (instancetype)initWithData:(nullable id)data {
	return [self initWithData:data leftTree:nil rightTree:nil];
}

#pragma mark - Insertion Methods

- (void)insertLeft:(id)data {
	if (!self.leftNode) {
		self.leftNode = [[MTTree alloc] initWithData:data];
	} else {
		MTTree *newNode = [[MTTree alloc] initWithData:data];
		newNode.leftNode = self.leftNode;
		self.leftNode = newNode;
	}
}

- (void)insertRight:(id)data {
	if (!self.rightNode) {
		self.rightNode = [[MTTree alloc] initWithData:data];
	} else {
		MTTree *newNode = [[MTTree alloc] initWithData:data];
		newNode.rightNode = self.rightNode;
		self.rightNode = newNode;
	}
}

#pragma mark - Tree Traversal

- (NSArray *)preOrderTraversal {
	NSMutableArray *result = [NSMutableArray array];
	[result addObject:self.data ?: [NSNull null]];
	if (self.leftNode) {
		NSArray *leftTraversal = [self.leftNode preOrderTraversal] ?: @[];
		[result addObjectsFromArray:leftTraversal];
	}
	if (self.rightNode) {
		NSArray *rightTraversal = [self.rightNode preOrderTraversal] ?: @[];
		[result addObjectsFromArray:rightTraversal];
	}
	return result;
}

- (NSArray *)inOrderTraversal {
	NSMutableArray *result = [NSMutableArray array];
	if (self.leftNode) {
		NSArray *leftTraversal = [self.leftNode inOrderTraversal] ?: @[];
		[result addObjectsFromArray:leftTraversal];
	}
	[result addObject:self.data ?: [NSNull null]];
	if (self.rightNode) {
		NSArray *rightTraversal = [self.rightNode inOrderTraversal] ?: @[];
		[result addObjectsFromArray:rightTraversal];
	}
	return result;
}

- (NSArray *)postOrderTraversal {
	NSMutableArray *result = [NSMutableArray array];
	if (self.leftNode) {
		NSArray *leftTraversal = [self.leftNode postOrderTraversal] ?: @[];
		[result addObjectsFromArray:leftTraversal];
	}
	if (self.rightNode) {
		NSArray *rightTraversal = [self.rightNode postOrderTraversal] ?: @[];
		[result addObjectsFromArray:rightTraversal];
	}
	[result addObject:self.data ?: [NSNull null]];
	return result;
}
@end
