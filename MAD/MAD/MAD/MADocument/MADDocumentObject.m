//
//  MADDocumentObject.m
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObject.h"
#import <Foundation/NSException.h>
#import "MADDocumentObjectReference.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"

#import "MADDocumentObjectAggregate.h"
#import "MADDocumentObjectLabelDynamic.h"
#import "MADDocumentObjectImage.h"
#import "MADDocumentObjectBarcode.h"
#import "MADDocumentObjectLabelStatic.h"

@implementation MADDocumentObject

+ (instancetype)newDocumentObject:(MADDocumentObjectDataReference *)definition {

    id documentObject;
    switch (definition.item.documentObjectType) {
            
        case MTDocumentObjectTypeAggregate:
            documentObject = [[MADDocumentObjectAggregate alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeImage:
            documentObject = [[MADDocumentObjectImage alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeBarcode:
            documentObject = [[MADDocumentObjectBarcode alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeLabelDynamic:
            documentObject = [[MADDocumentObjectLabelDynamic alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeLabelStatic:
            documentObject = [[MADDocumentObjectLabelStatic alloc] initWithDefinition:definition];
            break;
        //case MTDocumentObjectTypeWhtiespace:
        //case MTDocumentObjectTypeGroupKey:
        //case MTDocumentObjectTypeChart:
        //case MTDocumentObjectTypeFormula:
        //case MTDocumentObjectTypeAggregateFunctionList:
        default:
            documentObject = nil;
            break;
    }
    return documentObject;
}

- (void)drawInRect:(CGRect)rect { }

@end
