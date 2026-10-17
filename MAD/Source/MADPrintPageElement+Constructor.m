//
//  MADPrintPageElement+Constructor.m
//  MAD
//
//  Created by Michael on 9/2/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPrintPageElement+Constructor.h"
#import "MADDocumentObjectDataReference.h"

#if __APPLE__
#import "MADPrintPageElementBarcode.h"
#endif

#import <Foundation/NSException.h>

@implementation MADPrintPageElement (Constructor)

+ (instancetype)newDocumentObject:(__kindof MADDocumentObjectDataReference *)definition {	
	switch (definition.type) {
		case MADPrintPageElementTypeAggregate:
			return [[MADPrintPageElementAggregate alloc] initWithDefinition:(MADDocumentObjectDataReferenceAggregate *)definition];
			break;
			
		case MADPrintPageElementTypeImage:
			return [[MADPrintPageElementImage alloc] initWithDefinition:(MADDocumentObjectDataReferenceImage *)definition];
			break;
			
		case MADPrintPageElementTypeBarcode:
#if __APPLE__
			return [[MADPrintPageElementBarcode alloc] initWithDefinition:definition];
#else
			// MADBarcodes is Apple-only (MADSources.cmake).  The element's line still
			// reaches the walk -- its type and frame do not need a drawing object --
			// but there is nothing to resolve text from, so the walk records it bare.
			return nil;
#endif
			break;
			
		case MADPrintPageElementTypeLabelDynamic:
			return [[MADPrintPageElementTextDynamic alloc] initWithDefinition:(MADDocumentObjectDataReferenceLabelDynamic *)definition];
			break;
			
		case MADPrintPageElementTypeLabelStatic:
			return [[MADPrintPageElementTextStatic alloc] initWithDefinition:(MADDocumentObjectDataReferenceLabelStatic *)definition];
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
