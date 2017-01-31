//
//  RptqDocumentSection+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentSection_CoreDataProperties_h
#define MAD_RptqDocumentSection_CoreDataProperties_h

#import "RptqDocumentSection.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentSection (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSection *> *)fetchRequest;

@property (nonatomic) float height;
@property (nonatomic) int64_t identifier;
@property (nonatomic) float layoutHeight;
@property (nonatomic) float marginBottom;
@property (nonatomic) float marginLeft;
@property (nonatomic) float marginRight;
@property (nonatomic) float marginTop;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int64_t numberOfRows;
@property (nonatomic) float paddingBottom;
@property (nonatomic) float paddingLeft;
@property (nonatomic) float paddingRight;
@property (nonatomic) float paddingTop;
@property (nonatomic) int64_t type;
@property (nonatomic) BOOL visibility;
@property (nonatomic) int16_t wrappingStyle;
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
