//
//  MADDocumentObjectCollectionViewCell.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/24/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDocumentObjectCollectionViewCell.h"

#import <UIKit/UIAccessibility.h>
#import <UIKit/UILabel.h>
#import <UIKit/UINibLoading.h>

#import <MAD/MADDocumentObjectTypeDescriptor.h>

@implementation MADDocumentObjectCollectionViewCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.title.isAccessibilityElement = NO;
	self.detail.isAccessibilityElement = NO;
	self.detail.textColor = [UIColor labelColor];
}

- (void)setType:(MADPrintPageElementType)type {
	if (_type != type) {
		_type = type;
		switch (_type) {
			case MADPrintPageElementTypeLabelDynamic:
				self.title.text = [MADDocumentObjectCollectionViewCell TitleDynamic];
				self.detail.text = [MADDocumentObjectCollectionViewCell DetailDynamic];
				break;
			case MADPrintPageElementTypeLabelStatic:
				self.title.text = [MADDocumentObjectCollectionViewCell TitleStatic];
				self.detail.text = [MADDocumentObjectCollectionViewCell DetailStatic];
				break;
			case MADPrintPageElementTypeAggregate:
				self.title.text = [MADDocumentObjectCollectionViewCell TitleAggregate];
				self.detail.text = [MADDocumentObjectCollectionViewCell DetailAggregate];
				break;
			case MADPrintPageElementTypeImage:
				self.title.text = [MADDocumentObjectCollectionViewCell TitleImage];
				self.detail.text = [MADDocumentObjectCollectionViewCell DetailImage];
				break;
			case MADPrintPageElementTypeWhtiespace:
				self.title.text = [MADDocumentObjectCollectionViewCell TitleWhitespace];
				self.detail.text = [MADDocumentObjectCollectionViewCell DetailWhitespace];
				break;
			case MADPrintPageElementTypeBarcode:
				self.title.text = [MADDocumentObjectCollectionViewCell TitleBarcode];
				self.detail.text = [MADDocumentObjectCollectionViewCell DetailBarcode];
				break;
			default:
				self.title.text = @"";
				self.detail.text = @"";
				break;
		}
	}
}

- (NSString *)accessibilityHint {
	switch (self.type) {
		case MADPrintPageElementTypeLabelDynamic:
			return [MADDocumentObjectCollectionViewCell DetailDynamic];
			break;
		case MADPrintPageElementTypeLabelStatic:
			return [MADDocumentObjectCollectionViewCell DetailStatic];
			break;
		case MADPrintPageElementTypeAggregate:
			return [MADDocumentObjectCollectionViewCell DetailAggregate];
			break;
		case MADPrintPageElementTypeImage:
			return [MADDocumentObjectCollectionViewCell DetailImage];
			break;
		case MADPrintPageElementTypeWhtiespace:
			return [MADDocumentObjectCollectionViewCell DetailWhitespace];
			break;
		case MADPrintPageElementTypeBarcode:
			return [MADDocumentObjectCollectionViewCell DetailBarcode];
			break;
		default:
			return @"";
			break;
	}
}

- (NSString *)accessibilityLabel {
	switch (self.type) {
		case MADPrintPageElementTypeLabelDynamic:
			return [MADDocumentObjectCollectionViewCell TitleDynamic];
			break;
		case MADPrintPageElementTypeLabelStatic:
			return [MADDocumentObjectCollectionViewCell TitleStatic];
			break;
		case MADPrintPageElementTypeAggregate:
			return [MADDocumentObjectCollectionViewCell TitleAggregate];
			break;
		case MADPrintPageElementTypeImage:
			return [MADDocumentObjectCollectionViewCell TitleImage];
			break;
		case MADPrintPageElementTypeWhtiespace:
			return [MADDocumentObjectCollectionViewCell TitleWhitespace];
			break;
		case MADPrintPageElementTypeBarcode:
			return [MADDocumentObjectCollectionViewCell TitleBarcode];
			break;
		default:
			return @"";
			break;
	}
}

- (BOOL)isAccessibilityElement {
	return YES;
}


// The strings live in MADDocumentObjectTypeDescriptor so there is one table.

+ (NSString *)TitleDynamic      { return [MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeLabelDynamic]; }
+ (NSString *)DetailDynamic     { return [MADDocumentObjectTypeDescriptor localizedAddDetailStringForType:MADPrintPageElementTypeLabelDynamic]; }

+ (NSString *)TitleStatic       { return [MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeLabelStatic]; }
+ (NSString *)DetailStatic      { return [MADDocumentObjectTypeDescriptor localizedAddDetailStringForType:MADPrintPageElementTypeLabelStatic]; }

+ (NSString *)TitleWhitespace   { return [MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeWhtiespace]; }
+ (NSString *)DetailWhitespace  { return [MADDocumentObjectTypeDescriptor localizedAddDetailStringForType:MADPrintPageElementTypeWhtiespace]; }

+ (NSString *)TitleAggregate    { return [MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeAggregate]; }
+ (NSString *)DetailAggregate   { return [MADDocumentObjectTypeDescriptor localizedAddDetailStringForType:MADPrintPageElementTypeAggregate]; }

+ (NSString *)TitleImage        { return [MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeImage]; }
+ (NSString *)DetailImage       { return [MADDocumentObjectTypeDescriptor localizedAddDetailStringForType:MADPrintPageElementTypeImage]; }

+ (NSString *)TitleBarcode      { return [MADDocumentObjectTypeDescriptor localizedStringForType:MADPrintPageElementTypeBarcode]; }
+ (NSString *)DetailBarcode     { return [MADDocumentObjectTypeDescriptor localizedAddDetailStringForType:MADPrintPageElementTypeBarcode]; }

@end
