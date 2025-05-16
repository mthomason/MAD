//
//  MADReportSectionReportHeader.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionReportHeader.h"
#import <Foundation/NSBundle.h>

static NSString * const Name = @"Report Header";

@implementation MADReportSectionReportHeader

- (NSString *)localizedDisplayName {
    return NSLocalizedString(Name, Name);
}

@end
