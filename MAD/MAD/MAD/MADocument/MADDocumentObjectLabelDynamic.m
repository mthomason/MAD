//
//  MADDocumentObjectLabelDynamic.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectLabelDynamic.h"

#import <Foundation/NSString.h>
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import <MADSqlite3/MADDataTableFast.h>

@implementation MADDocumentObjectLabelDynamic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super initWithDefinition:definition]) {
        
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        datasource = definition.datasource;
        
        NSString *text = @"";
        NSDictionary *rowData = nil;
        __kindof RptqDocumentElement *item = definition.item;
        
        if ([item isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
            NSString *qa = [((RptqDocumentElementLabelDataField *)item).referencesQueryField.inQueryTable queryAlias];
            NSString *fieldKey = [datasource.database newSafeQueryField: ((RptqDocumentElementLabelDataField *)item).referencesQueryField.databaseSchemaField.name
                                                              andTable: qa];
            NSError * __autoreleasing error = nil;
            rowData = [datasource.dataTable dataForRow: definition.detailRowId
                                                column: fieldKey
                                                 error: &error];
            if (rowData != nil) {
                
                text = [item formattedString: ((RptqDocumentElementLabelDataField *)item).referencesQueryField.databaseSchemaField.dataType
                                    forValue: rowData[fieldKey]];
                if ([text isEqualToString:MTNullIdentifier]) {
                    text = @"";
                }
            }
        }
        self.text = text.copy;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
