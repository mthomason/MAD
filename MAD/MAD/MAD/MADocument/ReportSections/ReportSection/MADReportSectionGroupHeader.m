//
//  MADReportSectionGroupHeader.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionGroupHeader.h"
#import <Foundation/NSBundle.h>
#import "RptqDocumentSection.h"
#import "RptqQueryGroup+Extras.h"

static NSString * const Format = @"Group Header (%@)";

@implementation MADReportSectionGroupHeader

- (NSString *)localizedDisplayName {
    id fieldName =  [self.documentSection.inGroup fieldNameQuery];
	return [NSString stringWithFormat:NSLocalizedString(Format, Format), fieldName];
}

@end
