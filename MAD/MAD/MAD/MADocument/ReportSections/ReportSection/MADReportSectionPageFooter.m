//
//  MADReportSectionPageFooter.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionPageFooter.h"
#import <Foundation/NSBundle.h>

static NSString * const Name = @"Page Footer";

@implementation MADReportSectionPageFooter

- (NSString *)localizedDisplayName {
    return NSLocalizedString(Name, Name);
}

@end
