//
//  MADDocumentObjectReference.h
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectReference_h
#define MAD_MADDocumentObjectReference_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>
#import <MAD/MADDocumentObjectType.h>
#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionType.h"

@protocol MADPrintPageRendererDataSourceProtocol, MTBarcodeProtocol;

@class RptqDocumentElement, NSManagedObjectID, MADDocumentObjectDataReference,
       MADElementStylizedText, NSMutableDictionary<KeyType, ObjectType>, UIImage;

@protocol MADDocumentObjectDataReferenceProtocol <NSObject>

- (NSDictionary <NSString *, id> *)fontAttributes:(MADDocumentObjectDataReference *)dataRef;

@end

@interface MADDocumentObjectDataReference : NSObject
    <NSCopying>

    + (instancetype)newDocumentObjectDataReference:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource
                                          delegate:(NSObject <MADDocumentObjectDataReferenceProtocol> *)delegate
                                              page:(NSUInteger)page
                                              item:(__kindof RptqDocumentElement *)item
                                            itemID:(NSUInteger)itemID;

    @property (readonly, nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
    @property (readonly, nonatomic, strong) NSMutableDictionary <NSManagedObjectID *, MADElementStylizedText *> *fontDescriptors;
    @property (readwrite, nonatomic, weak) __kindof RptqDocumentElement *item;

    @property (readonly, nonatomic, assign) MTDocumentObjectType type;
    @property (readwrite, nonatomic, assign) NSUInteger pageIndex;
    @property (readwrite, nonatomic, assign) NSUInteger detailRowId;

    - (NSDictionary <NSString *, id> *)fontAttributes;

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

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

    @property (nonatomic, copy, readonly) UIImage *image;

@end

@interface MADDocumentObjectDataReferenceLabelStatic : MADDocumentObjectDataReference

    @property (nonatomic, copy, readonly) NSString *text;

@end

@interface MADDocumentObjectDataReferenceLabelDynamic : MADDocumentObjectDataReference

    @property (nonatomic, copy, readonly) NSString *fieldKey;
    - (NSString *)formattedStringForValue:(id)value;

@end

@interface MADDocumentObjectDataReferenceBarcode : MADDocumentObjectDataReference

    @property (nonatomic, copy, readonly) NSString *fieldKey1;
    @property (nonatomic, copy, readonly) NSString *fieldKey2;
    - (NSString *)formattedStringForValue1:(id)value;
    - (NSString *)formattedStringForValue2:(id)value;
    @property (nonatomic, strong, readonly) id <MTBarcodeProtocol> barcode;

@end

#endif
