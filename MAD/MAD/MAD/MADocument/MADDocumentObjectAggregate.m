//
//  MADDocumentObjectAggregate.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectAggregate.h"

#import <Foundation/NSString.h>

#import <MADFoundation/MADDataTable.h>

#import "RptqDocumentElementAggregate+Extras.h"
#import <MADAPI/MADDatabase.h>

#import "RptqDocumentElement+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentElementAggregate.h"

#import <MADSqlite3/MADDataTableFast.h>
#import "MADReportFormatter.h"
#import "MADParameters+QueryCacheAggregate.h"
#import <MADSqlite3/MADArrayCaching.h>
#import <MADAPI/MADQuery.h>
#import "MADQuery+Extras.h"
#import "MADAggregateFunctionGroupByType.h"

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
        datasource = definition.datasource;
        
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
        
        __kindof NSObject <NSCopying> *aggregateResult;
        
        if (!calculateInMemory) {
            
            NSArray <NSNumber *> *rowIDsForPage;
            rowIDsForPage = [datasource.reportFormatter rowIDsForPage:definition.pageIndex];
            
            aggregateResult = [datasource dataForRows:rowIDsForPage
                                               column:fieldKey
                                               groups:groupKeys
                                             function:isAggregate.functionType
                                              groupBy:isAggregate.groupType];
            
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
                            [[self class] dictionaryEmptyStringForKey: fieldKey];
                            break;
                        case MTAggregateFunctionTypeLast:
                            dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.lastObject :
                            [[self class] dictionaryEmptyStringForKey: fieldKey];
                            break;
                        default:
                            dataOfInterest = [[self class] dictionaryEmptyStringForKey: fieldKey];
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
                            dataOfInterest =  firstRowid != NSUIntegerMax ? [datasource dataForRow:firstRowid] : nil;
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
                            dataOfInterest = lastRowid != NSUIntegerMax ? [datasource dataForRow:lastRowid] : nil;
                            break;
                            
                        }
                        default:
                            dataOfInterest = [[self class] dictionaryEmptyStringForKey: fieldKey];
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
                            dataOfInterest =  firstRowid != NSUIntegerMax ? [datasource dataForRow:firstRowid] : nil;
                            break;
                        }
                        case MTAggregateFunctionTypeLast: {
                            
                            NSUInteger lastRowid = NSUIntegerMax;
                            NSArray <MADSectionRepresentation *> *sectionArray;
                            sectionArray = datasource.reportFormatter.reportLayout[(NSUInteger)datasource.reportFormatter.reportLayout.count - 1];
                            NSEnumerator <__kindof MADSectionRepresentation *> *reverseObjectEnumerator = [sectionArray reverseObjectEnumerator];
                            MADDocumentSectionType section;
                            for (MADSectionRepresentation *pageSection in reverseObjectEnumerator) {
                                section = pageSection.sectionType;
                                if (section == MADDocumentSectionTypeBody) {
                                    lastRowid = pageSection.detailRowId;
                                    break;
                                }
                            }
                            dataOfInterest = lastRowid != NSUIntegerMax ? [datasource dataForRow:lastRowid] : nil;
                            break;
                        }
                        default: {
                            
                            dataOfInterest = [[self class] dictionaryEmptyStringForKey: fieldKey];
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

+ (NSDictionary *)dictionaryEmptyStringForKey:(id)key {
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

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
