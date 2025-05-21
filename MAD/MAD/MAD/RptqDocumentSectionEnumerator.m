//
//  SectionEnumerator.m
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentSectionEnumerator.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqDocumentSection+Extras.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

@interface RptqDocumentSectionTypeEnumerator ()

@end

@implementation RptqDocumentSectionTypeEnumerator {
	NSUInteger _total;
	NSUInteger _current;
}

- (instancetype)initWithQueryID:(NSManagedObjectID *)queryID
		   managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	if (self = [super init]) {
		_total = [RptqQuery sectionCountFectch:queryID managedObjectContext:managedObjectContext];
		_current = 0;
	}
	return self;
}

- (NSUInteger)count {
	return _total;
}

- (NSArray *)allObjects {
	
	NSMutableArray *sectionTypes = [[NSMutableArray alloc] initWithCapacity:(_total - _current)];
	for (; _current<_total; _current++) {
		@autoreleasepool {
			NSNumber *section;
			section = @([RptqDocumentSection getSectionTypeforRow: _current
											 withNumberOfSections: _total]);
			[sectionTypes addObject:section];
			section = nil;
		}
	}
	return sectionTypes;
}

- (id)nextObject {
	return @([RptqDocumentSection getSectionTypeforRow: ++_current
								  withNumberOfSections: _total]);
}

@end

@interface RptqDocumentSectionEnumerator ()

	@property (nonatomic, assign)   NSUInteger numberOfGroups;
	@property (nonatomic, assign)   NSUInteger total;
	@property (nonatomic, weak)     RptqDocument *document;

@end

@implementation RptqDocumentSectionEnumerator

- (instancetype)initWithDocument:(RptqDocument *)document {
	if (self = [super init]) {
		RptqQuery *query = document.mainQuery;
		_numberOfGroups = document.mainQuery.hasQueryGroups.count;
		_total = [query sectionCount];
		_document = document;
		self.current = 0;
	}
	return self;
}

- (NSUInteger)count {
	return _total;
}

- (NSArray *)allObjects {
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:(_total - _current)];
	for (; _current<_total; _current++) {
		@autoreleasepool {
			RptqDocumentSection *section = [_document documentSectionForSelectedIndex: _current
																   withNumberOfGroups: _numberOfGroups];
			[result addObject:section];
		}
	}
	return result;
}

- (id)nextObject {
	id result = [_document documentSectionForSelectedIndex: _current
										withNumberOfGroups: _numberOfGroups];
	_current++;
	return result;
}

@end
