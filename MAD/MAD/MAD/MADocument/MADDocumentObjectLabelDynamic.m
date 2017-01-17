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
#import "RptqDocumentObject.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
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
        RptqDocumentObject *item;
        
        datasource = definition.datasource;
        item = definition.item;

        NSDictionary *rowData = [datasource.dataTable copyDataForCacheId:definition.detailRowId];
        if (rowData != nil) {
            NSString *qa = [item.isLabelDataField.referencesQueryField.inQueryTable copyQueryAlias];
            NSString *tableFieldKey = [datasource.database newSafeQueryField: item.isLabelDataField.referencesQueryField.databaseSchemaField.name
                                                                    andTable: qa];
            
            NSString *text = [item.isLabelDataField formattedString: item.isLabelDataField.referencesQueryField.databaseSchemaField.dataType.shortValue
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
