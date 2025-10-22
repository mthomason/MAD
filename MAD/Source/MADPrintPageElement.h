//
//  MADPrintPageElement.h
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDocumentObject_h
#define MAD_MADDocumentObject_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MADDocumentObjectDataReference, MADDocumentObjectDataReferenceLabelStatic, MADDocumentObjectDataReferenceLabelDynamic, MADDocumentObjectDataReferenceAggregate, MADDocumentObjectDataReferenceImage;

@interface MADPrintPageElement : NSObject
- (instancetype)initWithDefinition:(__kindof MADDocumentObjectDataReference *)definition;
- (void)drawInRect:(CGRect)rect;
@end

@interface MADPrintPageElementText : MADPrintPageElement
@property (readwrite, nonatomic, copy) NSString *text;
- (instancetype)initWithDefinition:(__kindof MADDocumentObjectDataReference *)definition;
@end

@interface MADPrintPageElementTextStatic : MADPrintPageElementText
- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelStatic *)definition;
@end

@interface MADPrintPageElementTextDynamic : MADPrintPageElementText
- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelDynamic *)definition;
@end

@interface MADPrintPageElementImage : MADPrintPageElement
- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceImage *)definition;
@end

@interface MADPrintPageElementAggregate : MADPrintPageElementText
- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceAggregate *)definition;
@end

#endif
