//
//  RptqDocument+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocument_CoreDataProperties_h
#define MAD_RptqDocument_CoreDataProperties_h

#import "RptqDocument.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocument (CoreDataProperties)

+ (NSFetchRequest<RptqDocument *> *)fetchRequest;

@property (nonatomic) int64_t identifier;
@property (nonatomic) int16_t papersize;
@property (nonatomic) BOOL override;

@property (nullable, nonatomic, copy) NSString *author_name;
@property (nullable, nonatomic, copy) NSString *comment;
@property (nullable, nonatomic, copy) NSString *copyright;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *organization;
@property (nullable, nonatomic, copy) NSString *overrideText;

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

#endif
