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
#import "MACloudManager.h"
#import "MTAggregateFunctionType.h"

@interface MTDataTable ()

@end

@implementation MTDataTable

- (id)resultsForAggregateType:(MTAggregateGroupByType)groupByType
                     function:(MTAggregateFunctionType)function
                     fieldKey:(NSString *)fieldKey
                    groupKeys:(NSArray *)groupKeys
                       rowids:(NSArray *)rowids {
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

+ (MTDataTable *)newDataTableForIdentifier:(NSString *)identifier {
    NSUInteger hash = [identifier hash];
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(hash);
    return [MTDataTable dataTableFactory:@{
                                           typeKey : type,
                                           objectIdKey : objectIdV}];
}

+ (instancetype)dataTableFactory:(NSDictionary *)parameters {

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
    
    NSNumber *objid = @(self.tag);
    [encoder encodeObject:  objid                   forKey: @"objid"];
    [encoder encodeObject:  [self sortDescriptors]  forKey: [MTDataTable keySortDescriptors]];
    [encoder encodeObject:  [self url]              forKey: [MTDataTable keyUrl]];
    [encoder encodeObject:  [self name]             forKey: [MTDataTable keyName]];
    [encoder encodeObject:  [self columnKeys]       forKey: [MTDataTable keyColumnKeys]];
    [encoder encodeObject:  [self columns]          forKey: [MTDataTable keyColumns]];
    [encoder encodeInteger: [self rowCounter]       forKey: [MTDataTable keyRowCounter]];
    
}

+ (NSString *)keyUrl {
    return @"url";
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
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

        NSNumber *objid = [decoder decodeObjectForKey:@"objid"];
        self.tag = [objid unsignedIntegerValue];
        
   }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initalizeWithObjectId:0 fromCache:NO];
    }
    return self;
}

- (instancetype)initWithId:(NSUInteger)objectId {
    return [self initWithId:objectId fromCache:YES];
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    self = [super init];
    if (self) {
        [self initalizeWithObjectId:objectId fromCache:fromCache];
    }
    return self;
}

- (void)initalizeWithObjectId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    NSString *name = @"";
    [self setName:name];
    
    NSMutableArray *columnKeys = [[NSMutableArray alloc] init];
    [self setColumnKeys:columnKeys];
    
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
    [self setSortDescriptors:sortDescriptors];
    
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
    [self setColumns:columns];
    
    [self setRowCounter:0];
    
    [self setTag:objectId];

    //if (fromCache) {
    //    [self loadFromCache];
    //}
}

- (NSURL *)url {
    NSString *filename = [MACloudManager filenameId:self.tag extention:@"mdcache"];
    NSURL *cacheDirectory = self.cacheDelegate == nil ? [[NSFileManager defaultManager] localCacheDirectory] : [[self cacheDelegate] cachedFilesDirectory];
    return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (void)loadFromCache {
    NSString *path = [self url].path;
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
    id plist = [NSPropertyListSerialization propertyListWithStream: inputStream
                                                           options: 0
                                                            format: &format
                                                             error: &error];
    if (plist) {
        [self loadWithPlist:plist];
    }
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
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
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList: data
                                                               format: NSPropertyListBinaryFormat_v1_0
                                                              options: 0
                                                                error: &error];
    if ([self url]) {
        [cache writeToURL:[self url]
                  options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen
                    error:&error];
        NSAssert(@"%s %@", __PRETTY_FUNCTION__, error);
    }
}

- (void)cache {
    NSDictionary *plist = [self plist];
    [self cachePlist:plist];
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
             keyName        : [self name],
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
    NSUInteger rowCounter = [rowCounterObj integerValue];
    [self setRowCounter:rowCounter];
    
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
