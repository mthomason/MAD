//
//  MADLabelStatus.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/28/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADLabelStatus_h
#define MAD_Designer_MADLabelStatus_h

#import <UIKit/UILabel.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

@interface MADLabelStatus : UILabel

    - (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs;
    - (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs;

    - (void)updatePageStatus:(MADReportPosition)reportPosition;
    - (void)updateStatusWithTime:(NSString *)timeMessage;
    - (void)updateStatusWithRecordsRead:(NSString *)message;
    - (void)updateStatusWithPageNumber:(NSString *)message;
    - (void)displayNoCache;

@end

#endif
