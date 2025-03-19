//
//  MADQuery.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import <MADAPI/MADQuery.h>

#import <MADFoundation/MADDataProtocol.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseDataBinding.h>

NSString * const MADQueryKeyPredicateColumn  = @"c";
NSString * const MADQueryKeyPredicateValue   = @"v";
NSString * const MADIdentifierROWID         = @"ROWID";

@interface MADQuery ()

@end

@implementation MADQuery

- (void)update {

}

- (BOOL)returnsResults {
	return YES;
}

- (BOOL)partOfTransactionSet { return NO; }

- (instancetype)initWithObject:(id)object {
	if (self = [super init]) { }
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	if ([self conformsToProtocol:@protocol(MADQueryFieldKeysProtocol)]) {
		[((MADQuery <MADQueryFieldKeysProtocol> *)self).fields removeAllObjects];
		[((MADQuery <MADQueryFieldKeysProtocol> *)self).fieldKeys removeAllObjects];
	}
	return @"";
}

- (NSString *)getSql:(MADDatabase *)database error:(NSError * __autoreleasing *)error {
	if ([self conformsToProtocol:@protocol(MADQueryFieldKeysProtocol)]) {
		[((MADQuery <MADQueryFieldKeysProtocol> *)self).fields removeAllObjects];
		[((MADQuery <MADQueryFieldKeysProtocol> *)self).fieldKeys removeAllObjects];
	}
	if ([self conformsToProtocol:@protocol(MADQueryDatabaseProtocol)]) {
		if (((MADQuery <MADQueryDatabaseProtocol> *)self).database == nil) {
			((MADQuery <MADQueryDatabaseProtocol> *)self).database = database;
		}
	}
	NSError * __autoreleasing e = nil;
	NSString *sql = [self getSql:&e];
	if (e != nil  && error != NULL) { *error = e; }
	return sql;
}

- (NSString *)fieldKeyForIndex:(NSUInteger)index {
	NSString *key = nil;
	if ([self conformsToProtocol:@protocol(MADQueryFieldKeysProtocol)]) {
		key = (index < ((MADQuery <MADQueryFieldKeysProtocol> *)self).fieldKeys.count) ?
				((MADQuery <MADQueryFieldKeysProtocol> *)self).fieldKeys[index] : nil;
	}
	return key;
}

@end
