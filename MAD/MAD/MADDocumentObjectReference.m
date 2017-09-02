//
//  MADDocumentObjectReference.m
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectReference.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <MADAPI/MADDatabase.h>
#import <MADSqlite3/MADDataTableFast.h>

#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqTextStyle.h"
#import "RptqAlignment.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementBarcode+Extras.h"
#import "MADElementStylizedText.h"
#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionType.h"
#import "MADDocumentObjectType.h"
#import "MADPrintPageRendererDataSource.h"

@interface MADDocumentObjectDataReference ()

    @property (readwrite, nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
    @property (readwrite, nonatomic, weak) NSObject <MADDocumentObjectDataReferenceProtocol> *delegate;

@end

@implementation MADDocumentObjectDataReference

+ (instancetype)newDocumentObjectDataReference:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource
                                      delegate:(NSObject <MADDocumentObjectDataReferenceProtocol> *)delegate
                                          page:(NSUInteger)page
                                          item:(__kindof RptqDocumentElement *)element
                                        itemID:(NSUInteger)itemID {
    id result;
    switch (element.type) {
        case MADPrintPageElementTypeAggregate:
            result = [[MADDocumentObjectDataReferenceAggregate alloc] initWithDataSource:datasource
                                                                                delegate:delegate
                                                                                    page:page
                                                                                    item:element
                                                                                  itemID:itemID];
            break;
        case MADPrintPageElementTypeImage:
            result = [[MADDocumentObjectDataReferenceImage alloc] initWithDataSource:datasource
                                                                            delegate:delegate
                                                                                page:page
                                                                                item:element
                                                                              itemID:itemID];
            break;
        case MADPrintPageElementTypeLabelDynamic:
            result = [[MADDocumentObjectDataReferenceLabelDynamic alloc] initWithDataSource:datasource
                                                                                   delegate:delegate
                                                                                       page:page
                                                                                       item:element
                                                                                     itemID:itemID];
            break;
        case MADPrintPageElementTypeLabelStatic:
            result = [[MADDocumentObjectDataReferenceLabelStatic alloc] initWithDataSource:datasource
                                                                                  delegate:delegate
                                                                                      page:page
                                                                                      item:element
                                                                                    itemID:itemID];
            break;
        case MADPrintPageElementTypeBarcode:
            result = [[MADDocumentObjectDataReferenceBarcode alloc] initWithDataSource:datasource
                                                                              delegate:delegate
                                                                                  page:page
                                                                                  item:element
                                                                                itemID:itemID];
            break;
        case MADPrintPageElementTypeWhtiespace:
        default:
            result = [[self alloc] initWithDataSource:datasource delegate:delegate
                                                 page:page item:element itemID:itemID];
            break;
    }
    return result;
}

- (void)dealloc {
    [_fontDescriptors removeAllObjects];
}

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource
                          delegate:(NSObject <MADDocumentObjectDataReferenceProtocol> *)delegate
                              page:(NSUInteger)page
                              item:(__kindof RptqDocumentElement *)item
                            itemID:(NSUInteger)itemID {
    if (self = [super init]) {
        
        self.datasource = datasource;
        self.delegate = delegate;
        self.item = item;
        self.detailRowId = itemID;
        self.pageIndex = page;

    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone {
    typeof(self) copy = [[self.class allocWithZone:zone] init];
    copy.item = _item;
    copy.detailRowId = _detailRowId;
    copy.pageIndex = _pageIndex;
    copy.datasource = _datasource;
    return copy;
}

- (MADPrintPageElementType)type {
    return self.item.documentObjectType;
}

- (NSDictionary <NSString *, id> *)fontAttributes {
    return [self.delegate fontAttributes:self];
}

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    return [self.item formattedString:dataType forValue:value];
}

@end

@interface MADDocumentObjectDataReferenceAggregate ()
    @property (nonatomic, readonly) RptqDocumentElementAggregate *item;
@end

@implementation MADDocumentObjectDataReferenceAggregate

@dynamic item;
@dynamic fieldKey;
@dynamic groupNumber;
@dynamic calculateInMemory;
@dynamic groupType;
@dynamic functionType;

- (int32_t)groupNumber {
    return self.item.groupNumber;
}

- (MTAggregateGroupByType)groupType {
    return self.item.groupType;
}

- (MTAggregateFunctionType)functionType {
    return self.item.functionType;
}

- (BOOL)calculateInMemory {
    return self.functionType == MTAggregateFunctionTypeFirst ||
           self.functionType == MTAggregateFunctionTypeLast;
}

- (NSString *)fieldKey {
    NSString *fieldKey, *queryAlias, *fieldName;
    fieldName = self.item.aggregateField.databaseSchemaField.name;
    queryAlias = [self.item.aggregateField.inQueryTable queryAlias];
    fieldKey = [self.datasource.database newSafeQueryField: fieldName
                                                  andTable: queryAlias];
    return fieldKey;
}

- (NSString *)formattedStringForValue:(id)value {
    NSString *result;
    result = [self.item formattedString: self.item.aggregateField.databaseSchemaField.dataType
                               forValue: value];
    if ([result isEqualToString:MTNullIdentifier]) result = @"";
    return result;
}

@end

@interface MADDocumentObjectDataReferenceImage ()
    @property (nonatomic, readonly) RptqDocumentElementImage *item;
@end

@implementation MADDocumentObjectDataReferenceImage

@dynamic item;
@dynamic image;

- (UIImage *)image {
    return self.item.image;
}

@end

@interface MADDocumentObjectDataReferenceLabelStatic ()
    @property (nonatomic, readonly) RptqDocumentElementLabel *item;
@end

@implementation MADDocumentObjectDataReferenceLabelStatic

@dynamic item;

- (NSString *)text {
    return self.item.text;
}

@end

@interface MADDocumentObjectDataReferenceLabelDynamic ()
    @property (nonatomic, readonly) RptqDocumentElementLabelDataField *item;
@end

@implementation MADDocumentObjectDataReferenceLabelDynamic

@dynamic item;
@dynamic fieldKey;

- (NSString *)fieldKey {
    NSString *qa = [self.item.referencesQueryField.inQueryTable queryAlias];
    NSString *fieldName = self.item.referencesQueryField.databaseSchemaField.name;
    NSString *fieldKey = [self.datasource.database newSafeQueryField: fieldName
                                                            andTable: qa];
    return fieldKey;
}

- (NSString *)formattedStringForValue:(id)value {
    NSString *result;
    result = [self.item formattedString: self.item.referencesQueryField.databaseSchemaField.dataType
                               forValue: value];
    if ([result isEqualToString:MTNullIdentifier]) result = @"";
    return result;
}

@end

@interface MADDocumentObjectDataReferenceBarcode ()
    @property (nonatomic, readonly) RptqDocumentElementBarcode *item;
@end

@implementation MADDocumentObjectDataReferenceBarcode

@dynamic item;
@dynamic fieldKey1;
@dynamic fieldKey2;
@dynamic barcode;

- (id <MTBarcodeProtocol>)barcode {
    return self.item;
}

- (NSString *)fieldKey1 {
    NSString *queryAlias = [self.item.referencesField1.inQueryTable queryAlias];
    NSString *fieldName = self.item.referencesField1.databaseSchemaField.name;
    MADSafeQueryField *fieldKey;
    fieldKey = [self.datasource.database newSafeQueryField: fieldName
                                                  andTable: queryAlias];
    return fieldKey;
}

- (NSString *)fieldKey2 {
    NSString *queryAlias = [self.item.referencesField2.inQueryTable queryAlias];
    NSString *fieldName = self.item.referencesField2.databaseSchemaField.name;
    MADSafeQueryField *fieldKey;
    fieldKey = [self.datasource.database newSafeQueryField: fieldName
                                                  andTable: queryAlias];
    return fieldKey;
}

- (NSString *)formattedStringForValue1:(id)value {
    NSString *result;
    result = [self.item formattedString: self.item.referencesField1.databaseSchemaField.dataType
                               forValue: value];
    if ([result isEqualToString:MTNullIdentifier]) result = @"";
    return result;
}

- (NSString *)formattedStringForValue2:(id)value {
    NSString *result;
    result = [self.item formattedString: self.item.referencesField2.databaseSchemaField.dataType
                               forValue: value];
    if ([result isEqualToString:MTNullIdentifier]) result = @"";
    return result;
}

@end
