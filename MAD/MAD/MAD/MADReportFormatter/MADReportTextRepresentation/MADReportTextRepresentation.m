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

@interface MADReportTextRepresentation ()

    @property (nonatomic, strong, getter=hasPages, readwrite) NSMutableDictionary <__kindof NSNumber *, __kindof MADReportPageRepresentation *> *pages;

@end

@implementation MADReportTextRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (instancetype)init {
    return [self initWithPageCount:0];
}

- (instancetype)initWithPageCount:(NSUInteger)pageCount {
    if (self = [super init]) {
        NSMutableDictionary *pages = pageCount > 0 ? [[NSMutableDictionary alloc] initWithCapacity:pageCount] :
                                                     [NSMutableDictionary new];
        self.pages = pages;
    }
    return self;
}

- (MADReportPageRepresentation *)pageIndex:(NSUInteger)pageIndex {
    NSNumber *p = @(pageIndex);
    return self.pages[p];
}

- (void)setPage:(MADReportPageRepresentation *)page forPageIndex:(NSUInteger)pageIndex {
    NSNumber *number = @(pageIndex);
    [self.pages setObject:page forKey:number];
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
