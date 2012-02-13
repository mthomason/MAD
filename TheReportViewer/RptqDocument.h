//
//  RptqDocument.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqDocumentSection, RptqQuery;

@interface RptqDocument : NSManagedObject

@property (nonatomic, retain) NSString * author_name;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSString * copyright;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * organization;
@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) NSNumber * papersize;
@property (nonatomic, retain) NSData * thumbnailpreview;
@property (nonatomic, retain) RptqDatabase *hasDatabaseSchema;
@property (nonatomic, retain) RptqDocumentSection *hasDetailSection;
@property (nonatomic, retain) RptqDocumentSection *hasPageFooterSection;
@property (nonatomic, retain) RptqDocumentSection *hasPageHeaderSection;
@property (nonatomic, retain) RptqQuery *hasQuery;
@property (nonatomic, retain) RptqDocumentSection *hasReportFooterSection;
@property (nonatomic, retain) RptqDocumentSection *hasReportHeaderSection;

@end
