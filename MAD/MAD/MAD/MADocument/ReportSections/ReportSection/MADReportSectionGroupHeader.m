//
//  MADReportSectionGroupHeader.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionGroupHeader.h"
#import "RptqDocumentSection.h"
#import "RptqQueryGroup+Extras.h"
#import <Foundation/NSBundle.h>

@implementation MADReportSectionGroupHeader

- (NSString *)localizedDisplayName {
	id fieldName =  [self.documentSection.inGroup fieldNameQuery];
	return [NSString stringWithFormat:NSLocalizedString(@"Group Header (%@)", @"Group Header (%@)"), fieldName];
}

@end
