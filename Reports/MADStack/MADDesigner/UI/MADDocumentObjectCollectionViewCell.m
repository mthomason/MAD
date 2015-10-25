//
//  MADDocumentObjectCollectionViewCell.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/24/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectCollectionViewCell.h"
#import <MAD/MADDocumentObjectType.h>

static NSString * const MADTitleDynamic     = @"Data Label";
static NSString * const MADTitleStatic      = @"Static Label";
static NSString * const MADTitleWhitespace  = @"Whitespace";
static NSString * const MADTitleAggregate   = @"Aggregate";
static NSString * const MADTitleImage       = @"Image";
static NSString * const MADTitleBarcode     = @"Barcode";

static NSString * const MADDetailDynamic     = @"Add a dynamic data field label.";
static NSString * const MADDetailStatic      = @"Add a static text document object.";
static NSString * const MADDetailWhitespace  = @"Add an empty element.";
static NSString * const MADDetailAggregate   = @"Add a grouping of data.";
static NSString * const MADDetailImage       = @"Add a static image.";
static NSString * const MADDetailBarcode     = @"Add a barcode element.";

@implementation MADDocumentObjectCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title.isAccessibilityElement = NO;
    self.detail.isAccessibilityElement = NO;
}

- (void)setType:(MTDocumentObjectType)type {
    if (_type != type) {
        _type = type;
        switch (_type) {
            case MTDocumentObjectTypeLabelDynamic:
                self.title.text = [MADDocumentObjectCollectionViewCell TitleDynamic];
                self.detail.text = [MADDocumentObjectCollectionViewCell DetailDynamic];
                break;
            case MTDocumentObjectTypeLabelStatic:
                self.title.text = [MADDocumentObjectCollectionViewCell TitleStatic];
                self.detail.text = [MADDocumentObjectCollectionViewCell DetailStatic];
                break;
            case MTDocumentObjectTypeAggregate:
                self.title.text = [MADDocumentObjectCollectionViewCell TitleAggregate];
                self.detail.text = [MADDocumentObjectCollectionViewCell DetailAggregate];
                break;
            case MTDocumentObjectTypeImage:
                self.title.text = [MADDocumentObjectCollectionViewCell TitleImage];
                self.detail.text = [MADDocumentObjectCollectionViewCell DetailImage];
                break;
            case MTDocumentObjectTypeWhtiespace:
                self.title.text = [MADDocumentObjectCollectionViewCell TitleWhitespace];
                self.detail.text = [MADDocumentObjectCollectionViewCell DetailWhitespace];
                break;
            case MTDocumentObjectTypeBarcode:
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
        case MTDocumentObjectTypeLabelDynamic:
            return [MADDocumentObjectCollectionViewCell DetailDynamic];
            break;
        case MTDocumentObjectTypeLabelStatic:
            return [MADDocumentObjectCollectionViewCell DetailStatic];
            break;
        case MTDocumentObjectTypeAggregate:
            return [MADDocumentObjectCollectionViewCell DetailAggregate];
            break;
        case MTDocumentObjectTypeImage:
            return [MADDocumentObjectCollectionViewCell DetailImage];
            break;
        case MTDocumentObjectTypeWhtiespace:
            return [MADDocumentObjectCollectionViewCell DetailWhitespace];
            break;
        case MTDocumentObjectTypeBarcode:
            return [MADDocumentObjectCollectionViewCell DetailBarcode];
            break;
        default:
            return @"";
            break;
    }
}

- (NSString *)accessibilityLabel {
    switch (self.type) {
        case MTDocumentObjectTypeLabelDynamic:
            return [MADDocumentObjectCollectionViewCell TitleDynamic];
            break;
        case MTDocumentObjectTypeLabelStatic:
            return [MADDocumentObjectCollectionViewCell TitleStatic];
            break;
        case MTDocumentObjectTypeAggregate:
            return [MADDocumentObjectCollectionViewCell TitleAggregate];
            break;
        case MTDocumentObjectTypeImage:
            return [MADDocumentObjectCollectionViewCell TitleImage];
            break;
        case MTDocumentObjectTypeWhtiespace:
            return [MADDocumentObjectCollectionViewCell TitleWhitespace];
            break;
        case MTDocumentObjectTypeBarcode:
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


+ (NSString *)TitleDynamic      { return NSLocalizedString(MADTitleDynamic, MADTitleDynamic); }
+ (NSString *)DetailDynamic     { return NSLocalizedString(MADDetailDynamic, MADDetailDynamic); }

+ (NSString *)TitleStatic       { return NSLocalizedString(MADTitleStatic, MADTitleStatic); }
+ (NSString *)DetailStatic      { return NSLocalizedString(MADDetailStatic, MADDetailStatic); }

+ (NSString *)TitleWhitespace   { return NSLocalizedString(MADTitleWhitespace, MADTitleWhitespace); }
+ (NSString *)DetailWhitespace  { return NSLocalizedString(MADDetailWhitespace, MADDetailWhitespace); }

+ (NSString *)TitleAggregate    { return NSLocalizedString(MADTitleAggregate, MADTitleAggregate); }
+ (NSString *)DetailAggregate   { return NSLocalizedString(MADDetailAggregate, MADDetailAggregate); }

+ (NSString *)TitleImage        { return NSLocalizedString(MADTitleImage, MADTitleImage); }
+ (NSString *)DetailImage       { return NSLocalizedString(MADDetailImage, MADDetailImage); }

+ (NSString *)TitleBarcode      { return NSLocalizedString(MADTitleBarcode, MADTitleBarcode); }
+ (NSString *)DetailBarcode     { return NSLocalizedString(MADDetailBarcode, MADDetailBarcode); }

@end
