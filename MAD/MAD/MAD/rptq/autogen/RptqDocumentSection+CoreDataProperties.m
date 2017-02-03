//
//  RptqDocumentSection+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentSection+CoreDataProperties.h"

@implementation RptqDocumentSection (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSection *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentSection"];
}

@dynamic identifier;
@dynamic type;
@dynamic height;
@dynamic layoutHeight;
@dynamic numberOfRows;
@dynamic visibility;
@dynamic wrappingStyle;
@dynamic hasRows;
@dynamic inGroup;
@dynamic inReport;
@dynamic inReportPageFooter;
@dynamic inReportPageHeader;
@dynamic inReportReportFooter;
@dynamic inReportReportHeader;

@end
