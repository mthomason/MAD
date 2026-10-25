//
//  MADReportTextRepresentation.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADReportTextRepresentation.h"
#import "MADReportPageRepresentation.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>

typedef NSMutableDictionary <NSNumber *, __kindof MADReportPageRepresentation *> MADReportPageMap;

@interface MADReportTextRepresentation ()

	@property (nonatomic, strong, getter=hasPages, readwrite) MADReportPageMap *pages;

@end

@implementation MADReportTextRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (void)dealloc {
	[_pages removeAllObjects];
}

- (instancetype)init {
	id r = [self initWithPageCount: 0];
	return r;
}

- (instancetype)initWithPageCount:(NSUInteger)pageCount {
	if (self = [super init]) {
		id pages = pageCount > 0 ? [[MADReportPageMap alloc] initWithCapacity:pageCount] :
								   [[MADReportPageMap alloc] init];
		_pages = pages;
	}
	return self;
}

- (MADReportPageRepresentation *)pageIndex:(NSUInteger)pageIndex {
	id p = [[NSNumber alloc] initWithUnsignedInteger: pageIndex];
	MADReportPageRepresentation *result = self.pages[p];
	return result;
}

- (void)setPage:(MADReportPageRepresentation *)page forPageIndex:(NSUInteger)pageIndex {
	id p = [[NSNumber alloc] initWithUnsignedInteger: pageIndex];
	(self.pages)[p] = page;
}

- (void)removeAllPages {
	[self.pages removeAllObjects];
}

- (NSUInteger)numberOfPages { return self.pages.count; }

#pragma mark - MADTextRepresentationProtocol

// `pages` is a dictionary keyed by page index, so the bare fast-enumeration yields the
// NSNumber keys.  Iterate the values.
- (NSUInteger)characterCount {
	NSUInteger characterCount = 0;
	for (MADReportPageRepresentation *page in self.pages.allValues) {
		characterCount += [page characterCount];
	}
	return characterCount;
}

- (NSUInteger)elementCount {
	NSUInteger elementCount = 0;
	for (MADReportPageRepresentation *page in self.pages.allValues) {
		elementCount += [page elementCount];
	}
	return elementCount;
}

@end
