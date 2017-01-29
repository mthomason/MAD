//
//  RptqDocument+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocument+CoreDataProperties.h"

@implementation RptqDocument (CoreDataProperties)

+ (NSFetchRequest<RptqDocument *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocument"];
}

@dynamic author_name;
@dynamic comment;
@dynamic copyright;
@dynamic identifier;
@dynamic name;
@dynamic organization;
@dynamic override;
@dynamic overrideText;
@dynamic papersize;
@dynamic thumbnailpreview;
@dynamic hasDatabaseSchemas;
@dynamic hasDetailSection;
@dynamic hasPageFooterSection;
@dynamic hasPageHeaderSection;
@dynamic hasReportFooterSection;
@dynamic hasReportHeaderSection;

@end
