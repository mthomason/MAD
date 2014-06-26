//
//  MTAstNodeComparson.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeComparson.h"
#import "MADValue.h"

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

- (MADValue *)evaluate {
    BOOL evalution;
    MADValue *left = self.leftNode.evaluate;
    MADValue *right = self.rightNode.evaluate;
    double dl = [[left value] doubleValue];
    double dr = [[right value] doubleValue];

    switch (self.comparsonType) {
        case SCComparesonGreaterThan:
            evalution = dl > dr;
            break;
            
        case SCComparesonLessThan:
            evalution = dl < dr;
            break;
            
        case SCComparesonEqualTo:
            evalution = dl == dr;
            break;
            
        case SCComparesonNotEqualTo:
            evalution = dl != dr;
            break;
            
        case SCComparesonGreatThanOrEqualTo:
            evalution = dl >= dr;
            break;
            
        case SCComparesonLessThanOrEqualTo:
            evalution = dl <= dr;
            break;
            
        default:
            evalution = false;
            break;
    }
    NSNumber *bv = [NSNumber numberWithBool:evalution];
    return  [MADValue value:bv withType:SCVarableTypeBoolean];

}

@end
