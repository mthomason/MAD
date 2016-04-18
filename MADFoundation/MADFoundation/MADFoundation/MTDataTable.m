//
//  MTTable.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataTable.h"
#import "MTDataColumn.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSURL.h>

static NSString * const StringEmpty = @"";

@interface MTDataTable ()

@end

@implementation MTDataTable

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
    
        NSString *name =                [decoder decodeObjectForKey: [MTDataTable keyName]];
        self.name = name;
        
        NSMutableArray *columnKeys =    [decoder decodeObjectForKey: [MTDataTable keyColumnKeys]];
        self.columnKeys = columnKeys;
        
        NSMutableDictionary *columns =  [decoder decodeObjectForKey: [MTDataTable keyColumns]];
        self.columns = columns;
        
        NSNumber *rowCounterObject = [decoder decodeObjectForKey: [MTDataTable keyRowCounter]];
        self.rowCounter = rowCounterObject.unsignedIntegerValue;
        
        NSMutableArray *sortDescriptors = [decoder decodeObjectForKey:[MTDataTable keySortDescriptors]];
        self.sortDescriptors = sortDescriptors;
        
        NSNumber *objid = [decoder decodeObjectForKey:@"objid"];
        self.tag = objid.unsignedIntegerValue;
        
    }
    return self;
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    if (self = [super init]) {
        
        NSString *name = @"";
        self.name = name;
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        self.columnKeys = columnKeys;
        
        NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
        self.sortDescriptors = sortDescriptors;
        
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
        self.columns = columns;
        
        self.rowCounter = 0;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initalizeWithObjectId:0 fromCache:NO];
    }
    return self;
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    if (self = [super init]) {
        [self initalizeWithObjectId:objectId fromCache:fromCache];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    NSNumber *objid = @(self.tag);
    [encoder encodeObject:  objid                   forKey: @"objid"];
    [encoder encodeObject:  [self sortDescriptors]  forKey: [MTDataTable keySortDescriptors]];
    [encoder encodeObject:  self.name             forKey: [MTDataTable keyName]];
    [encoder encodeObject:  [self columnKeys]       forKey: [MTDataTable keyColumnKeys]];
    [encoder encodeObject:  [self columns]          forKey: [MTDataTable keyColumns]];
    [encoder encodeObject: [NSNumber numberWithUnsignedInteger: [self rowCounter]]        forKey: [MTDataTable keyRowCounter]];
    
}

- (instancetype)initWithId:(NSUInteger)objectId {
    return [self initWithId:objectId fromCache:YES];
}

- (void)initalizeWithObjectId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    
    NSString *name = StringEmpty;
    self.name = name;
    
    NSMutableArray *columnKeys = [[NSMutableArray alloc] init];
    self.columnKeys = columnKeys;
    
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
    self.sortDescriptors = sortDescriptors;
    
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
    self.columns = columns;
    self.rowCounter = 0;
    self.tag = objectId;
    
}

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSArray *)objectsForGroupKeys:(NSArray *)groupKeys {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel
                                 withKeys:(NSArray *)keys accending:(BOOL)accending {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;    
}

+ (NSString *)keyUrl { return @"url"; }

- (NSString *)filenameMDCache {
    NSString *tag = [NSString stringWithFormat:@"%lu", (unsigned long)self.tag];
    return [tag stringByAppendingString:@"mdcache"];
}

- (void)loadFromCacheWithUrl:(NSURL *)url {
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath: url.path];
    [inputStream open];
    switch ([inputStream streamStatus]) {
        case NSStreamStatusError:
            break;
        default:
            break;
    }
    NSPropertyListFormat format;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithStream: inputStream
                                                           options: 0
                                                            format: &format
                                                             error: &error];
    if (plist) {
        [self loadWithPlist:plist];
    }
}

