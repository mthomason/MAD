//
//  MADDocumentObjectCachedDataReferenceItem.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectCachedDataReferenceItem.h"

@interface MADDocumentObjectCachedDataReferenceItem ()

    @property (nonatomic, readwrite, strong) NSString *referencedItem;

@end

@implementation MADDocumentObjectCachedDataReferenceItem
/*
- (instancetype)initWithDatabase:(MTDatabase *)database
                       datatable:(MTDataTable *)datatable
                           rowID:(NSUInteger)rowID {
    
    if (self = [super init]) {
        NSString *drawingObject;
        NSDictionary *rowData = [self.dataTable copyDataForCacheId:rowID];
        if (rowData != nil) {
            NSString *qa = [item.referencesQueryField.inQueryTable copyQueryAlias];
            MADSafeQueryField *tableFieldKey = [database newSafeQueryField: item.referencesQueryField.databaseSchemaField.name
                                                                  andTable: qa];
            
            NSString *text = [item formattedString: item.referencesQueryField.databaseSchemaField.dataType.shortValue
                                          forValue: rowData[tableFieldKey]];
            drawingObject = [NSString stringWithString:text];
            if ([drawingObject isEqualToString:MTNullIdentifier]) {
                drawingObject = @"";
            }
        } else {
            drawingObject = @"";
        }

    }
    return self;
    
}
*/
@end
