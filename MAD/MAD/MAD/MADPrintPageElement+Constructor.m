//
//  MADPrintPageElement+Constructor.m
//  MAD
//
//  Created by Michael on 9/2/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
	NSLog(@"%s %@", __PRETTY_FUNCTION__, NSStringFromMADPrintPageElementType(definition.type));
	
	switch (definition.type) {
		case MADPrintPageElementTypeAggregate:
			return [[MADPrintPageElementAggregate alloc] initWithDefinition:definition];
			break;
			
		case MADPrintPageElementTypeImage:
			return [[MADPrintPageElementImage alloc] initWithDefinition:definition];
			break;
			
		case MADPrintPageElementTypeBarcode:
			return [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];
			break;
			
		case MADPrintPageElementTypeLabelDynamic:
			return [[MADPrintPageElementTextDynamic alloc] initWithDefinition:definition];
			break;
			
		case MADPrintPageElementTypeLabelStatic:
			return [[MADPrintPageElementTextStatic alloc] initWithDefinition:definition];
			break;
			//case MADPrintPageElementTypeWhtiespace:
			//case MADPrintPageElementTypeGroupKey:
			//case MADPrintPageElementTypeChart:
			//case MADPrintPageElementTypeFormula:
			//case MADPrintPageElementTypeAggregateFunctionList:
		default:
			return nil;
			break;
	}
	return nil;
}

@end
