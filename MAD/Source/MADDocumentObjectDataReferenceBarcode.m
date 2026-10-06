//
//  MADDocumentObjectDataReferenceBarcode.m
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectDataReferenceBarcode.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElementBarcode+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"
#import "MADPrintPageRendererDataSource.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabase.h>

#import <Foundation/NSString.h>

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
	fieldKey = [self.datasource.database queryKey: fieldName table: queryAlias];
	return fieldKey;
}

- (NSString *)fieldKey2 {
	NSString *queryAlias = [self.item.referencesField2.inQueryTable queryAlias];
	NSString *fieldName = self.item.referencesField2.databaseSchemaField.name;
	MADSafeQueryField *fieldKey;
	fieldKey = [self.datasource.database queryKey: fieldName table: queryAlias];
	return fieldKey;
}

- (NSString *)formattedStringForValue1:(id)value {
	return [self.item formattedString: self.item.referencesField1.databaseSchemaField.dataType
							 forValue: value];
}

- (NSString *)formattedStringForValue2:(id)value {
	return [self.item formattedString: self.item.referencesField2.databaseSchemaField.dataType
							 forValue: value];
}

@end
