//
//  MTLinkedListNode.h
//  MADDataStructures
//
//  Created by Michael on 11/23/24.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MADDataStructures_MTLinkedListNode_h
#define MADDataStructures_MTLinkedListNode_h

#import <Foundation/NSObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTLinkedListNode : NSObject

@property (nonatomic, strong) id data;
@property (nonatomic, strong, nullable) MTLinkedListNode *next;
@property (nonatomic, strong, nullable) MTLinkedListNode *prev;

- (instancetype)initWithData:(id)data;

@end

NS_ASSUME_NONNULL_END

#endif
