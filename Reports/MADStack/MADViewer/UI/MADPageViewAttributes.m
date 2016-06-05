//
//  MADPageViewAttributes.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADPageViewAttributes.h"

static NSString * const keyPageNumber           = @"p";
static NSString * const keyNumberOfPages        = @"n";
static NSString * const keyOffsetInital         = @"o";
static NSString * const keySizeInital           = @"s";
static NSString * const keyZoomScaleInital      = @"z";
static NSString * const keyReportLastCacheDate  = @"r";
static NSString * const keyContentScaleFactor   = @"f";

@implementation MADPageViewAttributes

- (instancetype)initWithCurrentPageNumber:(NSUInteger)currentPageNumber
                       totalNumberOfPages:(NSUInteger)numberOfPages
                        contentSizeInital:(CGSize)contentSizeInital {
    if (self = [super init]) {
        _pageNumber = currentPageNumber;
        _numberOfPages = numberOfPages;
        _zoomScaleInital = 1.0000f;
        _contentSizeInital = contentSizeInital;
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

    NSNumber *zoomScaleInital = [[NSNumber alloc] initWithFloat:_zoomScaleInital];
    [coder encodeObject:zoomScaleInital forKey:keyZoomScaleInital];

    NSNumber *contentScaleFactor = [[NSNumber alloc] initWithFloat:_contentScaleFactor];
    [coder encodeObject:contentScaleFactor forKey:keyContentScaleFactor];

    [coder encodeCGPoint:_contentOffsetInital forKey:keyOffsetInital];
    [coder encodeCGSize:_contentSizeInital forKey:keySizeInital];
    [coder encodeDouble:_reportLastCacheDate.timeIntervalSinceReferenceDate forKey:keyReportLastCacheDate];
}

- (instancetype)copyWithZone:(NSZone *)zone {

    MADPageViewAttributes *result = [[[self class] allocWithZone:zone] init];
    result.contentScaleFactor = self.contentScaleFactor;
    result.pageNumber = self.pageNumber;
    result.numberOfPages = self.numberOfPages;
    result.contentOffsetInital = self.contentOffsetInital;
    result.contentSizeInital = self.contentSizeInital;
    result.zoomScaleInital = self.zoomScaleInital;
    
    NSDate *reportLastCacheDate = self.reportLastCacheDate.copy;
    result.reportLastCacheDate = reportLastCacheDate;

    return result;
}

@end
