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
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElement+Extras.h"
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
            referencesQueryField:(RptqDocumentElement *)documentObject {

    if (self = [super init]) {
        
        NSString *tableName;
        MADSafeQueryField *fieldName;
        RptqDocumentElementLabelDataField *isLabelDataField;
        RptqQueryField *referencesQueryField;
        RptqDatabaseSchemaField *databaseSchemaField;
        RptqQueryTable *inQueryTable;
        
        isLabelDataField = documentObject;
        referencesQueryField = isLabelDataField.referencesQueryField;
        databaseSchemaField = referencesQueryField.databaseSchemaField;
        
        
        inQueryTable = databaseSchemaField.inQueryField;
        
        tableName = [inQueryTable queryAlias];
        
        NSString *fieldNameRaw;
        fieldName = [database newSafeQueryField: isLabelDataField.referencesQueryField.databaseSchemaField.name
                                       andTable: tableName];
        
        self.tableName = tableName;
        self.fieldName = fieldName;
        _dataType = isLabelDataField.referencesQueryField.databaseSchemaField.dataType.shortValue;
        
    }
    return self;
}

@end
