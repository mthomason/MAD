//
//  MADReportRows.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADReportRows_h
#define MAD_MADReportRows_h

#import <Foundation/NSObject.h>

@class MADReportRow;

@interface MADReportRows : NSObject

    @property (nonatomic, readonly, strong, getter=hasRows) NSArray <MADReportRow *> *rows;

@end

#endif
