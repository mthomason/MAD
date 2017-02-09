//
//  MADDocumentObjectAggregate.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectAggregate.h"
#import <Foundation/NSString.h>
#import "RptqDocumentElementAggregate+Extras.h"
#import "MTDatabase.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentElementAggregate.h"
#import "MADDataTableFast.h"
#import "MADReportFormatter.h"
#import "MADParameters+QueryCacheAggregate.h"
#import "MADArrayCaching.h"
#import "MTQuery.h"
#import "MADAggregateFunctionGroupByType.h"
#import "MADDataTable.h"

#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

static inline NSRange MADRangeToGroup(int64_t groupNumber);
static inline NSRange MADRangeToGroup(int64_t groupNumber) {
    return NSMakeRange(0, (NSUInteger)groupNumber + 1);
}

@implementation MADDocumentObjectAggregate

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super initWithDefinition:definition]) {
        
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        datasource = datasource;
        RptqDocumentElementAggregate *isAggregate;
        isAggregate = (RptqDocumentElementAggregate *)definition.item;
        RptqQueryField *aggregateField = isAggregate.aggregateField;
        RptqQueryTable *inQueryTable = aggregateField.inQueryTable;
        
        NSString *queryAlias = [inQueryTable queryAlias];
        MADSafeQueryField *fieldKey;
        fieldKey = [datasource.database newSafeQueryField: aggregateField.databaseSchemaField.name
                                                 andTable: queryAlias];
        
        NSArray *groupKeys;
        
        int64_t groupNumber = isAggregate.groupNumber;
        NSArray *groupLevelKeys = [datasource groupLevelKeys:definition.detailRowId];
        if (groupNumber < (int64_t)groupLevelKeys.count) {
            groupKeys = [groupLevelKeys subarrayWithRange: MADRangeToGroup(groupNumber)];
        }
        
        RptqDatabaseSchemaField *databaseSchemaField = aggregateField.databaseSchemaField;
        MADDataType aggregateType = databaseSchemaField.dataType;
        
        BOOL calculateInMemory = isAggregate.functionType == MTAggregateFunctionTypeFirst ||
                                 isAggregate.functionType == MTAggregateFunctionTypeLast;
        
        id aggregateResult;
        
        if (calculateInMemory == NO) {
            
            int64_t groupType = isAggregate.groupType;
            MADIndexArray *rowIdsForPage = [datasource.reportFormatter rowidsForPage:definition.pageIndex];
            aggregateResult = [[self class] newResultsForAggregateType: groupType
                                                              function: isAggregate.functionType
                                                              fieldKey: fieldKey
                                                             groupKeys: groupKeys
                                                                rowids: rowIdsForPage
                                                         fromDataTable: datasource.dataTable];
            
        } else {    //Handle first and last
            
            NSArray <__kindof NSDictionary *> *dataForGroup = nil;
            NSDictionary *dataOfInterest = nil;
            switch (isAggregate.groupType) {
                case MTAggregateGroupByTypeSection: {
                    
                    dataForGroup = [[self class] dataForAggregateGroupByTypeSection: groupNumber
                                                                     groupLevelKeys: groupLevelKeys
                                                                          dataTable: datasource.dataTable];
                    
                    switch (isAggregate.functionType) {
                        case MTAggregateFunctionTypeFirst:
                            dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup[0] :
                            [[self class] newDictionaryEmptyStringForKey: fieldKey];
                            break;
                        case MTAggregateFunctionTypeLast:
                            dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.lastObject :
                            [[self class] newDictionaryEmptyStringForKey: fieldKey];
                            break;
                        default:
                            dataOfInterest = [[self class] newDictionaryEmptyStringForKey: fieldKey];
                            break;
                    }
                    break;
                }
                case MTAggregateGroupByTypePage: {
                    switch (isAggregate.functionType) {
                        case MTAggregateFunctionTypeFirst: {
                            
                            //don't get data from report formattter
                            //get it from data table
                            
                            NSUInteger firstRowid = NSUIntegerMax;
                            MADDocumentSectionType section;
                            for (MADSectionRepresentation *pageSection in datasource.reportFormatter.reportLayout[definition.pageIndex]) {
                                section = pageSection.sectionType;
                                if (section == MADDocumentSectionTypeBody) {
                                    firstRowid = pageSection.detailRowId;
                                    break;
                                }
                            }
                            dataOfInterest =  firstRowid != NSUIntegerMax ? [datasource.dataTable copyDataForCacheId:firstRowid] : nil;
                            break;
                        }
                        case MTAggregateFunctionTypeLast: {
                            
                            NSUInteger lastRowid = NSUIntegerMax;
                            MADDocumentSectionType section;
                            for (MADSectionRepresentation *pageSection in [datasource.reportFormatter.reportLayout[definition.pageIndex] reverseObjectEnumerator]) {
                                section = pageSection.sectionType;
                                if (section == MADDocumentSectionTypeBody) {
                                    lastRowid = pageSection.detailRowId;
                                    break;
                                }
                            }
                            dataOfInterest = lastRowid != NSUIntegerMax ? [datasource.dataTable copyDataForCacheId:lastRowid] : nil;
                            break;
                            
                        }
                        default:
                            dataOfInterest = [[self class] newDictionaryEmptyStringForKey: fieldKey];
                            break;
                    }
                    break;
                }
                case MTAggregateGroupByTypeReport: {
                    switch (isAggregate.functionType) {
                        case MTAggregateFunctionTypeFirst: {
                            
                            NSUInteger firstRowid = NSUIntegerMax;
                            MADDocumentSectionType section;
                            for (MADSectionRepresentation *pageSection in  datasource.reportFormatter.reportLayout[0]) {
                                section = pageSection.sectionType;
                                if (section == MADDocumentSectionTypeBody) {
                                    firstRowid = pageSection.detailRowId;
                                    break;
                                }
                            }
                            dataOfInterest =  firstRowid != NSUIntegerMax ? [datasource.dataTable copyDataForCacheId:firstRowid] : nil;
                            break;
                        }
                        case MTAggregateFunctionTypeLast: {
                            
                            NSUInteger lastRowid = NSUIntegerMax;
                            MADSectionArray *sectionArray = datasource.reportFormatter.reportLayout[(NSUInteger)datasource.reportFormatter.reportLayout.count - 1];
                            NSEnumerator <__kindof MADSectionRepresentation *> *reverseObjectEnumerator = [sectionArray reverseObjectEnumerator];
                            MADDocumentSectionType section;
                            for (MADSectionRepresentation *pageSection in reverseObjectEnumerator) {
                                section = pageSection.sectionType;
                                if (section == MADDocumentSectionTypeBody) {
                                    lastRowid = pageSection.detailRowId;
                                    break;
                                }
                            }
                            dataOfInterest = lastRowid != NSUIntegerMax ? [datasource.dataTable copyDataForCacheId:lastRowid] : nil;
                            break;
                        }
                        default: {
                            
                            dataOfInterest = [[self class] newDictionaryEmptyStringForKey: fieldKey];
                            break;
                        }
                    }
                    break;
                }
                default:
                    break;
            }
            aggregateResult = dataOfInterest[fieldKey];
        }
        
        NSString *formattedString = [isAggregate formattedString: aggregateType
                                                        forValue: aggregateResult];
        
        self.text = formattedString.copy;
        if ([self.text isEqualToString:MTNullIdentifier]) {
            self.text = @"";
        }
        
    }
    return self;
}

