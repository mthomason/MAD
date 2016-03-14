//
//  MADDocumentObjectType.m
//  MAD
//
//  Created by Michael Thomason on 10/31/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectType.h"
#import <Foundation/NSString.h>
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

@interface MADDocumentObjectType ()

@end

@implementation MADDocumentObjectType

+ (NSString *)humanReadableStringForType:(MTDocumentObjectType)type {
    switch (type) {
        case MTDocumentObjectTypeLabelDynamic:
            return MADDocumentObjectTypeTitleDynamic;
            break;
        case MTDocumentObjectTypeLabelStatic:
            return MADDocumentObjectTypeTitleStatic;
            break;
        case MTDocumentObjectTypeAggregate:
            return MADDocumentObjectTypeTitleAggregate;
            break;
        case MTDocumentObjectTypeImage:
            return MADDocumentObjectTypeTitleImage;
            break;
        case MTDocumentObjectTypeWhtiespace:
            return MADDocumentObjectTypeTitleWhitespace;
            break;
        case MTDocumentObjectTypeBarcode:
            return MADDocumentObjectTypeTitleBarcode;
            break;
        default:
            return @"";
            break;
    }
}

+ (NSString *)humanReadableDetailStringForType:(MTDocumentObjectType)type {
    switch (type) {
        case MTDocumentObjectTypeLabelDynamic:
            return MADDocumentObjectTypeDetailDynamic;
            break;
        case MTDocumentObjectTypeLabelStatic:
            return MADDocumentObjectTypeDetailStatic;
            break;
        case MTDocumentObjectTypeAggregate:
            return MADDocumentObjectTypeDetailAggregate;
            break;
        case MTDocumentObjectTypeImage:
            return MADDocumentObjectTypeDetailImage;
            break;
        case MTDocumentObjectTypeWhtiespace:
            return MADDocumentObjectTypeDetailWhitespace;
            break;
        case MTDocumentObjectTypeBarcode:
            return MADDocumentObjectTypeDetailBarcode;
            break;
        default:
            return @"";
            break;
    }
}

+ (NSString *)humanReadableAddDetailStringForType:(MTDocumentObjectType)type {
    switch (type) {
        case MTDocumentObjectTypeLabelDynamic:
            return MADDocumentObjectTypeAddDetailDynamic;
            break;
        case MTDocumentObjectTypeLabelStatic:
            return MADDocumentObjectTypeAddDetailStatic;
            break;
        case MTDocumentObjectTypeAggregate:
            return MADDocumentObjectTypeAddDetailAggregate;
            break;
        case MTDocumentObjectTypeImage:
            return MADDocumentObjectTypeAddDetailImage;
            break;
        case MTDocumentObjectTypeWhtiespace:
            return MADDocumentObjectTypeAddDetailWhitespace;
            break;
        case MTDocumentObjectTypeBarcode:
            return MADDocumentObjectTypeAddDetailBarcode;
            break;
        default:
            return @"";
            break;
    }
}

+ (NSString *)localizedStringForType:(MTDocumentObjectType)type {
    return NSLocalizedString([self humanReadableStringForType:type], [self humanReadableStringForType:type]);
}

+ (NSString *)localizedDetailStringForType:(MTDocumentObjectType)type {
    return NSLocalizedString([self humanReadableDetailStringForType:type], [self humanReadableDetailStringForType:type]);
}

+ (NSString *)localizedAddDetailStringForType:(MTDocumentObjectType)type {
    return NSLocalizedString([self humanReadableAddDetailStringForType:type], [self humanReadableAddDetailStringForType:type]);
}

@end