- (bool)cacheWithUrl:(NSURL *)url {

    NSDictionary *plist = [self plist];

    NSError *error = nil;
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList: plist
                                                               format: NSPropertyListBinaryFormat_v1_0
                                                              options: 0
                                                                error: &error];
    bool success = false;
    if (url) {
        success = [cache writeToURL: url
                            options: NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen
                              error: &error] ? true : false;

        NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);

    }
    return success;
}

- (NSDictionary *)plist {
    
    NSString *keyName = [MTDataTable keyName];
    NSString *keyColumnKeys = [MTDataTable keyColumnKeys];
    NSString *keyColumns = [MTDataTable keyColumns];
    NSString *keyRowCounter = [MTDataTable keyRowCounter];
    NSNumber *rowCounter = @([self rowCounter]);
    
    NSArray *columnKeys = [[NSArray alloc] initWithArray:[self columnKeys]];
    NSDictionary *columnsPlist = [NSDictionary dictionaryWithDictionary:[self columnsPlist]];
    
    return @{
             keyName        : self.name,
             keyColumnKeys  : columnKeys,
             keyColumns     : columnsPlist,
             keyRowCounter  : rowCounter,
             };
}

- (void)loadWithPlist:(id)plist {
    NSString *name = plist[[MTDataTable keyName]];
    if (name == nil) {
        name = @"";
    }
    [self setName: name];
    
    NSString *keyColumnKeys = [MTDataTable keyColumnKeys];
    id columnKeysArray = plist[keyColumnKeys];
    
    NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithArray:columnKeysArray];
    [self setColumnKeys: columnKeys];
    
    NSArray *sortDescriptorsArray = plist[[MTDataTable keySortDescriptors]];
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] initWithArray:sortDescriptorsArray];
    [self setSortDescriptors:sortDescriptors];
    
    NSDictionary *columnsPlist = [[NSDictionary alloc] initWithDictionary:plist[[MTDataTable keyColumns]]];

    for (NSString *key in [self columnKeys]) {
            NSDictionary *columnPlist = [[NSDictionary alloc] initWithDictionary:columnsPlist[key]];
            MTDataColumn *column = [[MTDataColumn alloc] initWithPlist: columnPlist];
            [self columns][key] = column;
    }
    
    NSNumber *rowCounterObj = plist[[MTDataTable keyRowCounter]];
    self.rowCounter = rowCounterObj.unsignedIntegerValue;
    
}

- (NSDictionary *)columnsPlist {
    
    NSMutableDictionary *columnsPlist = [[NSMutableDictionary alloc] initWithCapacity:[self numberOfColumns]];
    for (NSString *key in [self columnKeys]) {
        MTDataColumn *dataColumn = [self columns][key];
        columnsPlist[key] = [dataColumn plist];
    }
    return columnsPlist;
}

- (void)addColumn:(MTDataColumn *)column {}
- (void)addRow:(NSArray *)row {}
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {}

- (void)removeAllObjects {}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    return nil;
}

- (id)objectAtRow:(NSUInteger)row {
    return nil;
}

- (NSEnumerator *)columnsEnumerator {
    return nil;
}
- (NSEnumerator *)objectEnumerator {
    return nil;
}

- (void)beginBulkInsert {}
- (void)endBulkInsert {}

- (NSArray *)allObjects {
    return @[];
}

- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
    return @[];
}

- (NSUInteger)count {
    return 0;
}

- (NSUInteger)numberOfColumns {
    return 0;
}

- (NSUInteger)numberOfRows {
    return 0;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return 0;
}

+ (NSString *)keyName {
    SEL selName = @selector(name);
    return NSStringFromSelector(selName);
}

+ (NSString *)keyColumnKeys {
    SEL selColumnKeys = @selector(columnKeys);
    return NSStringFromSelector(selColumnKeys);
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}

+ (NSString *)keyRowCounter {
    SEL selRowCounter = @selector(rowCounter);
    return NSStringFromSelector(selRowCounter);
}
+ (NSString *)keySortDescriptors {
    SEL selSortDescriptors = @selector(sortDescriptors);
    return NSStringFromSelector(selSortDescriptors);
}

@end
