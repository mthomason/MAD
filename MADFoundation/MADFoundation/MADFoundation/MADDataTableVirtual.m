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

@property (nonatomic, strong, readwrite) NSMutableArray *sortIndex;

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
		self.sortIndex = [[NSMutableArray alloc] init];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		self.sortIndex = [decoder decodeObjectForKey:[MADDataTableVirtual keySortIndex]];
	}
	return self;
}

- (instancetype)initWithId:(NSUInteger)objectId {
	if (self = [super initWithId:objectId]) {
		self.sortIndex = [[NSMutableArray alloc] init];
	}
	return self;
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
	if (self = [super initWithNumberOfColumns:numberOfColumns]) {
		self.sortIndex = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeObject:_sortIndex forKey:[MADDataTableVirtual keySortIndex]];
}

- (BOOL)loadWithPlist:(nonnull NSDictionary *)plist error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
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
	return loadWithPlist;
}

- (NSDictionary *)copyPlist {
	NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:[super copyPlist]];
	plist[[MADDataTableVirtual keySortIndex]] = self.sortIndex;
	return plist;
}

- (void)addColumn:(MADDataColumn *)column {
	NSString *identifier = [column.identifier copy];
	[self.columnKeys addObject:identifier];
	self.columns[identifier] = column;
}

- (NSArray *)allObjects {
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
	return sortedIndex;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])stackbuf
									count:(NSUInteger)len {
	return [_sortIndex countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index { return [self objectAtRow:index]; }
- (id)objectAtIndex:(NSUInteger)index { return [self objectAtRow:index]; }
- (id)objectAtRow:(NSUInteger)row { return [self.sortIndex objectAtIndex:row]; }
- (NSEnumerator *)objectEnumerator { return [self.sortIndex objectEnumerator]; }
- (NSEnumerator *)columnsEnumerator { return [self.columns objectEnumerator]; }

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];
}

- (bool)addRow:(NSArray *)row error:(NSError * __autoreleasing *)error {
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
	[self.sortIndex sortUsingDescriptors:sortDescriptors];
	[self.sortDescriptors removeAllObjects];
	[self.sortDescriptors addObjectsFromArray:sortDescriptors];
}

- (NSUInteger)count { return [self numberOfRows]; }

- (NSUInteger)numberOfColumns { return (self.columnKeys).count; }

+ (NSString *)keySortIndex { return NSStringFromSelector(@selector(sortIndex)); }

- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
	NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(row, limit)];
	return [self.sortIndex objectsAtIndexes:indexSet];
}

- (void)removeAllObjects {
	for (MADDataColumn *column in [self.columns objectEnumerator]) {
		[column removeAllObjects];
	}
	[self.columns removeAllObjects];
	[self.columnKeys removeAllObjects];
	[self.sortIndex removeAllObjects];
	[self.sortDescriptors removeAllObjects];
	self.rowCounter = 0;
}

- (void)beginBulkInsert { }

- (void)endBulkInsert { }

@end
