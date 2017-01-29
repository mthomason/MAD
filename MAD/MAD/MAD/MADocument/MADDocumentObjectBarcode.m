//
//  MADDocumentObjectBarcode.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectBarcode.h"
#import "MTDatabase.h"
#import "RptqDocumentObjectBarcode+Extras.h"
#import "MTDataTableFast.h"
#import "RptqQueryField+CoreDataClass.h"
#import "RptqDatabaseSchemaField+CoreDataClass.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDocumentObject+Extras.h"
#import "MTReportFormatter.h"
#import <Foundation/NSString.h>

#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "RptqDocumentObject+CoreDataClass.h"

#import <MADBarcodes/MTBarcode.h>

@implementation MADDocumentObjectBarcode {
    MTBarcode *_drawingObject;
}

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super init]) {
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        RptqDocumentObjectBarcode *item;
        MTDatabase *database;
        
        datasource = definition.datasource;
        item = definition.item;
        database = datasource.database;
        NSDictionary *rowData = [datasource.dataTable copyDataForCacheId:definition.detailRowId];
        
        NSString *tableQueryAlias1 = [item.referencesField1.inQueryTable copyQueryAlias];
        NSString *tableQueryAlias2 = [item.referencesField2.inQueryTable copyQueryAlias];
        
        MADSafeQueryField *tableFieldKey1, *tableFieldKey2;
        tableFieldKey1 = [database newSafeQueryField: item.referencesField1.databaseSchemaField.name
                                            andTable: tableQueryAlias1];
        tableFieldKey2 = [database newSafeQueryField: item.referencesField2.databaseSchemaField.name
                                            andTable: tableQueryAlias2];
        
        NSString *input1 = [self inputForField: item.referencesField1
                             forDocumentObject: item.parentObjectBarcode
                                         value: rowData[tableFieldKey1]];
        NSString *input2 = [self inputForField: item.referencesField2
                             forDocumentObject: item.parentObjectBarcode
                                         value: rowData[tableFieldKey2]];
        
        MTBarcode *barcode = [RptqDocumentObjectBarcode newBarcodeWithDocumentObject:item
                                                                              input1:input1
                                                                              input2:input2];
        _drawingObject = barcode;
    }
    return self;
}

- (NSString *)inputForField:(RptqQueryField *)field
          forDocumentObject:(RptqDocumentObject *)item
                      value:(id)value {
    
    NSString *input1 = [item formattedString: field.databaseSchemaField.dataType.shortValue
                                    forValue: value];
    if ([input1 isEqualToString:MTNullIdentifier]) {
        return @"";
    } else {
        NSString *result = [[NSString alloc] initWithString:input1];
        return result;
    }
}

- (void)drawInRect:(CGRect)rect {
    [_drawingObject drawInRect:rect];
}

@end
