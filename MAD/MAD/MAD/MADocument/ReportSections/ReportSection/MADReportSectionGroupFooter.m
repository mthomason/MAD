//
//  MADReportSectionGroupFooter.m
//  MAD
//
//  Created by Michael Thomason on 6/28/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionGroupFooter.h"
#import <Foundation/NSBundle.h>
#import "RptqDocumentSection+CoreDataClass.h"
#import "RptqQueryGroup+Extras.h"

static NSString * const Format = @"Group Footer - (%@)";

@implementation MADReportSectionGroupFooter

- (NSString *)localizedDisplayName {
    id format = NSLocalizedString(Format, Format);
    id fieldName =  [self.documentSection.inGroup fieldNameQuery];
    id name = [[NSString alloc] initWithFormat:format, fieldName];
    return name;
}

@end
