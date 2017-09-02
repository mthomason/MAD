//
//  MADPrintPageElement+Constructor.m
//  MAD
//
//  Created by Michael on 9/2/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPrintPageElement+Constructor.h"
#import <Foundation/NSException.h>
#import "MADDocumentObjectReference.h"

#import "MADPrintPageElementAggregate.h"
#import "MADPrintPageElementTextDynamic.h"
#import "MADPrintPageElementImage.h"
#import "MADPrintPageElementBarcode.h"
#import "MADPrintPageElementTextStatic.h"

@implementation MADPrintPageElement (Constructor)

+ (instancetype)newDocumentObject:(__kindof MADDocumentObjectDataReference *)definition {
    
    id documentObject;
    switch (definition.type) {
            
        case MTDocumentObjectTypeAggregate:
            documentObject = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeImage:
            documentObject = [[MADPrintPageElementImage alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeBarcode:
            documentObject = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeLabelDynamic:
            documentObject = [[MADPrintPageElementTextDynamic alloc] initWithDefinition:definition];
            break;
            
        case MTDocumentObjectTypeLabelStatic:
            documentObject = [[MADPrintPageElementTextStatic alloc] initWithDefinition:definition];
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

@end
