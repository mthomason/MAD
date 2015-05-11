//
//  MTTree.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif

@interface MTTree : NSObject

@property (nonatomic, strong) MTTree *leftNode;
@property (nonatomic, strong) MTTree *rightNode;

- (instancetype)initWithLeftTree:(MTTree *)left andRightTree:(MTTree *)right NS_DESIGNATED_INITIALIZER;

@end
