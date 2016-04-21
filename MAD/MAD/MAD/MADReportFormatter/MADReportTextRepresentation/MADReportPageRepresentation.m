//
//  MADReportPageRepresentation.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import <Foundation/NSArray.h>

@interface MADReportPageRepresentation ()

    @property (nonatomic, strong, getter=hasSections) NSMutableArray <__kindof MADReportSectionRepresentation *> *sections;

@end

@implementation MADReportPageRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (void)dealloc {
    [_sections removeAllObjects];
}

- (instancetype)init {
    if (self = [super init]) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        self.sections = sections;
    }
    return self;
}

- (instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections {
    if (self = [super init]) {
        NSMutableArray *sections = numberOfSections > 0 ? [[NSMutableArray alloc] initWithCapacity:numberOfSections] :
                                                            [NSMutableArray new];
        self.sections = sections;
    }
    return self;
}

- (void)addSection:(nonnull MADReportSectionRepresentation *)section {
    [self.sections addObject:section];
}

- (NSUInteger)numberOfSections {
    return self.sections.count;
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
