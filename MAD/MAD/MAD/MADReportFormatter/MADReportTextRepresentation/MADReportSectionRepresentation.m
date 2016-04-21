//
//  MADReportSectionRepresentation.m
//  MAD
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"
#import <Foundation/NSArray.h>

@interface MADReportSectionRepresentation ()

    @property (nonatomic, strong, getter=hasRows) NSMutableArray <__kindof MADReportSectionRowsRepresentation *> *rows;

@end

@implementation MADReportSectionRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (void)dealloc {
    [_rows removeAllObjects];
}

- (instancetype)init {
    if (self = [super init]) {
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        self.rows = rows;
    }
    return self;
}

- (instancetype)initWithNumberOfRows:(NSUInteger)capacity {
    if (self = [super init]) {
        NSMutableArray *rows = capacity > 0 ? [[NSMutableArray alloc] initWithCapacity:capacity] :
                                                [NSMutableArray new];
        self.rows = rows;
    }
    return self;
}

- (void)addRow:(MADReportSectionRowsRepresentation *)row {
    [self.rows addObject:row];
}

- (NSUInteger)numberOfRows { return self.rows.count; }

#pragma mark - MADTextRepresentationProtocol

- (NSUInteger)characterCount {
    NSUInteger characterCount = 0;
    for (MADReportSectionRowsRepresentation *row in self.rows) {
        characterCount += [row characterCount];
    }
    return characterCount;
}

- (NSUInteger)elementCount {
    NSUInteger elementCount = 0;
    for (MADReportSectionRowsRepresentation *row in self.rows) {
        elementCount += [row elementCount];
    }
    return elementCount;
}

@end
