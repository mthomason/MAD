//
//  MTQueryCacheSelectRowId.m
//  MAD
//
//  Created by Michael Thomason on 5/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectRowId.h"

@interface MTQueryCacheSelectRowId ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSNumber *rowId;

@end

@implementation MTQueryCacheSelectRowId

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        self.rowId = [object objectForKey:@(MTQuerySelectRowId)];
        
        NSString *tableName = [object objectForKey:@(MTQuerySelectTableName)];
        [self setTableName:tableName];
        
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return [NSString stringWithFormat:@"SELECT * FROM %@  WHERE rowid = %d", self.tableName, self.rowId.integerValue];
}

@end
