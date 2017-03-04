//
//  MADReportSectionDetail.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionDetail.h"
#import <Foundation/NSBundle.h>

static NSString * const Name = @"Report Detail";

@implementation MADReportSectionDetail

- (NSString *)localizedDisplayName {
    id name = NSLocalizedString(Name, Name);
    return name;
}

@end
