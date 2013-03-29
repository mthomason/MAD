//
//  RptqDocument.h
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqDocumentSection;

@interface RptqDocument : NSManagedObject

@property (nonatomic, retain) NSString * author_name;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSString * copyright;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * organization;
@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) NSNumber * papersize;
@property (nonatomic, retain) NSData * thumbnailpreview;
@property (nonatomic, retain) NSSet *hasDatabaseSchemas;
@property (nonatomic, retain) RptqDocumentSection *hasDetailSection;
@property (nonatomic, retain) RptqDocumentSection *hasPageFooterSection;
@property (nonatomic, retain) RptqDocumentSection *hasPageHeaderSection;
@property (nonatomic, retain) RptqDocumentSection *hasReportFooterSection;
@property (nonatomic, retain) RptqDocumentSection *hasReportHeaderSection;
@end

@interface RptqDocument (CoreDataGeneratedAccessors)

- (void)addHasDatabaseSchemasObject:(RptqDatabase *)value;
- (void)removeHasDatabaseSchemasObject:(RptqDatabase *)value;
- (void)addHasDatabaseSchemas:(NSSet *)values;
- (void)removeHasDatabaseSchemas:(NSSet *)values;

@end
