//
//  MADDocumentObjectAggregate.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectAggregate.h"

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>

#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

@implementation MADDocumentObjectAggregate

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceAggregate *)definition {
    if (self = [super initWithDefinition:definition]) {
        
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        datasource = definition.datasource;
        
        NSString *fieldKey = [definition fieldKey];
        NSArray *groupKeys = [datasource groupKeys:(int64_t)definition.detailRowId
                                       groupNumber:definition.groupNumber];
        
        
        __kindof NSObject <NSCopying> *aggregateResult;
        
        if (![definition calculateInMemory]) {
            
            NSArray <NSNumber *> *rowIDsForPage;
            rowIDsForPage = [datasource rowIDsForPage:definition.pageIndex];
            aggregateResult = [datasource dataForRows: rowIDsForPage
                                               column: fieldKey
                                               groups: groupKeys
                                             function: definition.functionType
                                              groupBy: definition.groupType];
            
        } else {    //Handle first and last
            
            NSArray <__kindof NSDictionary *> *dataForGroup = nil;
            NSDictionary *dataOfInterest = nil;
            switch (definition.groupType) {
                case MTAggregateGroupByTypeSection: {
                    
                    dataForGroup = [datasource dataForGroups: groupKeys
                                                     groupID: definition.groupNumber];
                    
                    switch (definition.functionType) {
                        case MTAggregateFunctionTypeFirst:
                            dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.firstObject :
                                                                        @{fieldKey : @""};
                            break;
                        case MTAggregateFunctionTypeLast:
                            dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.lastObject :
                                                                         @{fieldKey : @""};
                            break;
                        default:
                            dataOfInterest = @{fieldKey : @""};
                            break;
                    }
                    break;
                }
                case MTAggregateGroupByTypePage: {
                    
                    switch (definition.functionType) {
                            
                        case MTAggregateFunctionTypeFirst:
                            dataOfInterest = [datasource dataForRowPageFirst:definition.pageIndex];
                            break;
                            
                        case MTAggregateFunctionTypeLast:
                            dataOfInterest = [datasource dataForRowPageLast:definition.pageIndex];
                            break;
                            
                        default:
                            dataOfInterest = @{fieldKey : @""};
                            break;
                    }
                    break;
                }
                    
                case MTAggregateGroupByTypeReport: {
                    
                    switch (definition.functionType) {
                            
                        case MTAggregateFunctionTypeFirst:
                            dataOfInterest = [datasource dataForRowReportFirst];
                            break;
                            
                        case MTAggregateFunctionTypeLast:
                            dataOfInterest = [datasource dataForRowReportLast];
                            break;
                            
                        default:
                            dataOfInterest = @{fieldKey : @""};
                            break;
                            
                    }
                    break;
                }
                default:
                    break;
            }
            aggregateResult = dataOfInterest[fieldKey];
        }
        
        NSString *formattedString = [definition formattedStringForValue: aggregateResult];
        self.text = formattedString.copy;
        
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
