//
//  MADDocumentCachedDataReference.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentCachedDataReference.h"

@interface MADDocumentCachedDataReference ()

    @property (nonatomic, readwrite, copy)   NSString *tableName;
    @property (nonatomic, readwrite, copy)   NSString *fieldName;
    @property (nonatomic, readwrite, assign) NSUInteger rowID;

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

@end
