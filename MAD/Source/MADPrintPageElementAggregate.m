//
//  MADPrintPageElementAggregate.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPrintPageElementAggregate.h"
#import "MADDocumentObjectDataReferenceAggregate.h"
#import "MADPrintPageRendererDataSource.h"
#import "madlog.h"

#import <MADAPI/MADAliases.h>

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>

@implementation MADPrintPageElementAggregate

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceAggregate *)definition {
	if (!definition) {
		os_log_error(GetMadLog(), "MADPrintPageElementAggregate (self: %p): initWithDefinition: - definition object is NIL. Cannot proceed.", self);
	} else {
		if (![definition fieldKey] || [[definition fieldKey] length] == 0) {
			os_log_error(GetMadLog(), "MADPrintPageElementAggregate (self: %p): WARNING - definition (definition: %p) has NIL or EMPTY fieldKey: '%@'", self, definition, [definition fieldKey]);
		}
	}
	if (self = [super initWithDefinition:definition]) {
		NSObject <MADPrintPageRendererDataSourceProtocol> *datasource = definition.datasource;

		if (!datasource) {
			os_log_error(GetMadLog(), "MADPrintPageElementAggregate (self: %p, definition: %p): Datasource is NIL in definition.", self, definition);
			self.text = @"Error: No Datasource";
			return self;
		}
		
		NSString *fieldKey = [definition fieldKey];
		NSArray <MADResult *> *groupKeys = [datasource groupKeys:(int64_t)definition.detailRowId
													 groupNumber:definition.groupNumber];
		
		//NSArray <NSString *> *groupNames = [[datasource groupLevelKeyNames] subarrayWithRange:NSMakeRange(0, groupKeys.count)];
		
		__kindof NSObject <NSSecureCoding, NSCopying> *aggregateResult = nil;
		if (![definition calculateInMemory]) {

			NSArray <NSNumber *> *rowIDsForPage  = [datasource rowIDsForPage:definition.pageIndex];
			aggregateResult = [datasource dataForRows: rowIDsForPage
											   column: fieldKey
											   groups: groupKeys
											 function: definition.functionType
											  groupBy: definition.groupType];
			
			
		} else {
			NSArray <__kindof NSDictionary *> *dataForGroup = nil;
			NSDictionary *dataOfInterest = nil;
			switch (definition.groupType) {
				case MTAggregateGroupByTypeSection: {
					
					dataForGroup = [datasource dataForGroups: groupKeys groupID: definition.groupNumber];
					
					switch (definition.functionType) {
						case MTAggregateFunctionTypeFirst:
							dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.firstObject : @{fieldKey : @""};
							break;
						case MTAggregateFunctionTypeLast:
							dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.lastObject : @{fieldKey : @""};
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
