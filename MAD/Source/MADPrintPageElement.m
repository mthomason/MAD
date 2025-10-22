//
//  MADPrintPageElement.m
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPrintPageElement.h"
#import "MADDocumentObjectDataReference.h"
#import "MADDocumentObjectDataReferenceLabelStatic.h"
#import "MADDocumentObjectDataReferenceLabelDynamic.h"
#import "MADDocumentObjectDataReferenceImage.h"
#import "MADDocumentObjectDataReferenceAggregate.h"
#import "MADPrintPageRendererDataSource.h"
#import "madlog.h"

#import <Foundation/NSString.h>
#import <UIKit/UIImage.h>
#import <UIKit/NSStringDrawing.h>

@interface MADPrintPageElementText()
@property (readwrite, nonatomic, weak) MADDocumentObjectDataReference *definition;
@end

@interface MADPrintPageElementImage ()
@property (nonatomic, strong) UIImage *image;
@end


@implementation MADPrintPageElement

- (instancetype)initWithDefinition:(__kindof MADDocumentObjectDataReference *)definition {
	if (self = [super init]) { }
	return self;
}

- (void)drawInRect:(CGRect)rect { }

@end

@implementation MADPrintPageElementText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
	if (self = [super init]) {
		_definition = definition;
	}
	return self;
}

- (void)drawInRect:(CGRect)rect {
	NSDictionary <NSString *, id> *fontAttributes = [self.definition fontAttributes];
	[self.text drawWithRect: rect
					options: NSStringDrawingUsesLineFragmentOrigin
				 attributes: fontAttributes
					context: nil];
	
}

@end

@implementation MADPrintPageElementTextStatic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelStatic *)definition {
	if (self = [super initWithDefinition:definition]) {
		self.text = [definition.text copy];
	}
	return self;
}

- (void)drawInRect:(CGRect)rect {
	[super drawInRect:rect];
}

@end

@implementation MADPrintPageElementTextDynamic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelDynamic *)definition {
	if (self = [super initWithDefinition:definition]) {
		
		NSString *fieldKey = definition.fieldKey;
		NSError * __autoreleasing error = nil;
		NSDictionary *rowData = [definition.datasource dataForRow: definition.detailRowId
														   column: fieldKey
															error: &error];
		NSString *text = @"";
		if (rowData != nil) {
			id value = [rowData objectForKey:fieldKey];
			if (value != nil) {
				text = [definition formattedStringForValue: value];
			}
		}
		self.text = [text copy];
		
	}
	return self;
}

- (void)drawInRect:(CGRect)rect {
	[super drawInRect:rect];
}

@end

@implementation MADPrintPageElementImage

- (void)dealloc {
	_image = nil;
}

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceImage *)definition {
	if (self = [super init]) {
		self.image = definition.image;
	}
	return self;
}

- (void)drawInRect:(CGRect)rect {
	[self.image drawInRect:rect];
}

@end

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

