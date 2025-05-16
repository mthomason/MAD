//
//  MADReportSectionPageHeader.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionPageHeader.h"
#import <Foundation/NSBundle.h>

static NSString * const Name = @"Page Header";

@implementation MADReportSectionPageHeader

- (NSString *)localizedDisplayName {
	return NSLocalizedString(Name, Name);
}

@end
