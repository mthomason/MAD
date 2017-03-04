//
//  MADDocumentObjectTypeDescriptor.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectTypeDescriptor_h
#define MAD_MADDocumentObjectTypeDescriptor_h

#import <Foundation/NSString.h>
#import <MAD/MADDocumentObjectType.h>

extern NSString * const MADDocumentObjectTypeTitleDynamic;
extern NSString * const MADDocumentObjectTypeTitleStatic;
extern NSString * const MADDocumentObjectTypeTitleWhitespace;
extern NSString * const MADDocumentObjectTypeTitleAggregate;
extern NSString * const MADDocumentObjectTypeTitleImage;
extern NSString * const MADDocumentObjectTypeTitleBarcode;

extern NSString * const MADDocumentObjectTypeAddDetailDynamic;
extern NSString * const MADDocumentObjectTypeAddDetailStatic;
extern NSString * const MADDocumentObjectTypeAddDetailWhitespace;
extern NSString * const MADDocumentObjectTypeAddDetailAggregate;
extern NSString * const MADDocumentObjectTypeAddDetailImage;
extern NSString * const MADDocumentObjectTypeAddDetailBarcode;

typedef NSString MADDocumentObjectTypeDescriptor;

@interface NSString (MADocumentObjectType)

    + (NSString *)humanReadableStringForType:(MTDocumentObjectType)type;
    + (NSString *)localizedStringForType:(MTDocumentObjectType)type;
    + (NSString *)localizedDetailStringForType:(MTDocumentObjectType)type;
    + (NSString *)localizedAddDetailStringForType:(MTDocumentObjectType)type;

@end

#endif
