//
//  RptqDocumentSection+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentSection_CoreDataProperties_h
#define MAD_RptqDocumentSection_CoreDataProperties_h

#import "RptqDocumentSection+CoreDataClass.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentSection (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSection *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *height;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, copy) NSNumber *layoutHeight;
@property (nullable, nonatomic, copy) NSNumber *marginBottom;
@property (nullable, nonatomic, copy) NSNumber *marginLeft;
@property (nullable, nonatomic, copy) NSNumber *marginRight;
@property (nullable, nonatomic, copy) NSNumber *marginTop;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *numberOfRows;
@property (nullable, nonatomic, copy) NSNumber *paddingBottom;
@property (nullable, nonatomic, copy) NSNumber *paddingLeft;
@property (nullable, nonatomic, copy) NSNumber *paddingRight;
@property (nullable, nonatomic, copy) NSNumber *paddingTop;
@property (nullable, nonatomic, copy) NSNumber *type;
@property (nullable, nonatomic, copy) NSNumber *visibility;
@property (nullable, nonatomic, copy) NSNumber *wrappingStyle;
@property (nullable, nonatomic, retain) NSOrderedSet<RptqDocumentSectionRows *> *hasRows;
@property (nullable, nonatomic, retain) RptqQueryGroup *inGroup;
@property (nullable, nonatomic, retain) RptqDocument *inReport;
@property (nullable, nonatomic, retain) RptqDocument *inReportPageFooter;
@property (nullable, nonatomic, retain) RptqDocument *inReportPageHeader;
@property (nullable, nonatomic, retain) RptqDocument *inReportReportFooter;
@property (nullable, nonatomic, retain) RptqDocument *inReportReportHeader;

@end

@interface RptqDocumentSection (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDocumentSectionRows *)value inHasRowsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasRowsAtIndex:(NSUInteger)idx;
- (void)insertHasRows:(NSArray<RptqDocumentSectionRows *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasRowsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasRowsAtIndex:(NSUInteger)idx withObject:(RptqDocumentSectionRows *)value;
- (void)replaceHasRowsAtIndexes:(NSIndexSet *)indexes withHasRows:(NSArray<RptqDocumentSectionRows *> *)values;
- (void)addHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)removeHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)addHasRows:(NSOrderedSet<RptqDocumentSectionRows *> *)values;
- (void)removeHasRows:(NSOrderedSet<RptqDocumentSectionRows *> *)values;

@end

NS_ASSUME_NONNULL_END

#endif
