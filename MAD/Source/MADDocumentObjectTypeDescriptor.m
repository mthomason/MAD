//
//  MADDocumentObjectTypeDescriptor.m
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
			return NSLocalizedString(@"Data Label", @"Title of a dynamic data label element.");
			break;
		case MADPrintPageElementTypeLabelStatic:
			return NSLocalizedString(@"Static Label", @"Title of a static text element.");
			break;
		case MADPrintPageElementTypeAggregate:
			return NSLocalizedString(@"Aggregate", @"Title of a grouping element.");
			break;
		case MADPrintPageElementTypeImage:
			return NSLocalizedString(@"Image", @"Title of a static image element.");
			break;
		case MADPrintPageElementTypeWhtiespace:
			return NSLocalizedString(@"Whitespace", @"Title of an empty spacer element.");
			break;
		case MADPrintPageElementTypeBarcode:
			return NSLocalizedString(@"Barcode", @"Title of a barcode element.");
			break;
		default:
			return @"";
			break;
	}
}

+ (NSString *)humanReadableDetailStringForType:(MADPrintPageElementType)type {
	switch (type) {
		case MADPrintPageElementTypeLabelDynamic:
			return NSLocalizedString(@"A dynamic data field label.", @"Description of a dynamic data label element.");
			break;
		case MADPrintPageElementTypeLabelStatic:
			return NSLocalizedString(@"A static text document object.", @"Description of a static text element.");
			break;
		case MADPrintPageElementTypeAggregate:
			return NSLocalizedString(@"A grouping of data.", @"Description of a grouping element.");
			break;
		case MADPrintPageElementTypeImage:
			return NSLocalizedString(@"A static image.", @"Description of a static image element.");
			break;
		case MADPrintPageElementTypeWhtiespace:
			return NSLocalizedString(@"An empty element.", @"Description of an empty spacer element.");
			break;
		case MADPrintPageElementTypeBarcode:
			return NSLocalizedString(@"A barcode element.", @"Description of a barcode element.");
			break;
		default:
			return @"";
			break;
	}
}

+ (NSString *)humanReadableAddDetailStringForType:(MADPrintPageElementType)type {
	switch (type) {
		case MADPrintPageElementTypeLabelDynamic:
			return NSLocalizedString(@"Add a dynamic data field label.", @"Action to add a dynamic data label element.");
			break;
		case MADPrintPageElementTypeLabelStatic:
			return NSLocalizedString(@"Add a static text document object.", @"Action to add a static text element.");
			break;
		case MADPrintPageElementTypeAggregate:
			return NSLocalizedString(@"Add a grouping of data.", @"Action to add a grouping element.");
			break;
		case MADPrintPageElementTypeImage:
			return NSLocalizedString(@"Add a static image.", @"Action to add a static image element.");
			break;
		case MADPrintPageElementTypeWhtiespace:
			return NSLocalizedString(@"Add an empty element.", @"Action to add an empty spacer element.");
			break;
		case MADPrintPageElementTypeBarcode:
			return NSLocalizedString(@"Add a barcode element.", @"Action to add a barcode element.");
			break;
		default:
			return @"";
			break;
	}
}

+ (NSString *)localizedStringForType:(MADPrintPageElementType)type {
	return [self humanReadableStringForType:type];
}

+ (NSString *)localizedDetailStringForType:(MADPrintPageElementType)type {
	return [self humanReadableDetailStringForType:type];
}

+ (NSString *)localizedAddDetailStringForType:(MADPrintPageElementType)type {
	return [self humanReadableAddDetailStringForType:type];
}

@end
