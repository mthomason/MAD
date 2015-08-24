//
//  MTAstNodeEmbeddedFunctionCall.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeFunctionCallEmbedded.h"
#import "MTPair.h"
#import "MADValue.h"

@interface MTAstNodeFunctionCallEmbedded ()

@property (nonatomic, strong) NSString *functionName;
@property (nonatomic, assign) SCFunctionClass class;
@property (nonatomic, assign) NSUInteger function;


@end

@implementation MTAstNodeFunctionCallEmbedded

- (id)initWithExpression:(MTAbstractSyntaxTree *)expression functionName:(NSString *)functionName andExpressionList:(MTAbstractSyntaxTree *)expressionList {
    MTPair *pair = [MTPair pairWithLeft:expression andRight:expressionList];
    self = [super initWithNodeType:SCNodeTypeBuiltInFunction andValues:pair];
    if (self) {
        NSString *fn = [NSString stringWithString:functionName];
        [self setFunctionName:fn];

        if ([functionName isEqualToString:@"concat"] || [functionName isEqualToString:@"concatenate"]) {

            [self setClass:SCFunctionClassString];
            [self setFunction:SCFunctionTypeStringConcat];
            
        } else if ([functionName isEqualToString:@"upper"]) {
            
            [self setClass:SCFunctionClassString];
            [self setFunction:SCFunctionTypeStringUpper];
            
        } else if ([functionName isEqualToString:@"lower"]) {

            [self setClass:SCFunctionClassString];
            [self setFunction:SCFunctionTypeStringLower];
            
        } else if ([functionName isEqualToString:@"power"]) {

            [self setClass:SCFunctionClassNumber];
            [self setFunction:SCFunctionTypeNumericPower];
            
        } else if ([functionName isEqualToString:@"floor"]) {
            
            [self setClass:SCFunctionClassNumber];
            [self setFunction:SCFunctionTypeNumericFloor];
            
        } else if ([functionName isEqualToString:@"ceiling"]) {
            
            [self setClass:SCFunctionClassNumber];
            [self setFunction:SCFunctionTypeNumericCeiling];
        
        } else if ([functionName isEqualToString:@"truncate"]) {
            
            [self setClass:SCFunctionClassNumber];
            [self setFunction:SCFunctionTypeNumericTruncate];

        } else if ([functionName isEqualToString:@"mod"]) {
        
            [self setClass:SCFunctionClassNumber];
            [self setFunction:SCFunctionTypeNumericModulus];

        } else if ([functionName isEqualToString:@"round"]) {

            [self setClass:SCFunctionClassNumber];
            [self setFunction:SCFunctionTypeNumericRound];

        }
    }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeBuiltInFunction;
}

- (MADValue *)evaluate {
    MADValue *result;
    switch ([self class]) {
        case SCFunctionClassBoolean:
            result = [self evaluateBoolean];
            break;
        case SCFunctionClassString:
            result = [self evaluateString];
            break;
        case SCFunctionClassNumber:
            result = [self evaluateNumber];
            break;
        default:
            result = [MADValue value:nil withType:SCVarableTypeNull];
            break;
    }
    return result;
}

- (MADValue *)evaluateNumber {
    MADValue *result;
    MADValue *baseWrapper = [[self leftNode] evaluate];
    double base = [baseWrapper doubleValue];
    double r = 0;
    if (base != NAN) {

        switch ((SCFunctionTypeNumber)[self function]) {
                
            case SCFunctionTypeNumericPower: {
                MADValue *exponantWrapper = [[self rightNode] evaluate];
                double exponant = [exponantWrapper doubleValue];
                r = exponant != NAN ? pow(base, exponant) : NAN;
                break;
            }
                
            case SCFunctionTypeNumericCeiling:
                r = ceil(base);
                break;
                
            case SCFunctionTypeNumericFloor:
                r = floor(base);
                break;

            case SCFunctionTypeNumericTruncate:
                r = trunc(base);
                break;
                
            case SCFunctionTypeNumericRound:
                r = round(base);
                break;

            case SCFunctionTypeNumericModulus: {
                MADValue *exponantWrapper = [[self rightNode] evaluate];
                double divisor = [exponantWrapper doubleValue];
                r = divisor != NAN ? fmod(base, divisor) : NAN;
                break;
            }
                
            default:
                break;
        }
    } else {
        r = NAN;
    }
    if (isnan(r)) {
        result = [MADValue value:nil withType:SCVarableTypeNull];
    } else {
        result = [MADValue value:[NSNumber numberWithDouble:r]
                        withType:SCVarableTypeDouble];
    }
    return result;
}

- (MADValue *)evaluateString {
    
    NSString *rs;
    switch ((SCFunctionTypeString)[self function]) {
        
        case SCFunctionTypeStringConcat:
            rs = [[[[self leftNode] evaluate] stringValue] stringByAppendingString:[[[self rightNode] evaluate] stringValue]];
            break;
        
        case SCFunctionTypeStringLower:
            rs = [[[[self leftNode] evaluate] stringValue] lowercaseString];
            break;

        case SCFunctionTypeStringUpper:
            rs = [[[[self leftNode] evaluate] stringValue] uppercaseString];
            break;
            
        default:
            rs = [[[self leftNode] evaluate] stringValue];
            break;
    }
    return [MADValue value: rs
                  withType: SCVarableTypeString];
}

- (MADValue *)evaluateBoolean {
    return nil;
}

+ (MADValue *)uniaryMinus:(MADValue *)value {
    NSNumber *um = [NSNumber numberWithDouble: -[[value value] doubleValue]];
    return [MADValue value:um withType:SCVarableTypeDouble];
}

@end