+ (NSDictionary *)newDictionaryEmptyStringForKey:(id)key {
    id dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"", key, nil];
    return dictionary;
}

+ (NSArray *)dataForAggregateGroupByTypeSection:(int64_t)groupNumber
                                 groupLevelKeys:(NSArray *)groupLevelKeys
                                      dataTable:(MADDataTable *)dataTable {
    NSArray <__kindof NSDictionary *> *dataForGroup;
    if (groupNumber < (int64_t)groupLevelKeys.count) {
        NSArray *groupKeys = [groupLevelKeys subarrayWithRange: MADRangeToGroup(groupNumber)];
        dataForGroup = [dataTable objectsForGroupKeys:groupKeys];
    } else {
        dataForGroup = @[];
    }
    return dataForGroup;
}

+ (id)newDocumentObjectForAggregateType:(MTAggregateGroupByType)groupByType
                               function:(MTAggregateFunctionType)function
                               fieldKey:(NSString *)fieldKey
                              groupKeys:(NSArray *)groupKeys
                                 rowids:(NSArray *)rowids
                          fromDataTable:(MADDataTableFast *)dataTable {
    
    id result = nil;
    NSString *columnKey = [dataTable columnKeyForColumnName:fieldKey];
    
    if (columnKey) {
        id queryParameters;
        
        switch (groupByType) {
            case MTAggregateGroupByTypePage: {
                queryParameters = [MADParameters newParamatersAggregateByPageWithFieldKey: columnKey
                                                                                andRowIds: rowids
                                                                          andFunctionType: function
                                                                             andDataTable: dataTable];
                break;
            }
            case MTAggregateGroupByTypeReport:
                queryParameters = [MADParameters newParametersAggregateByReportWithFieldKey: columnKey
                                                                            andFunctionType: function
                                                                               andDataTable: dataTable];
                break;
                
            case MTAggregateGroupByTypeSection:
                queryParameters = [MADParameters newParamatersAggregateByGroupKeys: groupKeys
                                                                       andFieldKey: columnKey
                                                                   andFunctionType: function
                                                                      andDataTable: dataTable];
                break;
                
            default:
                break;
        }
        
        MTQuery *query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheAggregateFunction
                                                     object: queryParameters];
        result = [dataTable runSelectQuery:query];
        
    }
    
    return result;
}

// FIXME: Return error handler... remove credentals
+ (id)newResultsForAggregateType:(MTAggregateGroupByType)groupByType
                        function:(MTAggregateFunctionType)function
                        fieldKey:(NSString *)fieldKey
                       groupKeys:(NSArray *)groupKeys
                          rowids:(NSArray *)rowids
                   fromDataTable:(MADDataTableFast *)dataTable {
    
    id result = nil;
    NSString *columnKey = [dataTable columnKeyForColumnName:fieldKey];
    
    if (columnKey) {
        id queryParameters;
        
        switch (groupByType) {
            case MTAggregateGroupByTypePage: {
                queryParameters = [MADParameters newParamatersAggregateByPageWithFieldKey: columnKey
                                                                                andRowIds: rowids
                                                                          andFunctionType: function
                                                                             andDataTable: dataTable];
                break;
            }
            case MTAggregateGroupByTypeReport:
                queryParameters = [MADParameters newParametersAggregateByReportWithFieldKey: columnKey
                                                                            andFunctionType: function
                                                                               andDataTable: dataTable];
                break;
                
            case MTAggregateGroupByTypeSection:
                queryParameters = [MADParameters newParamatersAggregateByGroupKeys: groupKeys
                                                                       andFieldKey: columnKey
                                                                   andFunctionType: function
                                                                      andDataTable: dataTable];
                break;
                
            default:
                break;
        }
        
        MTQuery *query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheAggregateFunction
                                                     object: queryParameters];
        result = [dataTable runSelectQuery:query];
        
    }
    
    return result;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
