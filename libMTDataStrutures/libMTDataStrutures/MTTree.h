//
//  MTTree.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTTree : NSObject

@property (nonatomic, strong) MTTree *leftNode;
@property (nonatomic, strong) MTTree *rightNode;

- (id)initWithLeftTree:(MTTree *)left andRightTree:(MTTree *)right;

@end
