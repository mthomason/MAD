//
//  MADDocumentObjectCollectionViewCell.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/24/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
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


+ (NSString *)TitleDynamic      { return NSLocalizedString(MADDocumentObjectTypeTitleDynamic, MADDocumentObjectTypeTitleDynamic); }
+ (NSString *)DetailDynamic     { return NSLocalizedString(MADDocumentObjectTypeAddDetailDynamic, MADDocumentObjectTypeAddDetailDynamic); }

+ (NSString *)TitleStatic       { return NSLocalizedString(MADDocumentObjectTypeTitleStatic, MADDocumentObjectTypeTitleStatic); }
+ (NSString *)DetailStatic      { return NSLocalizedString(MADDocumentObjectTypeAddDetailStatic, MADDocumentObjectTypeAddDetailStatic); }

+ (NSString *)TitleWhitespace   { return NSLocalizedString(MADDocumentObjectTypeTitleWhitespace, MADDocumentObjectTypeTitleWhitespace); }
+ (NSString *)DetailWhitespace  { return NSLocalizedString(MADDocumentObjectTypeAddDetailWhitespace, MADDocumentObjectTypeAddDetailWhitespace); }

+ (NSString *)TitleAggregate    { return NSLocalizedString(MADDocumentObjectTypeTitleAggregate, MADDocumentObjectTypeTitleAggregate); }
+ (NSString *)DetailAggregate   { return NSLocalizedString(MADDocumentObjectTypeAddDetailAggregate, MADDocumentObjectTypeAddDetailAggregate); }

+ (NSString *)TitleImage        { return NSLocalizedString(MADDocumentObjectTypeTitleImage, MADDocumentObjectTypeTitleImage); }
+ (NSString *)DetailImage       { return NSLocalizedString(MADDocumentObjectTypeAddDetailImage, MADDocumentObjectTypeAddDetailImage); }

+ (NSString *)TitleBarcode      { return NSLocalizedString(MADDocumentObjectTypeTitleBarcode, MADDocumentObjectTypeTitleBarcode); }
+ (NSString *)DetailBarcode     { return NSLocalizedString(MADDocumentObjectTypeAddDetailBarcode, MADDocumentObjectTypeAddDetailBarcode); }

@end
