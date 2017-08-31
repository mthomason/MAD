//
//  MADDocumentObjectLabelDynamic.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectLabelDynamic.h"

#import <Foundation/NSString.h>

#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementLabelDataField+Extras.h"

#import "RptqQueryField.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqDatabaseSchemaField.h"

#import <MADAPI/MADDatabase.h>
#import <MADSqlite3/MADDataTableFast.h>

#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

#import "MADElementStylizedText.h"

@implementation MADDocumentObjectLabelDynamic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super initWithDefinition:definition]) {
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        RptqDocumentElementLabelDataField *item;
        
        datasource = definition.datasource;
        item = definition.item;
        NSString *qa = [item.referencesQueryField.inQueryTable queryAlias];
        NSString *tableFieldKey = [datasource.database newSafeQueryField: item.referencesQueryField.databaseSchemaField.name
                                                                andTable: qa];
        NSError * __autoreleasing error = nil;
        NSDictionary *rowData = [datasource.dataTable copyDataForCacheId: definition.detailRowId
                                                     andColumnIdentifier: tableFieldKey
                                                                   error: &error];
        if (rowData != nil) {
            
            NSString *text = [item formattedString: item.referencesQueryField.databaseSchemaField.dataType
                                          forValue: rowData[tableFieldKey]];
            self.text = text.copy;
            if ([self.text isEqualToString:MTNullIdentifier]) {
                self.text = @"";
            }
        } else {
            self.text = @"";
        }
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
