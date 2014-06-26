//
//  MTAstNodeComparson.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeComparson.h"

@interface MTAstNodeComparson ()

@property (nonatomic, assign) SCCompareson comparsonType;

@end

@implementation MTAstNodeComparson

- (id)initWithComparson:(SCCompareson)comparson ofValues:(MTPair *)values {
    self = [super initWithNodeType:SCNodeTypeComparison andValues:values];
    if (self) {
        [self setComparsonType:comparson];
    }
    return self;
}

- (BOOL)evaluate {
    BOOL evalution;
    switch (self.comparsonType) {
        case SCComparesonGreaterThan:
            evalution = self.leftNode.evaluate > self.rightNode.evaluate;
            break;
            
        case SCComparesonLessThan:
            evalution = self.leftNode.evaluate < self.rightNode.evaluate;
            break;
            
        case SCComparesonEqualTo:
            evalution = self.leftNode.evaluate == self.rightNode.evaluate;
            break;
            
        case SCComparesonNotEqualTo:
            evalution = self.leftNode.evaluate != self.rightNode.evaluate;
            break;
            
        case SCComparesonGreatThanOrEqualTo:
            evalution = self.leftNode.evaluate >= self.rightNode.evaluate;
            break;
            
        case SCComparesonLessThanOrEqualTo:
            evalution = self.leftNode.evaluate <= self.rightNode.evaluate;
            break;
            
        default:
            evalution = false;
            break;
    }
    return evalution;

}

@end
