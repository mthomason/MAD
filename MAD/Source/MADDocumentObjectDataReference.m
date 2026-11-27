//
//  MADDocumentObjectReference.m
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDocumentObjectDataReference.h"
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
#import "MADDocumentObjectDataReferenceBarcode.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabase.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

@interface MADDocumentObjectDataReference ()
@property (readwrite, nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
@property (readwrite, nonatomic, weak) NSObject <MADDocumentObjectDataReferenceProtocol> *delegate;
@end

@interface MADDocumentObjectDataReferenceLabelStatic ()
@property (nonatomic, readonly) RptqDocumentElementLabel *item;
@end

@interface MADDocumentObjectDataReferenceLabelDynamic ()
@property (nonatomic, readonly) RptqDocumentElementLabelDataField *item;
@end

@interface MADDocumentObjectDataReferenceAggregate ()
@property (nonatomic, readonly) RptqDocumentElementAggregate *item;
@end

@interface MADDocumentObjectDataReferenceImage ()
@property (nonatomic, readonly) RptqDocumentElementImage *item;
@end

@implementation MADDocumentObjectDataReference

+ (instancetype)newDocumentObjectDataReference:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource
									  delegate:(NSObject <MADDocumentObjectDataReferenceProtocol> *)delegate
										  page:(NSUInteger)page
										  item:(__kindof RptqDocumentElement *)element
										itemID:(NSUInteger)itemID {
	__kindof MADDocumentObjectDataReference *result;
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
	NSString *result = [self.item formattedString:dataType forValue:value];
	return result != nil ? result : @"";
}

@end

@implementation MADDocumentObjectDataReferenceLabelStatic

@dynamic item;

- (NSString *)text {
	return self.item.text ?: @"";
}

@end

@implementation MADDocumentObjectDataReferenceLabelDynamic

@dynamic item;
@dynamic fieldKey;

- (NSString *)fieldKey {
	RptqQueryField *field = self.item.referencesQueryField;
	// A composed document's root fields persist an explicit output key, and the
	// composed result table is keyed by those output keys -- not by a source-table
	// alias the way an ordinary query's columns are.  Reading the alias here would
	// resolve to nothing and render the detail band blank, or worse, if two sources
	// name a field the same, to the wrong source's value.
	if (field.outputKey.length > 0) {
		return field.outputKey;
	}
	NSString *qa = [field.inQueryTable queryAlias];
	NSString *fieldName = field.databaseSchemaField.name;
	NSString *fieldKey = [self.datasource.database queryKey: fieldName
													  table: qa];
	return fieldKey;
}

- (NSString *)formattedStringForValue:(id)value {
	RptqDatabaseSchemaField *schemaField = self.item.referencesQueryField.databaseSchemaField;
	return [self.item formattedString:schemaField.dataType
							 forValue:value
							 decimals:schemaField.decimals];
}

@end

@implementation MADDocumentObjectDataReferenceAggregate

@dynamic item;
@dynamic fieldKey;
@dynamic groupNumber;
@dynamic calculateInMemory;
@dynamic groupType;
@dynamic functionType;

- (int32_t)groupNumber { return self.item.groupNumber; }
- (MTAggregateGroupByType)groupType { return self.item.groupType; }
- (MTAggregateFunctionType)functionType { return self.item.functionType; }
- (BOOL)calculateInMemory { return self.functionType == MTAggregateFunctionTypeFirst || self.functionType == MTAggregateFunctionTypeLast; }

/*
 
 - (NSString *)fieldKey {
 NSString *fieldName = self.item.aggregateField.databaseSchemaField.name;
 NSString *queryAlias = [self.item.aggregateField.inQueryTable queryAlias];
 return [self.datasource.database queryKey: fieldName
 table: queryAlias];
 }
 
 */

- (NSString *)fieldKey {
	os_log_t logger = GetMadLog(); // Or your specific log handle for this subsystem
	
	RptqDocumentElementAggregate *aggItem = self.item;
	if (!aggItem) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p): fieldKey - self.item (RptqDocumentElementAggregate) is NIL. PageIndex: %lu, DetailRowId: %lu", self, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId);
		return nil; // Or an appropriate default to avoid crashing, though nil is fine for string.
		// ! nil returned from a method that is expected to return a non-null value
	}
	
	RptqQueryField *aggregateField = aggItem.aggregateField;
	if (!aggregateField) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType));
		return nil;
		// ! nil returned from a method that is expected to return a non-null value
	}
	
	RptqDatabaseSchemaField *dbSchemaField = aggregateField.databaseSchemaField;
	if (!dbSchemaField) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField.databaseSchemaField is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType));
		return nil;
		// ! nil returned from a method that is expected to return a non-null value
	}
	
	NSString *fieldName = dbSchemaField.name;
	if (!fieldName || fieldName.length == 0) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField.databaseSchemaField.name is NIL or empty. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType));
		// Potentially return nil or an error placeholder if this is invalid
	}
	
	RptqQueryTable *queryTable = aggregateField.inQueryTable;
	if (!queryTable) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField.inQueryTable is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@, FieldName: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType), fieldName);
		// ! nil returned from a method that is expected to return a non-null value
		return nil;
	}
	
	NSString *queryAlias = [queryTable queryAlias];
	if (!queryAlias || queryAlias.length == 0) {
		// Potentially return nil or an error placeholder
	}
	NSObject <MADPrintPageRendererDataSourceProtocol> *datasource = self.datasource;
	if (!datasource) {
		os_log_debug(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.datasource is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@, FieldName: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType), fieldName);
		// ! nil returned from a method that is expected to return a non-null value
		return nil;
	}
	
	if (!datasource.database) {
		os_log_debug(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.datasource.database is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@, FieldName: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType), fieldName);
		// ! nil returned from a method that is expected to return a non-null value
		return nil;
	}
	
	return [datasource.database queryKey:fieldName table:queryAlias];
}

- (NSString *)formattedStringForValue:(id)value {
	RptqDatabaseSchemaField *schemaField = self.item.aggregateField.databaseSchemaField;
	return [self.item formattedString:schemaField.dataType
							 forValue:value
							 decimals:schemaField.decimals];
}

@end

@implementation MADDocumentObjectDataReferenceImage

@dynamic item;
@dynamic image;

- (MADReferenceImage *)image {
	return self.item.image;
}

@end
