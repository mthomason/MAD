//
//  MADDocumentObjectReference.m
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
#import "MADDocumentObjectDataReferenceAggregate.h"
#import "MADDocumentObjectDataReferenceImage.h"
#import "MADDocumentObjectDataReferenceLabelStatic.h"
#import "MADDocumentObjectDataReferenceBarcode.h"
#import "MADDocumentObjectDataReferenceLabelDynamic.h"
#import "madlog.h"

#import <MADAPI/MADDatabase.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

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
	return [self.item formattedString:dataType forValue:value];
}

@end
