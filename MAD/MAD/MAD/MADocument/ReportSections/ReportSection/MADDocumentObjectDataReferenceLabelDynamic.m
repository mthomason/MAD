//
//  MADDocumentObjectDataReferenceLabelDynamic.m
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectDataReferenceLabelDynamic.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"
#import "MADPrintPageRendererDataSource.h"
#import "madlog.h"

#import <MADAPI/MADDatabase.h>

#import <Foundation/NSString.h>

@interface MADDocumentObjectDataReferenceLabelDynamic ()

@property (nonatomic, readonly) RptqDocumentElementLabelDataField *item;

@end

@implementation MADDocumentObjectDataReferenceLabelDynamic

@dynamic item;
@dynamic fieldKey;

- (NSString *)fieldKey {
	NSString *qa = [self.item.referencesQueryField.inQueryTable queryAlias];
	NSString *fieldName = self.item.referencesQueryField.databaseSchemaField.name;
	NSString *fieldKey = [self.datasource.database queryKey: fieldName table: qa];
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
