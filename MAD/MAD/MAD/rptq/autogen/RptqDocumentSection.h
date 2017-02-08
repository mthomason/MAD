//
//  RptqDocumentSection.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentSection_NSManagedObject_h
#define MAD_RptqDocumentSection_NSManagedObject_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqDocument, RptqDocumentSectionRows, RptqQueryGroup;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentSection : NSManagedObject

@end

@interface RptqDocumentSection (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSection *> *)fetchRequest;

@property (nonatomic) int64_t identifier;
@property (nonatomic) int32_t numberOfRows;
@property (nonatomic) int16_t type;
@property (nonatomic) int16_t wrappingStyle;
@property (nonatomic) BOOL visibility;
@property (nonatomic) double height;
@property (nonatomic) double layoutHeight;
@property (nullable, nonatomic, retain) NSOrderedSet<RptqDocumentSectionRows *> *hasRows;
@property (nullable, nonatomic, retain) RptqQueryGroup *inGroup;
@property (nullable, nonatomic, retain) RptqDocument *inReport;
@property (nullable, nonatomic, retain) RptqDocument *inReportPageFooter;
@property (nullable, nonatomic, retain) RptqDocument *inReportPageHeader;
@property (nullable, nonatomic, retain) RptqDocument *inReportReportFooter;
@property (nullable, nonatomic, retain) RptqDocument *inReportReportHeader;

@end

@interface RptqDocumentSection (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDocumentSectionRows *)value
    inHasRowsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasRowsAtIndex:(NSUInteger)idx;
- (void)insertHasRows:(NSArray<RptqDocumentSectionRows *> *)value
            atIndexes:(NSIndexSet *)indexes;
- (void)removeHasRowsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasRowsAtIndex:(NSUInteger)idx
                           withObject:(RptqDocumentSectionRows *)value;
- (void)replaceHasRowsAtIndexes:(NSIndexSet *)indexes
                    withHasRows:(NSArray<RptqDocumentSectionRows *> *)values;
- (void)addHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)removeHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)addHasRows:(NSOrderedSet<RptqDocumentSectionRows *> *)values;
- (void)removeHasRows:(NSOrderedSet<RptqDocumentSectionRows *> *)values;

@end

NS_ASSUME_NONNULL_END

#endif
