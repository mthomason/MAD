//
//  MADReportSectionRowsRepresentation.m
//  MAD
//
//  Created by Michael Thomason on 10/30/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionRowsRepresentation.h"
#import <UIKit/UIGeometry.h>
#import "MADReportLineRepresentation.h"

typedef NSMutableSet <MADReportLineRepresentation *>  MADMutableSetReportLines;

@interface MADReportSectionRowsRepresentation ()

    @property (nonatomic, strong, getter=hasLines) MADMutableSetReportLines *lines;

@end

@implementation MADReportSectionRowsRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (void)dealloc {
    [_lines removeAllObjects];
}

- (instancetype)init {
    return [self initWithNumberOfSectionRowElements:0];
}

- (instancetype)initWithNumberOfSectionRowElements:(NSUInteger)elementCount {
    if (self = [super init]) {
        MADMutableSetReportLines *lines;
        lines = [[MADMutableSetReportLines alloc] initWithCapacity:elementCount];
        self.lines = lines;
    }
    return self;
}

- (void)addLine:(nonnull MADReportLineRepresentation *)line {
    [self.lines addObject:line];
}

- (NSArray <__kindof MADReportLineRepresentation *> *)allLines {
    return [self.lines.allObjects sortedArrayUsingComparator:accessibilityLineComparson];
}

- (NSUInteger)isItemCount { return self.lines.count; }

#pragma mark - Helper

//FIXME: Put these in order before storing them... perhaps on background queue...

NSComparator accessibilityLineComparson = ^NSComparisonResult(MADReportLineRepresentation *  _Nonnull obj1, MADReportLineRepresentation *  _Nonnull obj2) {
    // Sort from left to right.
    if (obj1.frame.origin.y < obj2.frame.origin.y) {
        return NSOrderedAscending;
    } else if (obj1.frame.origin.y == obj2.frame.origin.y && obj1.frame.origin.x < obj2.frame.origin.x) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
};

#pragma mark - MADTextRepresentationProtocol

- (NSUInteger)characterCount {
    NSUInteger characterCount = 0;
    for (MADReportLineRepresentation *line in self.lines) {
        characterCount += [line characterCount];
    }
    return characterCount;
}

- (NSUInteger)elementCount {
    NSUInteger elementCount = 0;
    for (MADReportLineRepresentation *line in self.lines) {
        elementCount += [line elementCount];
    }
    return elementCount;
}

@end
