//
//  MADReportSectionReportFooter.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionReportFooter.h"
#import <Foundation/NSBundle.h>

static NSString * const Name = @"Report Footer";

@implementation MADReportSectionReportFooter

- (NSString *)localizedDisplayName {
    id name = NSLocalizedString(Name, Name);
    return name;
}

@end
