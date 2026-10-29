//
//  MADDocumentObjectReference.h
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDocumentObjectDataReference_h
#define MAD_MADDocumentObjectDataReference_h

#include <TargetConditionals.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSValue.h>
#import <MADFoundation/MADDataType.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>
#import <MAD/MADAggregateFunctionType.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MADPrintPageRendererDataSourceProtocol, MADBarcodeProtocol;
@class RptqDocumentElement, MADDocumentObjectDataReference, MADElementStylizedText, NSMutableDictionary;

#if defined(__APPLE__) && TARGET_OS_OSX
@class NSImage;
typedef NSImage MADReferenceImage;
#else
@class UIImage;
typedef UIImage MADReferenceImage;
#endif

@protocol MADDocumentObjectDataReferenceProtocol <NSObject>
@required
- (NSDictionary <NSString *, id> *)fontAttributes:(MADDocumentObjectDataReference *)dataRef;
@end

@interface MADDocumentObjectDataReference : NSObject <NSCopying>

@property (readonly, nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
@property (readonly, nonatomic, strong) NSMutableDictionary <NSNumber *, MADElementStylizedText *> *fontDescriptors;
@property (readwrite, nonatomic, weak) __kindof RptqDocumentElement *item;
@property (readonly, nonatomic, assign) MADPrintPageElementType type;
@property (readwrite, nonatomic, assign) NSUInteger pageIndex;
@property (readwrite, nonatomic, assign) NSUInteger detailRowId;

+ (instancetype)newDocumentObjectDataReference:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource
									  delegate:(NSObject <MADDocumentObjectDataReferenceProtocol> *)delegate
										  page:(NSUInteger)page
										  item:(__kindof RptqDocumentElement *)item
										itemID:(NSUInteger)itemID;
- (NSDictionary <NSString *, id> *)fontAttributes;
- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

@end

@interface MADDocumentObjectDataReferenceLabelStatic : MADDocumentObjectDataReference

@property (nonatomic, copy, readonly) NSString *text;

@end

@interface MADDocumentObjectDataReferenceLabelDynamic : MADDocumentObjectDataReference

@property (nonatomic, copy, readonly) NSString *fieldKey;
- (NSString *)formattedStringForValue:(id)value;

@end

@interface MADDocumentObjectDataReferenceAggregate : MADDocumentObjectDataReference

@property (nonatomic, copy, readonly) NSString *fieldKey;
@property (nonatomic, assign, readonly) int32_t groupNumber;
@property (nonatomic, assign, readonly) BOOL calculateInMemory;
@property (nonatomic, assign, readonly) MTAggregateGroupByType groupType;
@property (nonatomic, assign, readonly) MTAggregateFunctionType functionType;
- (NSString *)formattedStringForValue:(id)value;

@end

@interface MADDocumentObjectDataReferenceImage : MADDocumentObjectDataReference

@property (nullable, nonatomic, copy, readonly) MADReferenceImage *image;

@end

NS_ASSUME_NONNULL_END

#endif
