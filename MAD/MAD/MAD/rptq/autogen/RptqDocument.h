//
//  RptqDocument.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqDocumentSection;

@interface RptqDocument : NSManagedObject

@property (nonatomic, strong) NSString * author_name;
@property (nonatomic, strong) NSString * comment;
@property (nonatomic, strong) NSString * copyright;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * organization;
@property (nonatomic, strong) NSNumber * override;
@property (nonatomic, strong) NSString * overrideText;
@property (nonatomic, strong) NSNumber * papersize;
@property (nonatomic, strong) NSData * thumbnailpreview;
@property (nonatomic, strong) NSSet *hasDatabaseSchemas;
@property (nonatomic, strong) RptqDocumentSection *hasDetailSection;
@property (nonatomic, strong) RptqDocumentSection *hasPageFooterSection;
@property (nonatomic, strong) RptqDocumentSection *hasPageHeaderSection;
@property (nonatomic, strong) RptqDocumentSection *hasReportFooterSection;
@property (nonatomic, strong) RptqDocumentSection *hasReportHeaderSection;
@end

@interface RptqDocument (CoreDataGeneratedAccessors)

- (void)addHasDatabaseSchemasObject:(RptqDatabase *)value;
- (void)removeHasDatabaseSchemasObject:(RptqDatabase *)value;
- (void)addHasDatabaseSchemas:(NSSet *)values;
- (void)removeHasDatabaseSchemas:(NSSet *)values;

@end
