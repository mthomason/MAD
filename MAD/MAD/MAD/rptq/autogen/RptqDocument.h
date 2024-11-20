//
//  RptqDocument.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocument_h
#define MAD_RptqDocument_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqDatabase, RptqDocumentSection;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocument : NSManagedObject

@end

@interface RptqDocument (CoreDataProperties)

+ (NSFetchRequest<RptqDocument *> *)fetchRequest;

@property (nonatomic) int64_t identifier;
@property (nonatomic) int16_t papersize;

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
