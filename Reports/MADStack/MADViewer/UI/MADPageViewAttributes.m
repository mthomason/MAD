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

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _pageNumber = [decoder decodeInt64ForKey:keyPageNumber];
        _numberOfPages = [decoder decodeInt64ForKey:keyNumberOfPages];
        _contentOffsetInital = [decoder decodeCGPointForKey:keyOffsetInital];
        _contentSizeInital = [decoder decodeCGSizeForKey:keySizeInital];
        _zoomScaleInital = [decoder decodeDoubleForKey:keyZoomScaleInital];
        NSTimeInterval reportLastCacheDate = [decoder decodeDoubleForKey:keyReportLastCacheDate];
        _reportLastCacheDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:reportLastCacheDate];
        _contentScaleFactor = [decoder decodeDoubleForKey:keyContentScaleFactor];

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:_pageNumber forKey:keyPageNumber];
    [coder encodeInt64:_numberOfPages forKey:keyNumberOfPages];
    [coder encodeCGPoint:_contentOffsetInital forKey:keyOffsetInital];
    [coder encodeCGSize:_contentSizeInital forKey:keySizeInital];
    [coder encodeDouble:_zoomScaleInital forKey:keyZoomScaleInital];
    [coder encodeDouble:_reportLastCacheDate.timeIntervalSinceReferenceDate forKey:keyReportLastCacheDate];
    [coder encodeDouble:_contentScaleFactor forKey:keyContentScaleFactor];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MADPageViewAttributes *result = [[[self class] allocWithZone:zone] init];
    result.contentScaleFactor = self.contentScaleFactor;
    result.pageNumber = self.pageNumber;
    result.numberOfPages = self.numberOfPages;
    result.contentOffsetInital = self.contentOffsetInital;
    result.contentSizeInital = self.contentSizeInital;
    result.zoomScaleInital = self.zoomScaleInital;
    result.reportLastCacheDate = self.reportLastCacheDate.copy;
    return result;
}

@end
