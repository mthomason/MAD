//
//  MADReportPageRepresentation.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import <Foundation/NSArray.h>

typedef NSMutableArray <__kindof MADReportSectionRepresentation *> MADReportSectionArray;

@interface MADReportPageRepresentation ()

	@property (nonatomic, strong, getter=hasSections) MADReportSectionArray *sections;

@end

@implementation MADReportPageRepresentation

@synthesize elementOffset = _elementOffset;
@synthesize characterOffset = _characterOffset;

- (void)dealloc {
	[_sections removeAllObjects];
}

- (instancetype)init {
	id r = [self initWithNumberOfSections: 0];
	return r;
}

- (instancetype)initWithNumberOfSections:(NSUInteger)count {
	if (self = [super init]) {
		id sections;
		sections = count > 0 ? [[MADReportSectionArray alloc] initWithCapacity:count] :
							   [[MADReportSectionArray alloc] init];
		_sections = sections;
	}
	return self;
}

- (void)addSection:(nonnull MADReportSectionRepresentation *)section {
	[self.sections addObject:section];
}

- (NSUInteger)numberOfSections {
	return self.sections.count;
}

- (NSArray <__kindof MADReportSectionRepresentation *> *)allSections {
	return self.sections.copy;
}

#pragma mark - MADTextRepresentationProtocol

- (NSUInteger)characterCount {
	NSUInteger characterCount = 0;
	for (MADReportSectionRepresentation *section in self.sections) {
		characterCount += [section characterCount];
	}
	return characterCount;
}

- (NSUInteger)elementCount {
	NSUInteger elementCount = 0;
	for (MADReportSectionRepresentation *section in self.sections) {
		elementCount += [section elementCount];
	}
	return elementCount;
}

@end
