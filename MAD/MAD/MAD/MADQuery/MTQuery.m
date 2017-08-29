//
//  MTQuery.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQuery.h"

#import <Foundation/NSNull.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>
#import <Foundation/NSDictionary.h>

#import <MAD/MADQueryCacheSelectLimitOffsetParamaters.h>

#import <MADFoundation/MADDataProtocol.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADAPI/MTDatabase.h>
#import <MADAPI/MADDatabaseDataBinding.h>

NSString * const MTQueryKeyPredicateColumn  = @"c";
NSString * const MTQueryKeyPredicateValue   = @"v";
NSString * const MADIdentifierROWID         = @"ROWID";

@interface MTQuery ()

    @property (nonatomic, assign, readwrite) MADQueryType type;

@end

@implementation MTQuery

- (void)dealloc {
    _dataDelegate = nil;
}

- (void)update {

}

- (BOOL)returnsResults {
    return YES;
}

- (BOOL)partOfTransactionSet { return NO; }

- (instancetype)initWithObject:(id)object {
    
    if (self = [super init]) {
        
        NSMutableArray *binaryBindings = [[NSMutableArray alloc] init];
        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];

        self.binaryBindings = binaryBindings;
        self.fields = fieldInfo;
        self.fieldKeys = fieldKeys;

    }
    return self;
}

- (BOOL)performQueryWithError:(NSError * __autoreleasing *)error {
    NSError * __autoreleasing qerror = NULL;
    BOOL success = [self.database executeQuery:self withError:&qerror];
    if (!success && qerror != NULL && error != NULL) {
        *error = qerror;
    }
    NSAssert(qerror == NULL, @"Error: %@", (*error).localizedDescription);
    return success;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    [self.fields removeAllObjects];
    [self.fieldKeys removeAllObjects];
    return @"";
}

- (NSString *)getSql:(MTDatabase *)database error:(NSError * __autoreleasing *)error {
    [self.fields removeAllObjects];
    [self.fieldKeys removeAllObjects];
    if (self.database == nil) {
        self.database = database;
    }
    NSError * __autoreleasing e = nil;
    NSString *sql = [self getSql:&e];
    if (e != nil) { *error = e; }
    return sql;
}

- (NSString *)sqlGroupByExpressionWithQuery:(RptqQuery *)query {
    //Group is done on the reporting client side, so we do not add group by information here.
    return @"";
}

- (NSString *)fieldKeyForIndex:(NSUInteger)index {
    return (index < self.fieldKeys.count) ? self.fieldKeys[index] : nil;
}

- (NSMutableDictionary *)fields {
    return _fields == nil ? _fields = [NSMutableDictionary new] : _fields;
}
- (NSMutableArray *)fieldKeys {
    return _fieldKeys == nil ? _fieldKeys = [NSMutableArray new] : _fieldKeys;
}

@end
