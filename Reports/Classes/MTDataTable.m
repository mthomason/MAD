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
#import "MTDataTableVirtual.h"
#import "MTDataTableFast.h"
#import "MTDataColumn.h"
#import "NSFileManager+Common.h"
#import "MTLog.h"

@interface MTDataTable ()

@end

@implementation MTDataTable

- (NSEnumerator *)enumeratorForRowIds:(NSIndexSet *)rowids {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
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

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys accending:(BOOL)accending {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId {
    NSAssert(false, @"Not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

+ (id)dataTableFactory:(NSDictionary *)parameters {

    NSNumber *keyDataTableType = @(MTDataTableTypeOfTable);
    NSNumber *keyDataTableObjectId = @(MTDataTableObjectId);
    NSNumber *keyDataTableNumberOfColumns = @(MTDataTableNumberOfColumns);

    NSNumber *dataTableType = parameters[keyDataTableType];
    NSNumber *dataTableObjectId = parameters[keyDataTableObjectId];
    NSNumber *datatableNumberOfColumns = parameters[keyDataTableNumberOfColumns];
    
    NSUInteger numberOfColumns = 0;
    BOOL numberOfColumnsHack = NO;
    BOOL objectIdSet = NO;
    
    id result = nil;
    
    if (datatableNumberOfColumns != nil) {
        numberOfColumnsHack = YES;
        numberOfColumns = [datatableNumberOfColumns integerValue];
    }
    
    //Default type is virtual. If there is no object id, then type MUST be virtual.  That's
    //  because we won't know where to store it.
    MTDataTableType type = MTDataTableTypeVirtual;
    NSUInteger objectId = 0;
    if (dataTableType != nil && dataTableObjectId != nil) {
        type = [dataTableType integerValue];
    }

    if (dataTableObjectId != nil) {
        objectIdSet = YES;
        objectId = [dataTableObjectId integerValue];
    }
    
    switch (type) {
        case MTDataTableTypeVirtual: {
            if (objectIdSet) {
                result = [[MTDataTableVirtual alloc] initWithId:objectId];
            } else {
                if (numberOfColumnsHack) {
                    result = [[MTDataTableVirtual alloc] initWithNumberOfColumns:numberOfColumns];
                } else {
                    result = [[MTDataTableVirtual alloc] initWithId:objectId];
                }
            }
            break;
        }
        case MTDataTableTypePhysical: {
            result = [[MTDataTableFast alloc] initWithId:objectId];
            break;
        }
        default:
            NSAssert(false, @"Not implemented.");
            break;
    }
    return result;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject:  [self sortDescriptors]  forKey:[MTDataTable keySortDescriptors]];
    [encoder encodeObject:  [self url]              forKey:[MTDataTable keyUrl]];
    [encoder encodeObject:  [self name]             forKey: [MTDataTable keyName]];
    [encoder encodeObject:  [self columnKeys]       forKey: [MTDataTable keyColumnKeys]];
    [encoder encodeObject:  [self columns]          forKey: [MTDataTable keyColumns]];
    [encoder encodeInteger: [self rowCounter]       forKey: [MTDataTable keyRowCounter]];

}

+ (NSString *)keyUrl {
    return @"url";
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {
        NSString *name =                [decoder decodeObjectForKey: [MTDataTable keyName]];
        [self setName: name];
        
        NSMutableArray *columnKeys =    [decoder decodeObjectForKey: [MTDataTable keyColumnKeys]];
        [self setColumnKeys: columnKeys];
        
        NSMutableDictionary *columns =  [decoder decodeObjectForKey: [MTDataTable keyColumns]];
        [self setColumns: columns];
        
        NSUInteger rowCounter =         [decoder decodeIntegerForKey: [MTDataTable keyRowCounter]];
        [self setRowCounter:rowCounter];
        
        NSMutableArray *sortDescriptors = [decoder decodeObjectForKey:[MTDataTable keySortDescriptors]];
        [self setSortDescriptors:sortDescriptors];

        NSURL *url = [decoder decodeObjectForKey:[MTDataTable keyUrl]];
        [self setUrl:url];
                
   }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initalizeWithObjectId:0];
    }
    return self;
}

- (id)initWithId:(NSUInteger)objectId {
    self = [super init];
    if (self) {
        [self initalizeWithObjectId:objectId];
    }
    return self;
}

- (void)initalizeWithObjectId:(NSUInteger)objectId {
    NSString *name = @"";
    [self setName:name];
    
    NSMutableArray *columnKeys = [[NSMutableArray alloc] init];
    [self setColumnKeys:columnKeys];
    
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
    [self setSortDescriptors:sortDescriptors];
    
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
    [self setColumns:columns];
    
    [self setRowCounter:0];
    
    [self setObjectId:objectId];
    
    [self loadFromCache];
    
}

- (void)setObjectId:(NSUInteger)objectId {
    NSString *filename = [NSFileManager filenameId:objectId extention:@"mcache"];
    NSURL *cacheDirectory = [NSFileManager cacheDirectory];
    NSURL *fileUrl = [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
    [self setUrl:fileUrl];
}

- (void)loadFromCache {
    NSString *path = [[self url] path];
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath: path];
    [inputStream open];
    switch ([inputStream streamStatus]) {
        case NSStreamStatusError:
            break;
        default:
            break;
    }
    NSPropertyListFormat format;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithStream:inputStream options:0 format:&format error:&error];
    if (plist) {
        [self loadWithPlist:plist];
    }
}

- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    self = [super init];
    if (self) {
        
        NSString *name = @"";
        [self setName:name];
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        [self setColumnKeys:columnKeys];
        
        NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
        [self setSortDescriptors:sortDescriptors];
                
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
        [self setColumns:columns];
        
        [self setRowCounter:0];
    }
    return self;
}

- (void)cachePlist:(id)data {
    NSError *error = nil;
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList:data format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if ([self url]) {
        NSDataWritingOptions mask = NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen;
        [cache writeToURL:[self url] options:mask error:&error];
        if (error) {
            MTLog(@"Error: %@", error);
            error = nil;
            [cache writeToURL:[self url] options:mask error:&error];
        }
    }
}

- (void)cache {
    NSDictionary *plist = [self plist];
    [self cachePlist:plist];
}

- (NSDictionary *)columnsPlist {
    
    NSMutableDictionary *columnsPlist = [[NSMutableDictionary alloc] initWithCapacity:[self numberOfColumns]];
    for (NSString *key in [[self columns] keyEnumerator]) {
        MTDataColumn *dataColumn = [[self columns] objectForKey:key];
        columnsPlist[key] = [dataColumn plist];
    }
    return columnsPlist;
}

- (id)plist {
    
    NSString *keyName = [MTDataTable keyName];
    NSString *keyColumnKeys = [MTDataTable keyColumnKeys];
    NSString *keyColumns = [MTDataTable keyColumns];
    NSString *keyRowCounter = [MTDataTable keyRowCounter];
    NSNumber *rowCounter = @([self rowCounter]);
    
    NSArray *columnKeys = [[NSArray alloc] initWithArray:[self columnKeys]];
    NSDictionary *columnsPlist = [self columnsPlist];
    
    return @{
             keyName        : [self name],
             keyColumnKeys  : columnKeys,
             keyColumns     : columnsPlist,
             keyRowCounter  : rowCounter,
             };
}

- (void)loadWithPlist:(id)plist {
    NSString *name = [plist objectForKey: [MTDataTable keyName]];
    if (name == nil) {
        name = @"";
    }
    [self setName: name];
    
    NSString *keyColumnKeys = [MTDataTable keyColumnKeys];
    id columnKeysArray = [plist objectForKey: keyColumnKeys];
    
    NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithArray:columnKeysArray];
    [self setColumnKeys: columnKeys];
    
    NSArray *sortDescriptorsArray = [plist objectForKey:[MTDataTable keySortDescriptors]];
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] initWithArray:sortDescriptorsArray];
    [self setSortDescriptors:sortDescriptors];
    
    NSDictionary *columnsPlist = [[NSDictionary alloc] initWithDictionary:[plist objectForKey: [MTDataTable keyColumns]]];
    
    NSUInteger count = [columnsPlist count];
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:count];
    for (NSString *key in [columnsPlist keyEnumerator]) {
        @autoreleasepool {
            NSDictionary *columnPlist = [[NSDictionary alloc] initWithDictionary:columnsPlist[key]];
            MTDataColumn *column = [[MTDataColumn alloc] initWithPlist: columnPlist];
            columns[key] = column;
        }
    }
    [self setColumns: columns];
    
    NSUInteger rowCounter = [[plist objectForKey: [MTDataTable keyRowCounter]] integerValue];
    [self setRowCounter:rowCounter];
    
}

- (void)addColumn:(MTDataColumn *)column {}
- (void)addRow:(NSArray *)row {}
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {}

- (void)removeAllObjects {}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    return nil;
}

- (id)objectAtRow:(NSInteger)row {
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

- (NSArray *)objectAtRow:(NSInteger)row limit:(NSUInteger)limit {
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
