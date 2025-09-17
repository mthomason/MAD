//
//  MADReportSectionGroupFooter.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionGroupFooter.h"
#import "RptqDocumentSection.h"
#import "RptqQueryGroup+Extras.h"
#import <Foundation/NSBundle.h>

@implementation MADReportSectionGroupFooter

- (NSString *)localizedDisplayName {
	id fieldName =  [self.documentSection.inGroup fieldNameQuery];
	return [[NSString alloc] initWithFormat:NSLocalizedString(@"Group Footer - (%@)", @"Group Footer - (%@)"), fieldName];
}

@end
