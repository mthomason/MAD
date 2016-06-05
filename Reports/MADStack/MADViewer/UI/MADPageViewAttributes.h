//
//  MADPageViewAttributes.h
//  MAD Designer
//
//  Created by Michael Thomason on 2/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADPageViewAttributes_h
#define Reports_MADPageViewAttributes_h

#import <UIKit/UIGeometry.h>

@interface MADPageViewAttributes : NSObject
    <NSCoding, NSCopying>

    - (instancetype)initWithCurrentPageNumber:(NSUInteger)currentPageNumber
                           totalNumberOfPages:(NSUInteger)numberOfPages
                            contentSizeInital:(CGSize)contentSizeInital;

    @property (nonatomic, assign, readwrite) NSUInteger pageNumber;
    @property (nonatomic, assign, readwrite) NSUInteger numberOfPages;
    @property (nonatomic, assign, readwrite) CGPoint contentOffsetInital;
    @property (nonatomic, assign, readwrite) CGSize contentSizeInital;
    @property (nonatomic, assign, readwrite) CGFloat zoomScaleInital;
    @property (nonatomic, assign, readwrite) CGFloat contentScaleFactor;
    @property (nonatomic, copy) NSDate *reportLastCacheDate;

@end

#endif
