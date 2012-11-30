//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabase.h"

@implementation MNSDatabase

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)getTables: (void (^)(NSArray *tables))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}


- (void)fieldsInDatabase: (NSString *)database andTable:(RptqTable *)table
              completion: (void (^)(MNSDatabase *database, RptqTable *originTable, NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)identifier {
    return [MNSDatabase identifier];
}

+ (NSString *)identifier {
    return @"NONE";
}

@end