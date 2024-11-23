//
//  MTLinkedListNode.h
//  MADDataStructures
//
//  Created by Michael on 11/23/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTLinkedListNode : NSObject

	@property (nonatomic, strong) id data;
	@property (nonatomic, strong, nullable) MTLinkedListNode *next;
	@property (nonatomic, strong, nullable) MTLinkedListNode *prev;

	- (instancetype)initWithData:(id)data;

@end

NS_ASSUME_NONNULL_END
