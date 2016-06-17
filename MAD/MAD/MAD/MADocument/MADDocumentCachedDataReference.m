//
//  MADDocumentCachedDataReference.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentCachedDataReference.h"

#import <Foundation/NSString.h>

#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObject+Extras.h"
#import "MTDatabase.h"
#import "MTDataTableFast.h"
#import <MADFoundation/MADDataType.h>

@interface MADDocumentCachedDataReference ()

    @property (nonatomic, readwrite, strong) NSString *tableName;
    @property (nonatomic, readwrite, strong) NSString *fieldName;
    @property (nonatomic, readwrite, assign) NSUInteger rowID;
    @property (nonatomic, readwrite, assign) MADDataType dataType;

@end

@implementation MADDocumentCachedDataReference

- (instancetype)initWithTableName:(NSString *)tableName
                        fieldName:(NSString *)fieldName
                            rowID:(NSUInteger)rowID {
    if (self = [super init]) {
        _tableName = tableName.copy;
        _fieldName = fieldName.copy;
    }
    return self;
}

- (instancetype)initWithDatabase:(MTDatabase *)database
            referencesQueryField:(RptqDocumentObject *)documentObject {
    if (self = [super init]) {
        NSString *tableName = [documentObject.isLabelDataField.referencesQueryField.inQueryTable copyQueryAlias];
        MADSafeQueryField *fieldName = [database newSafeQueryField: documentObject.isLabelDataField.referencesQueryField.databaseSchemaField.name
                                                           andTable: tableName];
        self.tableName = tableName;
        self.fieldName = fieldName;
        _dataType = documentObject.isLabelDataField.referencesQueryField.databaseSchemaField.dataType.shortValue;
        
    }
    return self;
}

- (NSString *)textForDatatable:(MTDataTableFast *)datatable andRowID:(NSUInteger)rowID {
/*    NSDictionary *rowData = [datatable copyDataForCacheId:rowID];
    NSString *text = [documentObject formattedString: _dataType
                                            forValue: rowData[self.fieldName]];*/
                                            return nil;
}

@end
