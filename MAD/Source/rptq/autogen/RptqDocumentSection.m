//
//  RptqDocumentSection+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDocumentSection.h"
#import "RptqDocument.h"
#import "RptqDocumentSectionRows.h"
#import "RptqQueryGroup.h"

@implementation RptqDocumentSection

@end

@implementation RptqDocumentSection (CoreDataProperties)


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
