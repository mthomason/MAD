//
//  MADPageViewAttributes.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/24/16.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
//

#import "MADPageViewAttributes.h"
#import <UIKit/UIGeometry.h>

static NSString * const keyPageNumber           = @"p";
static NSString * const keyNumberOfPages        = @"n";
static NSString * const keyOffsetInital         = @"o";
static NSString * const keySizeInital           = @"s";
static NSString * const keyZoomScaleInital      = @"z";
static NSString * const keyReportLastCacheDate  = @"r";
static NSString * const keyContentScaleFactor   = @"f";

@implementation MADPageViewAttributes

- (instancetype)initWithCurrentPage:(NSUInteger)currentPageNumber
                              total:(NSUInteger)numberOfPages
                               size:(CGSize)size {
    return [self initWithPosition: MADReportPositionMake(currentPageNumber - 1, numberOfPages)
                             size: size];
}

- (instancetype)initWithPosition:(MADReportPosition)position
                            size:(CGSize)size {
    if (self = [super init]) {
        _pageNumber = position.currentPage + 1;
        _numberOfPages = position.totalPages;
        _zoomScaleInital = 1.0;
        _contentSizeInital = size;
        _contentOffsetInital = CGPointZero;
        _contentScaleFactor = 0.0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {

    if (self = [super init]) {
        
        NSNumber *pageNumber = [decoder decodeObjectForKey:keyPageNumber];
        _pageNumber = pageNumber.unsignedIntegerValue;
        
        NSNumber *numberOfPages = [decoder decodeObjectForKey:keyNumberOfPages];
        _numberOfPages = numberOfPages.unsignedIntegerValue;

        NSNumber *zoomScaleInital = [decoder decodeObjectForKey:keyZoomScaleInital];
        _zoomScaleInital = zoomScaleInital.floatValue;

        NSNumber *contentScaleFactor = [decoder decodeObjectForKey:keyContentScaleFactor];
        _contentScaleFactor = contentScaleFactor.floatValue;
        
        _contentOffsetInital = [decoder decodeCGPointForKey:keyOffsetInital];
        _contentSizeInital = [decoder decodeCGSizeForKey:keySizeInital];

        NSTimeInterval reportLastCacheDate = [decoder decodeDoubleForKey:keyReportLastCacheDate];
        _reportLastCacheDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:reportLastCacheDate];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {

    NSNumber *pageNumber = [[NSNumber alloc] initWithUnsignedInteger:_pageNumber];
    [coder encodeObject:pageNumber forKey:keyPageNumber];

    NSNumber *numberOfPages = [[NSNumber alloc] initWithUnsignedInteger:_numberOfPages];
    [coder encodeObject:numberOfPages forKey:keyNumberOfPages];

    NSNumber *zoomScaleInital = [[NSNumber alloc] initWithDouble:_zoomScaleInital];
    [coder encodeObject:zoomScaleInital forKey:keyZoomScaleInital];

    NSNumber *contentScaleFactor = [[NSNumber alloc] initWithDouble:_contentScaleFactor];
    [coder encodeObject:contentScaleFactor forKey:keyContentScaleFactor];

    [coder encodeCGPoint:_contentOffsetInital forKey:keyOffsetInital];
    [coder encodeCGSize:_contentSizeInital forKey:keySizeInital];
    [coder encodeDouble:_reportLastCacheDate.timeIntervalSinceReferenceDate forKey:keyReportLastCacheDate];
}

- (instancetype)copyWithZone:(NSZone *)zone {

    MADPageViewAttributes *result = [[[self class] allocWithZone:zone] init];
    result.reportLastCacheDate = _reportLastCacheDate.copy;
    result.contentScaleFactor = _contentScaleFactor;
    result.pageNumber = _pageNumber;
    result.numberOfPages = _numberOfPages;
    result.contentOffsetInital = _contentOffsetInital;
    result.contentSizeInital = _contentSizeInital;
    result.zoomScaleInital = _zoomScaleInital;

    return result;
}

@end
