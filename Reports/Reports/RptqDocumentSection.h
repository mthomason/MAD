//
//  RptqDocumentSection.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqDocumentSectionRows, RptqQueryGroup;

@interface RptqDocumentSection : NSManagedObject

@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSNumber * layoutHeight;
@property (nonatomic, strong) NSNumber * marginBottom;
@property (nonatomic, strong) NSNumber * marginLeft;
@property (nonatomic, strong) NSNumber * marginRight;
@property (nonatomic, strong) NSNumber * marginTop;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * numberOfRows;
@property (nonatomic, strong) NSNumber * paddingBottom;
@property (nonatomic, strong) NSNumber * paddingLeft;
@property (nonatomic, strong) NSNumber * paddingRight;
@property (nonatomic, strong) NSNumber * paddingTop;
@property (nonatomic, strong) NSNumber * type;
@property (nonatomic, strong) NSNumber * visibility;
@property (nonatomic, strong) NSNumber * wrappingStyle;
@property (nonatomic, strong) NSOrderedSet *hasRows;
@property (nonatomic, strong) RptqQueryGroup *inGroup;
@property (nonatomic, strong) RptqDocument *inReport;
@property (nonatomic, strong) RptqDocument *inReportPageFooter;
@property (nonatomic, strong) RptqDocument *inReportPageHeader;
@property (nonatomic, strong) RptqDocument *inReportReportFooter;
@property (nonatomic, strong) RptqDocument *inReportReportHeader;
@end

@interface RptqDocumentSection (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDocumentSectionRows *)value inHasRowsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasRowsAtIndex:(NSUInteger)idx;
- (void)insertHasRows:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasRowsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasRowsAtIndex:(NSUInteger)idx withObject:(RptqDocumentSectionRows *)value;
- (void)replaceHasRowsAtIndexes:(NSIndexSet *)indexes withHasRows:(NSArray *)values;
- (void)addHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)removeHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)addHasRows:(NSOrderedSet *)values;
- (void)removeHasRows:(NSOrderedSet *)values;
@end
