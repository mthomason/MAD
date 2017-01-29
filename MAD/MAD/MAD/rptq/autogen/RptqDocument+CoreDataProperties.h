//
//  RptqDocument+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocument+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocument (CoreDataProperties)

+ (NSFetchRequest<RptqDocument *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *author_name;
@property (nullable, nonatomic, copy) NSString *comment;
@property (nullable, nonatomic, copy) NSString *copyright;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *organization;
@property (nullable, nonatomic, copy) NSNumber *override;
@property (nullable, nonatomic, copy) NSString *overrideText;
@property (nullable, nonatomic, copy) NSNumber *papersize;
@property (nullable, nonatomic, retain) NSData *thumbnailpreview;
@property (nullable, nonatomic, retain) NSSet<RptqDatabase *> *hasDatabaseSchemas;
@property (nullable, nonatomic, retain) RptqDocumentSection *hasDetailSection;
@property (nullable, nonatomic, retain) RptqDocumentSection *hasPageFooterSection;
@property (nullable, nonatomic, retain) RptqDocumentSection *hasPageHeaderSection;
@property (nullable, nonatomic, retain) RptqDocumentSection *hasReportFooterSection;
@property (nullable, nonatomic, retain) RptqDocumentSection *hasReportHeaderSection;

@end

@interface RptqDocument (CoreDataGeneratedAccessors)

- (void)addHasDatabaseSchemasObject:(RptqDatabase *)value;
- (void)removeHasDatabaseSchemasObject:(RptqDatabase *)value;
- (void)addHasDatabaseSchemas:(NSSet<RptqDatabase *> *)values;
- (void)removeHasDatabaseSchemas:(NSSet<RptqDatabase *> *)values;

@end

NS_ASSUME_NONNULL_END
