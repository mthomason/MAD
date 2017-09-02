//
//  MADDocumentObjectBarcode.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectBarcode.h"

#import <Foundation/NSString.h>
#import <MADBarcodes/MTBarcode.h>

#import <MADAPI/MADDatabase.h>

#import <MADSqlite3/MADDataTableFast.h>
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADReportFormatter.h"

#import "RptqDocumentElement.h"
#import "RptqDocumentElementBarcode.h"

#import "RptqDatabaseSchemaField.h"

#import "RptqQueryTable.h"
#import "RptqQueryField.h"

#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementBarcode+Extras.h"

#import "RptqQueryTable+Extras.h"

@implementation MADDocumentObjectBarcode {
    MTBarcode *_drawingObject;
}

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super init]) {
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        RptqDocumentElementBarcode *item;
        MADDatabase *database;
        
        datasource = definition.datasource;
        item = definition.item;
        database = datasource.database;
        NSDictionary *rowData = [datasource.dataTable dataForRow:definition.detailRowId];
        
        NSString *tableQueryAlias1 = [item.referencesField1.inQueryTable queryAlias];
        NSString *tableQueryAlias2 = [item.referencesField2.inQueryTable queryAlias];
        
        MADSafeQueryField *tableFieldKey1, *tableFieldKey2;
        tableFieldKey1 = [database newSafeQueryField: item.referencesField1.databaseSchemaField.name
                                            andTable: tableQueryAlias1];
        tableFieldKey2 = [database newSafeQueryField: item.referencesField2.databaseSchemaField.name
                                            andTable: tableQueryAlias2];
        
        NSString *input1 = [self inputForField: item.referencesField1
                             forDocumentObject: item
                                         value: rowData[tableFieldKey1]];
        NSString *input2 = [self inputForField: item.referencesField2
                             forDocumentObject: item
                                         value: rowData[tableFieldKey2]];
        
        MTBarcode *barcode = [MTBarcode newBarcode:item
                                            input1:input1
                                            input2:input2];
        _drawingObject = barcode;
    }
    return self;
}

- (NSString *)inputForField:(RptqQueryField *)field
          forDocumentObject:(RptqDocumentElement *)item
                      value:(id)value {
    
    NSString *input1 = [item formattedString: field.databaseSchemaField.dataType
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
