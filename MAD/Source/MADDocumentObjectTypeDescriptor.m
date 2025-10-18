//
//  MADDocumentObjectTypeDescriptor.m
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDocumentObjectTypeDescriptor.h"
#import <Foundation/NSBundle.h>

NSString * const MADDocumentObjectTypeTitleDynamic     = @"Data Label";
NSString * const MADDocumentObjectTypeTitleStatic      = @"Static Label";
NSString * const MADDocumentObjectTypeTitleWhitespace  = @"Whitespace";
NSString * const MADDocumentObjectTypeTitleAggregate   = @"Aggregate";
NSString * const MADDocumentObjectTypeTitleImage       = @"Image";
NSString * const MADDocumentObjectTypeTitleBarcode     = @"Barcode";

NSString * const MADDocumentObjectTypeDetailDynamic     = @"A dynamic data field label.";
NSString * const MADDocumentObjectTypeDetailStatic      = @"A static text document object.";
NSString * const MADDocumentObjectTypeDetailWhitespace  = @"An empty element.";
NSString * const MADDocumentObjectTypeDetailAggregate   = @"A grouping of data.";
NSString * const MADDocumentObjectTypeDetailImage       = @"A static image.";
NSString * const MADDocumentObjectTypeDetailBarcode     = @"A barcode element.";

NSString * const MADDocumentObjectTypeAddDetailDynamic     = @"Add a dynamic data field label.";
NSString * const MADDocumentObjectTypeAddDetailStatic      = @"Add a static text document object.";
NSString * const MADDocumentObjectTypeAddDetailWhitespace  = @"Add an empty element.";
NSString * const MADDocumentObjectTypeAddDetailAggregate   = @"Add a grouping of data.";
NSString * const MADDocumentObjectTypeAddDetailImage       = @"Add a static image.";
NSString * const MADDocumentObjectTypeAddDetailBarcode     = @"Add a barcode element.";

@implementation MADDocumentObjectTypeDescriptor

+ (NSString *)humanReadableStringForType:(MADPrintPageElementType)type {
	switch (type) {
		case MADPrintPageElementTypeLabelDynamic:
			return MADDocumentObjectTypeTitleDynamic;
			break;
		case MADPrintPageElementTypeLabelStatic:
			return MADDocumentObjectTypeTitleStatic;
			break;
		case MADPrintPageElementTypeAggregate:
			return MADDocumentObjectTypeTitleAggregate;
			break;
		case MADPrintPageElementTypeImage:
			return MADDocumentObjectTypeTitleImage;
			break;
		case MADPrintPageElementTypeWhtiespace:
			return MADDocumentObjectTypeTitleWhitespace;
			break;
		case MADPrintPageElementTypeBarcode:
			return MADDocumentObjectTypeTitleBarcode;
			break;
		default:
			return @"";
			break;
	}
}

+ (NSString *)humanReadableDetailStringForType:(MADPrintPageElementType)type {
	switch (type) {
		case MADPrintPageElementTypeLabelDynamic:
			return MADDocumentObjectTypeDetailDynamic;
			break;
		case MADPrintPageElementTypeLabelStatic:
			return MADDocumentObjectTypeDetailStatic;
			break;
		case MADPrintPageElementTypeAggregate:
			return MADDocumentObjectTypeDetailAggregate;
			break;
		case MADPrintPageElementTypeImage:
			return MADDocumentObjectTypeDetailImage;
			break;
		case MADPrintPageElementTypeWhtiespace:
			return MADDocumentObjectTypeDetailWhitespace;
			break;
		case MADPrintPageElementTypeBarcode:
			return MADDocumentObjectTypeDetailBarcode;
			break;
		default:
			return @"";
			break;
	}
}

+ (NSString *)humanReadableAddDetailStringForType:(MADPrintPageElementType)type {
	switch (type) {
		case MADPrintPageElementTypeLabelDynamic:
			return MADDocumentObjectTypeAddDetailDynamic;
			break;
		case MADPrintPageElementTypeLabelStatic:
			return MADDocumentObjectTypeAddDetailStatic;
			break;
		case MADPrintPageElementTypeAggregate:
			return MADDocumentObjectTypeAddDetailAggregate;
			break;
		case MADPrintPageElementTypeImage:
			return MADDocumentObjectTypeAddDetailImage;
			break;
		case MADPrintPageElementTypeWhtiespace:
			return MADDocumentObjectTypeAddDetailWhitespace;
			break;
		case MADPrintPageElementTypeBarcode:
			return MADDocumentObjectTypeAddDetailBarcode;
			break;
		default:
			return @"";
			break;
	}
}

+ (NSString *)localizedStringForType:(MADPrintPageElementType)type {
	return NSLocalizedString([self humanReadableStringForType:type], [self humanReadableStringForType:type]);
}

+ (NSString *)localizedDetailStringForType:(MADPrintPageElementType)type {
	return NSLocalizedString([self humanReadableDetailStringForType:type], [self humanReadableDetailStringForType:type]);
}

+ (NSString *)localizedAddDetailStringForType:(MADPrintPageElementType)type {
	return NSLocalizedString([self humanReadableAddDetailStringForType:type], [self humanReadableAddDetailStringForType:type]);
}

@end
