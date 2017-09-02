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
            
        case MADPrintPageElementTypeAggregate:
            documentObject = [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];
            break;
            
        case MADPrintPageElementTypeImage:
            documentObject = [[MADPrintPageElementImage alloc] initWithDefinition:definition];
            break;
            
        case MADPrintPageElementTypeBarcode:
            documentObject = [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];
            break;
            
        case MADPrintPageElementTypeLabelDynamic:
            documentObject = [[MADPrintPageElementTextDynamic alloc] initWithDefinition:definition];
            break;
            
        case MADPrintPageElementTypeLabelStatic:
            documentObject = [[MADPrintPageElementTextStatic alloc] initWithDefinition:definition];
            break;
            //case MADPrintPageElementTypeWhtiespace:
            //case MADPrintPageElementTypeGroupKey:
            //case MADPrintPageElementTypeChart:
            //case MADPrintPageElementTypeFormula:
            //case MADPrintPageElementTypeAggregateFunctionList:
        default:
            documentObject = nil;
            break;
    }
    return documentObject;
}

@end
