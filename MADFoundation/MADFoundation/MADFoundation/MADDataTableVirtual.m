//
//  MADDataTableVirtual.m
//  MAD
//
//  Created by Michael Thomason on 4/25/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDataTableVirtual.h"
#import <Foundation/NSStream.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSDictionary.h>
#import <MADFoundation/MADDataColumn.h>
#import "madlog.h"

@interface MADDataTableVirtual ()

	@property (nonatomic, strong) NSInputStream *inputStream;
	@property (nonatomic, strong) NSOutputStream *outputStream;

	@property (nonatomic, strong, readwrite) NSMutableArray *sortIndex;     // A sorted array of dictionaries

@end

@implementation MADDataTableVirtual

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
	NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
	NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSDictionary *)dataForRow:(NSUInteger)cacheId {
	NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys {
	NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
	NSAssert(NO, @"Not implemented: %s", __PRETTY_FUNCTION__);
	return nil;
}

- (instancetype)init {
	if (self = [super init]) {
		os_log_info(GetFoundationLog(), "%s: Initializing default", __PRETTY_FUNCTION__);
		self.sortIndex = [[NSMutableArray alloc] init];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		os_log_info(GetFoundationLog(), "%s: Initializing with coder", __PRETTY_FUNCTION__);
		self.sortIndex = [decoder decodeObjectForKey:[MADDataTableVirtual keySortIndex]];
	}
	return self;
}

- (instancetype)initWithId:(NSUInteger)objectId {
	if (self = [super initWithId:objectId]) {
		os_log_info(GetFoundationLog(), "%s: Initializing with ID %lu", __PRETTY_FUNCTION__, (unsigned long)objectId);
		self.sortIndex = [[NSMutableArray alloc] init];
	}
	return self;
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
	if (self = [super initWithNumberOfColumns:numberOfColumns]) {
		os_log_info(GetFoundationLog(), "%s: Initializing with %lu columns", __PRETTY_FUNCTION__, (unsigned long)numberOfColumns);
		self.sortIndex = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	os_log_info(GetFoundationLog(), "%s: Encoding object", __PRETTY_FUNCTION__);
	[super encodeWithCoder:encoder];
	[encoder encodeObject:_sortIndex forKey:[MADDataTableVirtual keySortIndex]];
}

- (BOOL)loadWithPlist:(nonnull NSDictionary *)plist error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
	os_log_info(GetFoundationLog(), "%s", __PRETTY_FUNCTION__);
	NSError *loadWithPlistError = nil;
	BOOL loadWithPlist = [super loadWithPlist:plist error:&loadWithPlistError];
	if (loadWithPlistError != nil) {
		os_log_error(GetFoundationLog(), "Error loading plist: %@", loadWithPlistError);
		if (outError) {
			*outError = [loadWithPlistError copy];
		}
	}
	if (!loadWithPlist) {
		return NO;
	}
	
	self.sortIndex = [plist[[MADDataTableVirtual keySortIndex]] mutableCopy];
	os_log_info(GetFoundationLog(), "Loaded sort index with %lu entries", (unsigned long)self.sortIndex.count);
	return loadWithPlist;
}

- (NSDictionary *)copyPlist {
	os_log_info(GetFoundationLog(), "%s", __PRETTY_FUNCTION__);
	NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:[super copyPlist]];
	plist[[MADDataTableVirtual keySortIndex]] = self.sortIndex;
	return plist;
}

- (void)addColumn:(MADDataColumn *)column {
	os_log_info(GetFoundationLog(), "%s: Adding column with identifier %@", __PRETTY_FUNCTION__, column.identifier);
	NSString *identifier = [column.identifier copy];
	[self.columnKeys addObject:identifier];
	self.columns[identifier] = column;
}

- (NSArray *)allObjects {
	os_log_info(GetFoundationLog(), "%s", __PRETTY_FUNCTION__);
	return [self.sortIndex copy];
}

- (NSUInteger)numberOfRows { return self.rowCounter; }

