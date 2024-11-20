//
//  RptqDocument+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqDocumentSection.h"
@implementation RptqDocument

@end

@implementation RptqDocument (CoreDataProperties)

+ (NSFetchRequest<RptqDocument *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocument"];
}

@dynamic identifier;
@dynamic papersize;
@dynamic hasDatabaseSchemas;
@dynamic hasDetailSection;
@dynamic hasPageFooterSection;
@dynamic hasPageHeaderSection;
@dynamic hasReportFooterSection;
@dynamic hasReportHeaderSection;

@end
