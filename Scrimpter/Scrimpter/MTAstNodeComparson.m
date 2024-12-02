//
//  MTAstNodeComparson.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAstNodeComparson.h"
#import "MADValue.h"

@interface MTAstNodeComparson ()

@property (nonatomic, assign) SCCompareson comparsonType;

@end

@implementation MTAstNodeComparson

- (instancetype)initWithComparson:(SCCompareson)comparson ofValues:(MTPair *)values {
    self = [super initWithNodeType:SCNodeTypeComparison andValues:values];
    if (self) {
        [self setComparsonType:comparson];
    }
    return self;
}

- (MADValue *)evaluate {
    BOOL evalution;
    MADValue *left = [self.leftAST evaluate];
    MADValue *right = [self.rightAST evaluate];
    
    evalution = left.type == right.type;
    
    if (evalution) {    //If the types match...
        
        if (left.type == SCVarableTypeBoolean) {
            evalution = [self compareBoolean:[[left value] boolValue] withBoolean:[[right value] boolValue]];
            
        } else if (left.type == SCVarableTypeDouble) {
            evalution = [self compareDouble:[[left value] doubleValue] withDouble:[[right value] doubleValue]];
            
        } else if (left.type == SCVarableTypeString) {
            evalution = [self compareString:[left value] withString:[right value]];
            
        } else {    //both are null
            evalution = YES;
        }
    }
    
    NSNumber *bv = [NSNumber numberWithBool:evalution];
    return  [MADValue value:bv withType:SCVarableTypeBoolean];

}

- (bool)compareDouble:(double)dl withDouble:(double)dr {
    switch (self.comparsonType) {
        case SCComparesonGreaterThan:
            return dl > dr;
            break;
            
        case SCComparesonLessThan:
            return dl < dr;
            break;
            
        case SCComparesonEqualTo:
            return dl == dr;
            break;
            
        case SCComparesonNotEqualTo:
            return dl != dr;
            break;
            
        case SCComparesonGreatThanOrEqualTo:
            return dl >= dr;
            break;
            
        case SCComparesonLessThanOrEqualTo:
            return dl <= dr;
            break;

        default:
            return false;
            break;
    }
}

- (bool)compareString:(NSString *)sl withString:(NSString *)sr {
    switch ([sl compare:sr]) {
        case NSOrderedAscending:    //sl < sr
            return self.comparsonType == SCComparesonLessThan ||
                   self.comparsonType == SCComparesonLessThanOrEqualTo;
            break;
            
        case NSOrderedDescending:   //sl > sr
            return self.comparsonType == SCComparesonGreaterThan ||
                   self.comparsonType == SCComparesonGreatThanOrEqualTo;
            break;
            
        case NSOrderedSame:         //sl == sr
            return self.comparsonType == SCComparesonEqualTo ||
                     self.comparsonType == SCComparesonGreatThanOrEqualTo ||
                     self.comparsonType == SCComparesonLessThanOrEqualTo;
            break;
            
        default:
            NSAssert(false, @"Unknown order type");
            return false;
            break;
    }
}

- (bool)compareBoolean:(bool)dl withBoolean:(bool)dr {
    switch (self.comparsonType) {
        case SCComparesonGreaterThan:
            return dl > dr;
            break;
            
        case SCComparesonLessThan:
            return dl < dr;
            break;
            
        case SCComparesonEqualTo:
            return dl == dr;
            break;
            
        case SCComparesonNotEqualTo:
            return dl != dr;
            break;
            
        case SCComparesonGreatThanOrEqualTo:
            return dl >= dr;
            break;
            
        case SCComparesonLessThanOrEqualTo:
            return dl <= dr;
            break;
            
        default:
            return false;
            break;
    }
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"********* MTAstNodeComparson *********\n"];
    switch (self.comparsonType) {
        case SCComparesonGreaterThan:
            [description appendString:@"Greater Than"];
            break;
        case SCComparesonLessThan:
            [description appendString:@"Less Than"];
            break;
        case SCComparesonEqualTo:
            [description appendString:@"Equal To"];
            break;
        case SCComparesonNotEqualTo:
            [description appendString:@"Not Equal To"];
            break;
        case SCComparesonGreatThanOrEqualTo:
            [description appendString:@"Greater Than or Equal To"];
            break;
        case SCComparesonLessThanOrEqualTo:
            [description appendString:@"Less Than or Equal To"];
            break;
        default:
            [description appendString:@"Unknown"];
            break;
    }
    [description appendFormat:@"*********"];
    return description;
}

@end