- (NSUInteger)sortedIndexForIndex:(NSUInteger)index {
	NSUInteger sortedIndex;
	if ((self.sortDescriptors).count > 0) {
		sortedIndex = [self.sortIndex indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			if ([obj[@"~rowid~"] unsignedIntegerValue] == index) {
				*stop = YES;
				return YES;
			}
			return NO;
		}];
	} else {
		sortedIndex = index;
	}
	os_log_info(GetFoundationLog(), "%s: Mapped index %lu to sorted index %lu", __PRETTY_FUNCTION__, (unsigned long)index, (unsigned long)sortedIndex);
	return sortedIndex;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
	return [self objectAtRow:idx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])stackbuf
									count:(NSUInteger)len {
	return [_sortIndex countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSEnumerator *)objectEnumerator {
	return [self.sortIndex objectEnumerator];
}

- (NSEnumerator *)columnsEnumerator {
	return [self.columns objectEnumerator];
}

- (id)objectAtRow:(NSUInteger)row {
	id obj = self.sortIndex[row];
	os_log_info(GetFoundationLog(), "%s: Accessed object at row %lu, class: %@", __PRETTY_FUNCTION__, (unsigned long)row, NSStringFromClass([obj class]));
	return obj;
}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	NSUInteger sortedIndex = [self sortedIndexForIndex:row];
	id objectForField = [dataInColumn objectAtIndex:sortedIndex];
	os_log_info(GetFoundationLog(), "%s: Object at row %lu, column %lu (key %@): class %@", __PRETTY_FUNCTION__, (unsigned long)row, (unsigned long)column, fieldKey, NSStringFromClass([objectForField class]));
	return objectForField;
}

- (id)objectAtIndex:(NSUInteger)index {
	NSUInteger sortedIndex = [self sortedIndexForIndex:index];
	NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:(self.columnKeys).count];
	for (NSString *key in self.columnKeys) {
		if (key.length > 0) {
			NSArray *dataInColumn = self.columns[key];
			NSAssert(NO, @"Remove after testing this warning.");
			id objectForField = dataInColumn[sortedIndex];
			os_log_info(GetFoundationLog(), "%s: object[%lu][%@] = %@ (%@)", __PRETTY_FUNCTION__, (unsigned long)index, key, objectForField, NSStringFromClass([objectForField class]));
			data[key] = objectForField;
		}
	}
	return data;
}

- (bool)addRow:(NSArray *)row error:(NSError * __autoreleasing *)error {
	os_log_info(GetFoundationLog(), "%s: Adding row with %lu values", __PRETTY_FUNCTION__, (unsigned long)row.count);
	NSUInteger index = 0;
	NSUInteger numberOfColumns = [self numberOfColumns];
	NSMutableDictionary *indexedRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
	NSNumber *ogRowIndex = @(self.rowCounter);
	for (id object in row) {
		NSString *key = self.columnKeys[index];
		MADDataColumn *column = self.columns[key];
		[column addObject:object];
		indexedRow[key] = object;
		indexedRow[@"~rowid~"] = ogRowIndex;
		index++;
	}
	[self.sortIndex addObject:indexedRow];
	self.rowCounter++;
	return true;
}

- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {
	os_log_info(GetFoundationLog(), "%s: Adding row with field keys", __PRETTY_FUNCTION__);
	for (id key in self.columnKeys) {
		MADDataColumn *column = self.columns[key];
		id obj = row[key];
		if (obj == nil) obj = @"";
		[column addObject:obj];
	}
	[self.sortIndex addObject:row];
	self.rowCounter++;
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {
	os_log_info(GetFoundationLog(), "%s: Sorting with %lu descriptors", __PRETTY_FUNCTION__, (unsigned long)sortDescriptors.count);
	[self.sortIndex sortUsingDescriptors:sortDescriptors];
	[self.sortDescriptors removeAllObjects];
	[self.sortDescriptors addObjectsFromArray:sortDescriptors];
}

- (NSUInteger)count { return [self numberOfRows]; }

- (NSUInteger)numberOfColumns { return (self.columnKeys).count; }

+ (NSString *)keySortIndex { return NSStringFromSelector(@selector(sortIndex)); }

- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
	os_log_info(GetFoundationLog(), "%s: Getting %lu objects starting at row %lu", __PRETTY_FUNCTION__, (unsigned long)limit, (unsigned long)row);
	NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(row, limit)];
	return [self.sortIndex objectsAtIndexes:indexSet];
}

- (void)removeAllObjects {
	os_log_info(GetFoundationLog(), "%s: Removing all objects", __PRETTY_FUNCTION__);
	for (MADDataColumn *column in [self.columns objectEnumerator]) {
		[column removeAllObjects];
	}
	[self.columns removeAllObjects];
	[self.columnKeys removeAllObjects];
	[self.sortIndex removeAllObjects];
	[self.sortDescriptors removeAllObjects];
	self.rowCounter = 0;
}

- (void)beginBulkInsert {
	os_log_info(GetFoundationLog(), "%s: Begin bulk insert", __PRETTY_FUNCTION__);
}

- (void)endBulkInsert {
	os_log_info(GetFoundationLog(), "%s: End bulk insert", __PRETTY_FUNCTION__);
}

@end
