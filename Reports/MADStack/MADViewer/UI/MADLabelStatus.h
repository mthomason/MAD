//
//  MADLabelStatus.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/28/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UILabel.h>

@interface MADLabelStatus : UILabel

    - (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs;
    - (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs;

    - (void)updatePageStatus:(NSUInteger)numberOfPages currentPageIndex:(NSUInteger)currentPageIndex;
    - (void)updateStatusWithTime:(NSString *)timeMessage;
    - (void)updateStatusWithRecordsRead:(NSString *)message;
    - (void)updateStatusWithPageNumber:(NSString *)message;

@end
