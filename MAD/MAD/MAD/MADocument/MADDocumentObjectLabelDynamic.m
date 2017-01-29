//
//  MADDocumentObjectLabelDynamic.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectLabelDynamic.h"
#import <Foundation/NSString.h>
#import "MTDataTable.h"
#import "RptqDocumentObject+CoreDataClass.h"
#import "RptqDocumentObjectLabelDataField+CoreDataClass.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqQueryField+CoreDataClass.h"
#import "RptqQueryTable+CoreDataClass.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField+CoreDataClass.h"
#import "MTDatabase.h"
#import "MTReportFormatter.h"

#import "MTDataTableFast.h"

#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

#import "MADocumentObjectAttributesText.h"
#import <UIKit/UIFontDescriptor.h>
#import <UIKit/NSStringDrawing.h>

@implementation MADDocumentObjectLabelDynamic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super initWithDefinition:definition]) {
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        RptqDocumentObjectLabelDataField *item;
        
        datasource = definition.datasource;
        item = definition.item;
        NSString *qa = [item.referencesQueryField.inQueryTable copyQueryAlias];
        NSString *tableFieldKey = [datasource.database newSafeQueryField: item.referencesQueryField.databaseSchemaField.name
                                                                andTable: qa];

        NSDictionary *rowData = [datasource.dataTable copyDataForCacheId: definition.detailRowId
                                                     andColumnIdentifier: tableFieldKey];
        if (rowData != nil) {
            
            NSString *text = [item formattedString: item.referencesQueryField.databaseSchemaField.dataType.shortValue
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
