//
//  MADDocumentObjectDataReferenceAggregate.m
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectDataReferenceAggregate.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"
#import "MADPrintPageRendererDataSource.h"
#import "madlog.h"

#import <MADAPI/MADDatabase.h>

#import <Foundation/NSString.h>

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
	}
	
	RptqQueryField *aggregateField = aggItem.aggregateField;
	if (!aggregateField) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType));
		return nil;
	}
	
	RptqDatabaseSchemaField *dbSchemaField = aggregateField.databaseSchemaField;
	if (!dbSchemaField) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField.databaseSchemaField is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType));
		return nil;
	}
	
	NSString *fieldName = dbSchemaField.name;
	if (!fieldName || fieldName.length == 0) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField.databaseSchemaField.name is NIL or empty. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType));
		// Potentially return nil or an error placeholder if this is invalid
	}
	
	RptqQueryTable *queryTable = aggregateField.inQueryTable;
	if (!queryTable) {
		os_log_error(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.item.aggregateField.inQueryTable is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@, FieldName: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType), fieldName);
		return nil;
	}
	
	NSString *queryAlias = [queryTable queryAlias];
	if (!queryAlias || queryAlias.length == 0) {
		// Potentially return nil or an error placeholder
	}
	NSObject <MADPrintPageRendererDataSourceProtocol> *datasource = self.datasource;
	if (!datasource) {
		os_log_debug(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.datasource is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@, FieldName: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType), fieldName);
		return nil;
	}
	
	if (!datasource.database) {
		os_log_debug(logger, "MADDocumentObjectDataReferenceAggregate (self: %p, item: %p, itemID: %lld): fieldKey - self.datasource.database is NIL. PageIndex: %lu, DetailRowId: %lu, FunctionType: %@, FieldName: %@", self, aggItem, aggItem.identifier, (unsigned long)self.pageIndex, (unsigned long)self.detailRowId, NSStringFromMADAggregateFunctionType(self.functionType), fieldName);
		return nil;
	}
	
	return [datasource.database queryKey:fieldName table:queryAlias];
}

- (NSString *)formattedStringForValue:(id)value {
	NSString *result = [self.item formattedString: self.item.aggregateField.databaseSchemaField.dataType
										 forValue: value];
	if ([result isEqualToString:MTNullIdentifier]) result = @"";
	return result;
}

@end
