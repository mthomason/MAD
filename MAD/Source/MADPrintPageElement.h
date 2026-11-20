//
//  MADPrintPageElement.h
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDocumentObject_h
#define MAD_MADDocumentObject_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MADDocumentObjectDataReference, MADDocumentObjectDataReferenceLabelStatic, MADDocumentObjectDataReferenceLabelDynamic, MADDocumentObjectDataReferenceAggregate, MADDocumentObjectDataReferenceImage, NSData;

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
/// The element's stored PNG bytes, so a line representation can carry them to the
/// formats (the barcode closure's -imageData seam).  Off Apple the picture is
/// those bytes; on Apple the PDF path draws it and this answers nil.
- (nullable NSData *)renderedImageData;
@end

@interface MADPrintPageElementAggregate : MADPrintPageElementText
- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceAggregate *)definition;
@end

#endif
