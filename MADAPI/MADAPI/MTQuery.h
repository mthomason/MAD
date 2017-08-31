//
//  MTQuery.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAPI_Reports_MTQuery_h
#define MADAPI_Reports_MTQuery_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

#pragma mark Types of specific paramamters accepted for each query

@protocol MADDataProtocol;

extern NSString * const MTQueryKeyPredicateColumn;
extern NSString * const MTQueryKeyPredicateValue;
extern NSString * const MADIdentifierROWID;

@class NSMutableArray, NSMutableDictionary, MADDatabase, MADDataTable;

@protocol MADQueryDataBindingProtocol <NSObject>
    @property (nonatomic, strong) NSMutableArray *binaryBindings;
@end

@protocol MADQueryFieldKeysProtocol <NSObject>
    @property (nonatomic, readwrite, strong) NSMutableDictionary <NSString *, id> *fields;
    @property (nonatomic, strong) NSMutableArray *fieldKeys;
@end

@protocol MADQueryColumnsProtocol <NSObject>
    @property (nonatomic, strong) NSDictionary *columns;            //MADDataColumns by key
@end

@protocol MADQueryDataTableProtocol <NSObject>
    @property (nonatomic, strong) MADDataTable *dataTable;
@end

@protocol MADQueryDatabaseProtocol <NSObject>
    @property (nonatomic, strong) MADDatabase *database;
@end

@protocol MADQueryDataDelegateProtocol <NSObject>
    @property (nonatomic, weak) id <MADDataProtocol> dataDelegate;
@end

@protocol MADQueryUpdatableProtocol <NSObject>
    - (void)update;
@end

@interface MTQuery : NSObject

    - (instancetype)initWithObject:(id)object;

    - (NSString *)getSql:(NSError * __autoreleasing *)error;

    @property (nonatomic, readonly) BOOL returnsResults;
    @property (nonatomic, readonly) BOOL partOfTransactionSet;

@end

@interface MTQuery (MADQueryFieldKeysProtocol)    //Intended for use by MTQuery subclasses only

    - (NSString *)fieldKeyForIndex:(NSUInteger)index;

@end

@interface MTQuery (MADQueryDatabaseProtocol)    //Intended for use by MTQuery subclasses only

    - (NSString *)getSql:(MADDatabase *)database error:(NSError * __autoreleasing *)error;
    - (NSString *)fieldKeyForIndex:(NSUInteger)index;

@end

#endif
