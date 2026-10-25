//
//  RptqDocument+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqDocumentSection.h"
@implementation RptqDocument

@end

@implementation RptqDocument (CoreDataProperties)


@dynamic identifier;
@dynamic papersize;
@dynamic hasDatabaseSchemas;
@dynamic hasDetailSection;
@dynamic hasPageFooterSection;
@dynamic hasPageHeaderSection;
@dynamic hasReportFooterSection;
@dynamic hasReportHeaderSection;

@end
