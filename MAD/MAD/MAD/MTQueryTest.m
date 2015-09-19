//
//  MTQueryTest.m
//  MAD
//
//  Created by Michael Thomason on 4/2/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryTest.h"
#import "MTDatabase.h"
#import "RptqUserCredentals.h"
#import <MADFoundation/MTDataTable.h>
#import "MTDataTable+Factory.h"
#import "MTDatabaseConnection.h"

@interface MTQueryTest ()
    <MTDatabaseProtocol>

@property (nonatomic, strong) MTDataTable *datatable;   // Holds datatable since used
                                                        //  in static function
@end

@implementation MTQueryTest

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[MTDatabaseConnection class]], @"MTQuerySampleDataTable expects RptqDatabaseSchemaTable.");
        
        NSUInteger hash = [object hash];
        
        NSNumber *typeKey = @(MTDataTableTypeOfTable);
        NSNumber *type = @(MTDataTableTypeVirtual);
        NSNumber *objectIdKey = @(MTDataTableObjectId);
        NSNumber *objectIdV =  @(hash);
        MTDataTable *datatable = [MTDataTable dataTableFactory:@{
                                                                 typeKey : type,
                                                                 objectIdKey : objectIdV}];
        
        self.datatable = datatable;
    
        MTDatabase *db = [MTDatabase databaseFactory:object];
        [self setDatabase:db];
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *key = [self.database safeIdentifier:@"f1"];
    [[self fieldKeys] addObject:key];
    NSString *sql = [NSString stringWithFormat:@"%@ 255 AS %@", [self.database selectPart], key];
    return sql;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self datatable];
}

@end
