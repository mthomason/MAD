//
//  MADReportTextRepresentation.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReportTextRepresentation.h"
#import "MADReportPageRepresentation.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>

@interface MADReportTextRepresentation ()

    @property (nonatomic, strong, getter=hasPages, readwrite) NSMutableDictionary <__kindof NSNumber *, __kindof MADReportPageRepresentation *> *pages;

@end

@implementation MADReportTextRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (void)dealloc {
    [_pages removeAllObjects];
}

- (instancetype)init {
    if (self = [super init]) {
        NSMutableDictionary *pages = [[NSMutableDictionary alloc] init];
        self.pages = pages;
    }
    return self;
}

- (instancetype)initWithPageCount:(NSUInteger)pageCount {
    if (self = [super init]) {
        NSMutableDictionary *pages = pageCount > 0 ? [[NSMutableDictionary alloc] initWithCapacity:pageCount] :
                                                     [[NSMutableDictionary alloc] init];
        self.pages = pages;
    }
    return self;
}

- (MADReportPageRepresentation *)pageIndex:(NSUInteger)pageIndex {
    NSNumber *p = [[NSNumber alloc] initWithUnsignedInteger: pageIndex];
    MADReportPageRepresentation *result = self.pages[p];
    return result;
}

- (void)setPage:(MADReportPageRepresentation *)page forPageIndex:(NSUInteger)pageIndex {
    NSNumber *p = [[NSNumber alloc] initWithUnsignedInteger: pageIndex];
    [self.pages setObject:page forKey:p];
}

- (void)removeAllPages {
    [self.pages removeAllObjects];
}

- (NSUInteger)numberOfPages { return self.pages.count; }

#pragma mark - MADTextRepresentationProtocol

- (NSUInteger)characterCount {
    NSUInteger characterCount = 0;
    for (MADReportPageRepresentation *page in self.pages) {
        characterCount += [page characterCount];
    }
    return characterCount;
}

- (NSUInteger)elementCount {
    NSUInteger elementCount = 0;
    for (MADReportPageRepresentation *page in self.pages) {
        elementCount += [page elementCount];
    }
    return elementCount;
}

@end
