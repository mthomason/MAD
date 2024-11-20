//
//  MTTree.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MTTree_h
#define MAD_DataStructures_MTTree_h

#import <Foundation/NSObject.h>

#ifndef NS_DESIGNATED_INITIALIZER
  #if __has_attribute(objc_designated_initializer)
    #define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
  #else
    #define NS_DESIGNATED_INITIALIZER
  #endif
#endif

@interface MTTree : NSObject

@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) MTTree *leftNode;
@property (nonatomic, strong, nullable) MTTree *rightNode;

- (instancetype)initWithData:(nullable id)data
				  leftTree:(nullable MTTree *)left
				 rightTree:(nullable MTTree *)right NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithData:(nullable id)data;

- (void)insertLeft:(id)data;
- (void)insertRight:(id)data;

- (NSArray *)preOrderTraversal;   // Root -> Left -> Right
- (NSArray *)inOrderTraversal;    // Left -> Root -> Right
- (NSArray *)postOrderTraversal;  // Left -> Right -> Root

@end

#endif
