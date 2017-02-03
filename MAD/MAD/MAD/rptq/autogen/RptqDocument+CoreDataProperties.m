//
//  RptqDocument+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument+CoreDataProperties.h"

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
