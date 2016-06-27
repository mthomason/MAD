//
//  MADReportSection.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportSection_h
#define MAD_MADReportSection_h

#import <Foundation/NSObject.h>

@class MADReportRows;

@interface MADReportSection : NSObject

    @property (nonatomic, readonly, strong, getter=hasReportRows)    MADReportRows *reportRows;

@end

#endif
