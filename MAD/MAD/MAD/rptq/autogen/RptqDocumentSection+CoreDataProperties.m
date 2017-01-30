//
//  RptqDocumentSection+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentSection+CoreDataProperties.h"

@implementation RptqDocumentSection (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSection *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentSection"];
}

@dynamic height;
@dynamic identifier;
@dynamic layoutHeight;
@dynamic marginBottom;
@dynamic marginLeft;
@dynamic marginRight;
@dynamic marginTop;
@dynamic name;
@dynamic numberOfRows;
@dynamic paddingBottom;
@dynamic paddingLeft;
@dynamic paddingRight;
@dynamic paddingTop;
@dynamic type;
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
