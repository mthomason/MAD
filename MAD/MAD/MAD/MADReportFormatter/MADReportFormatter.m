//
//  MADReportFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportFormatter.h"

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectModel.h>
#import <CoreData/NSPropertyDescription.h>
#import <CoreData/NSEntityDescription.h>

#import <UIKit/UIPrintInteractionController.h>

#import <MADFoundation/MADDataType.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADReportFormatterDataSourceProtocol.h"

#import "MADSectionRepresentation.h"

#import "MADReportFormatterState.h"
#import "MADocument.h"

#import "MADModel.h"
#import "MADModelDocument.h"
#import "MADModelDatabase.h"

#import "MTQueryFull.h"

#import "RptqDocument+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryGroup+Extras.h"

#import "MTDatabase.h"
#import "MADDatabaseField.h"

#import "MADReportFormatterCache.h"

#import "MADArrayCaching.h"

#import "MADNotificationDidFormatPage.h"
#import "MADPageOptions.h"

#import "NSData+Comparson.h"

#import "MADSectionRepresentation.h"

static inline UIEdgeInsets MADEdgeInsetsQuarterInch();
static inline UIEdgeInsets MADEdgeInsetsQuarterInch() {
    return UIEdgeInsetsMake(fCGPointsForInches(1.0/4.0),
                            fCGPointsForInches(1.0/4.0),
                            fCGPointsForInches(1.0/4.0),
                            fCGPointsForInches(1.0/4.0));
}

static inline UIEdgeInsets MADEdgeInsetsEmpty();
static inline UIEdgeInsets MADEdgeInsetsEmpty() {
    return UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.height,
                            CGSizeZero.height, CGSizeZero.height);
}

static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect, CGSize);
static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect printableRect, CGSize layoutSize) {
    return UIEdgeInsetsMake(printableRect.origin.y, printableRect.origin.x,
                            layoutSize.height - printableRect.size.height - printableRect.origin.y,
                            layoutSize.width - printableRect.size.width - printableRect.origin.x);
}

static inline CGFloat PrintableHeightForPage(MADPageOptions *);
static inline CGFloat PrintableHeightForPage(MADPageOptions *page) {
    return page.layoutSize.height - page.margins.top - page.margins.bottom;
}

static inline CGFloat HeightWithNextItem(CGFloat, CGFloat, CGFloat);
static inline CGFloat HeightWithNextItem(CGFloat heightUsedCurrentPage, CGFloat
                                         nextItemHeight, CGFloat pageFooterHeight) {
    return heightUsedCurrentPage + nextItemHeight + pageFooterHeight;
}

@interface MADSectionLayout : NSObject

    @property (nonatomic, copy) NSManagedObjectID *objectID;
    @property (nonatomic, assign) int64_t identifier;
    @property (nonatomic, assign) MADDocumentSectionType type;
    @property (nonatomic, assign) CGFloat height;
    @property (nonatomic, assign) NSUInteger groupLevel;
    @property (nonatomic, assign) NSUInteger numberOfRows;
    @property (nonatomic, assign, getter=isVisible) BOOL visibility;
    @property (nonatomic, assign) RptqDocumentSectionWrappingStyle wrappingStyle;
    //@property (nonatomic, strong) NSArray *elements;

@end

@implementation MADSectionLayout {
  @public
    NSManagedObjectID *_objectID;
    int64_t _identifier;
    MADDocumentSectionType _type;
    CGFloat _height;
    NSUInteger _groupLevel;
    NSUInteger _numberOfRows;
    BOOL _visibility;
    RptqDocumentSectionWrappingStyle _wrappingStyle;
}

- (instancetype)initWithObject:(NSDictionary *)object
          managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super init]) {
        
        NSString *keyIdentifier = NSStringFromSelector(@selector(identifier)),
                 *keyPathNumberOfRows = [RptqDocumentSection keyPathNumberOfRows],
                 *keyPathType = [RptqDocumentSection keyPathType],
                 *keyPathWrappingStyle = [RptqDocumentSection keyPathWrappingStyle],
                 *keyPathVisibility = [RptqDocumentSection keyPathVisibility],
                 *keyPathHeight = [RptqDocumentSection keyPathHeight],
                 *keySelf = NSStringFromSelector(@selector(self));
        
        NSNumber *number = object[keyIdentifier];
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt64Type, &_identifier);
        
        number = object[keyPathHeight];
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberDoubleType, &_height);
        
        number = object[keyPathNumberOfRows];
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt32Type, &_numberOfRows);
        
        number = object[keyPathType];
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_type);
        
        number = object[keyPathVisibility];
        _visibility = number.boolValue;
        
        number = object[keyPathWrappingStyle];
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_wrappingStyle);
        
        NSManagedObjectID *objectID = object[keySelf];
        objectID = objectID.copy;
        
        NSFetchRequest *fetchRequestElements;
    
        fetchRequestElements = [RptqDocumentElement fetchRequestElementsInSection:objectID];
        NSError *error = nil;
        NSArray *results = [managedObjectContext executeFetchRequest: fetchRequestElements
                                                               error: &error];
        NSLog(@"%@", results);
        
    }
    return self;
}

@end

@interface MADSectionGroupLayout : MADSectionLayout

    @property (nonatomic, assign) MADSortOrder sort;
    @property (nonatomic, assign) int16_t weight;
    @property (nonatomic, assign) int16_t dataType;
    @property (nonatomic, copy) NSString * (^safeIdentifier)(NSString *);

@end

@implementation MADSectionGroupLayout {
    int64_t _dropIndex;
    NSString *_tableAlias;
    NSString *_fieldName;
}

- (instancetype)initWithObject:(NSDictionary *)object
          managedObjectContext:(NSManagedObjectContext *)managedObjectContext
              safeIdentifier:(NSString * (^)(NSString *))safeIdentifier {
    if (self = [super initWithObject: object managedObjectContext: managedObjectContext]) {
        
        if (_type == MADDocumentSectionTypeGroupHeader || _type == MADDocumentSectionTypeGroupFooter) {
            NSString *keyPathInGroupWeight = [RptqDocumentSection keyPathInGroupWeight],
                     *keyPathInGroupSort = [RptqDocumentSection keyPathInGroupSort],
                     *keyPathInGroupHasFieldDatabaseSchemaFieldDataType = [RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldDataType],
                     *keyPathInGroupHasFieldInQueryTableAlias = [RptqDocumentSection keyPathInGroupHasFieldInQueryTableAlias],
                     *keyPathInGroupHasFieldDatabaseSchemaFieldName = [RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldName],
                     *keyPathInGroupHasFieldInQueryTableDropIndex = [RptqDocumentSection keyPathInGroupHasFieldInQueryTableDropIndex];
        
            NSNumber *number = object[keyPathInGroupSort];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_sort);

            number = object[keyPathInGroupWeight];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_weight);
            
            number = object[keyPathInGroupHasFieldDatabaseSchemaFieldDataType];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_dataType);
            
            NSString *tableAlias = object[keyPathInGroupHasFieldInQueryTableAlias];
            _tableAlias = tableAlias.copy;

            NSString *fieldName = object[keyPathInGroupHasFieldDatabaseSchemaFieldName];
            _fieldName = fieldName.copy;

            number = object[keyPathInGroupHasFieldInQueryTableDropIndex];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt64Type, &_dropIndex);

            self.safeIdentifier = safeIdentifier;
        }
    
    }
    return self;
}

- (BOOL)sortAscending {
    return _sort == MADSortOrderAccending;
}

- (NSSortDescriptor *)sortDescriptor {
    NSString *queryTableAlias = [RptqQueryTable queryAliasForSchemaTableName:_tableAlias dropIndex:_dropIndex];
    NSString *safeTableAlias = self.safeIdentifier(queryTableAlias);
    NSString *safeFieldName = self.safeIdentifier(_fieldName);
    NSString *sortKey = [safeTableAlias stringByAppendingString:@"."];
    sortKey = [sortKey stringByAppendingString:safeFieldName];
    SEL sel = MADDataTypeSelectorForSorting(_dataType);
    id result = [[NSSortDescriptor alloc] initWithKey: sortKey
                                            ascending: [self sortAscending]
                                             selector: sel];
    return result;
}

@end

@interface MADSectionsLayout : NSObject

    @property (nonatomic, strong) MADSectionLayout *reportHeader;
    @property (nonatomic, strong) MADSectionLayout *pageHeader;
    @property (nonatomic, strong) NSArray <MADSectionGroupLayout *> *groupHeaders;
    @property (nonatomic, strong) MADSectionLayout *detail;
    @property (nonatomic, strong) NSArray <MADSectionGroupLayout *> *groupFooters;
    @property (nonatomic, strong) MADSectionLayout *pageFooter;
    @property (nonatomic, strong) MADSectionLayout *reportFooter;

@end

@interface MADSectionsLayout ()

@end

@implementation MADSectionsLayout

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                               databaseClass:(Class)databaseClass {
    if (self = [super init]) {
        NSFetchRequest *fetchRequestDocumentSections;
        fetchRequestDocumentSections = [RptqDocumentSection fetchRequestDocumentSections];
        
        NSError *error = nil;
        NSArray <NSDictionary *> *documentSections;
        documentSections = [managedObjectContext executeFetchRequest: fetchRequestDocumentSections
                                                               error: &error];
        
        NSString *keyIdentifier = NSStringFromSelector(@selector(identifier)),
                 *keyPathNumberOfRows = [RptqDocumentSection keyPathNumberOfRows],
                 *keyPathType = [RptqDocumentSection keyPathType],
                 *keyPathWrappingStyle = [RptqDocumentSection keyPathWrappingStyle],
                 *keyPathVisibility = [RptqDocumentSection keyPathVisibility],
                 *keyPathHeight = [RptqDocumentSection keyPathHeight],
                 *keyPathLayoutHeight = [RptqDocumentSection keyPathLayoutHeight],
                 *keyPathInGroupHasFieldInQueryTableAlias = [RptqDocumentSection keyPathInGroupHasFieldInQueryTableAlias],
                 *keyPathInGroupHasFieldDatabaseSchemaFieldName = [RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldName],
                 *keyPathInGroupWeight = [RptqDocumentSection keyPathInGroupWeight],
                 *keyPathInGroupSort = [RptqDocumentSection keyPathInGroupSort],
                 *keyPathInPageHeader = [RptqDocumentSection keyPathInPageHeader],
                 *keyPathInPageFooter = [RptqDocumentSection keyPathInPageFooter],
                 *keyPathInReport = [RptqDocumentSection keyPathInReport],
                 *keyPathInGroup = [RptqDocumentSection keyPathInGroup],
                 *keySelf = NSStringFromSelector(@selector(self));
        
        NSString *keyPath;
        NSUInteger expressionInQueryCount = 2;
        NSExpression *pexpressions[expressionInQueryCount];
        
        // Report Header
        keyPath = [RptqDocumentSection keyPathInReportHeader];
        pexpressions[0] = [NSExpression expressionForKeyPath:keyPath];
        pexpressions[1] = [NSExpression expressionForConstantValue:nil];
        
        NSPredicate *predicate;
        predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                       rightExpression: pexpressions[1]
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSNotEqualToPredicateOperatorType
                                                               options: 0];
        
        NSArray <NSDictionary *> *reportHeaderArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (reportHeaderArray.count > 0) {
            NSDictionary *reportHeaderDictionary = reportHeaderArray[0];
            _reportHeader = [[MADSectionLayout alloc] initWithObject: reportHeaderDictionary
                                                managedObjectContext: managedObjectContext];
        }
        
        // Report Footer
        keyPath = [RptqDocumentSection keyPathInReportFooter];
        pexpressions[0] = [NSExpression expressionForKeyPath:keyPath];
        
        predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                       rightExpression: pexpressions[1]
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSNotEqualToPredicateOperatorType
                                                               options: 0];

        NSArray <NSDictionary *> *reportFooterArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (reportFooterArray.count > 0) {
            NSDictionary *objects = reportFooterArray[0];
            _reportFooter = [[MADSectionLayout alloc] initWithObject: objects
                                                managedObjectContext: managedObjectContext];
        }
        
        // Page Header
        keyPath = [RptqDocumentSection keyPathInPageHeader];
        pexpressions[0] = [NSExpression expressionForKeyPath:keyPath];
        
        predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                       rightExpression: pexpressions[1]
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSNotEqualToPredicateOperatorType
                                                               options: 0];
        NSArray <NSDictionary *> *pageHeaderArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (pageHeaderArray.count > 0) {
            NSDictionary *objects = pageHeaderArray[0];
            _pageHeader = [[MADSectionLayout alloc] initWithObject: objects
                                              managedObjectContext: managedObjectContext];
        }

        // Page Footer
        keyPath = [RptqDocumentSection keyPathInPageFooter];
        pexpressions[0] = [NSExpression expressionForKeyPath:keyPath];
        
        predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                       rightExpression: pexpressions[1]
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSNotEqualToPredicateOperatorType
                                                               options: 0];
        NSArray <NSDictionary *> *pageFooterArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (pageFooterArray.count > 0) {
            NSDictionary *objects = pageFooterArray[0];
            _pageFooter = [[MADSectionLayout alloc] initWithObject: objects
                                              managedObjectContext: managedObjectContext];
        }

        // Detail
        keyPath = [RptqDocumentSection keyPathInReport];
        pexpressions[0] = [NSExpression expressionForKeyPath:keyPath];
        
        predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                       rightExpression: pexpressions[1]
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSNotEqualToPredicateOperatorType
                                                               options: 0];
        NSArray <NSDictionary *> *detailArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (detailArray.count > 0) {
            NSDictionary *objects = detailArray[0];
            _detail = [[MADSectionLayout alloc] initWithObject: objects
                                          managedObjectContext: managedObjectContext];
        }
        
        // Groups
        NSArray *groupHeaders = [[NSArray alloc] init];
        NSArray *groupFooters = [[NSArray alloc] init];
        
        keyPath = [RptqDocumentSection keyPathInGroup];
        pexpressions[0] = [NSExpression expressionForKeyPath:keyPath];
        
        predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                       rightExpression: pexpressions[1]
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSNotEqualToPredicateOperatorType
                                                               options: 0];
        NSArray <NSDictionary *> *groupArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (groupArray.count > 0) {
            MADSectionGroupLayout *groupLayout;
            for (NSDictionary *objects in groupArray) {
                groupLayout = [[MADSectionGroupLayout alloc] initWithObject: objects
                                                       managedObjectContext: managedObjectContext
                               safeIdentifier:^NSString *(NSString *identifier) {
                                   id dbClass = databaseClass;
                                   return [dbClass newSafeIdentifier:identifier];
                               }];
                switch (groupLayout.type) {
                    
                    case MADDocumentSectionTypeGroupHeader:
                        groupHeaders = [groupHeaders arrayByAddingObject: groupLayout];
                        break;
                    
                    case MADDocumentSectionTypeGroupFooter:
                        groupFooters = [groupFooters arrayByAddingObject: groupLayout];
                        break;
                        
                    default:
                        break;
                }
            }
        }
        
        NSString *keyWeight = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortWeightAsc = [NSSortDescriptor sortDescriptorWithKey:keyWeight ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortWeightAsc, nil];
        self.groupHeaders = [groupHeaders sortedArrayUsingDescriptors: sortDescriptors];
        self.groupFooters = [groupFooters sortedArrayUsingDescriptors: sortDescriptors];

    }
    return self;
}

@end

@interface MADReportFormatter ()

    @property (nonatomic, readwrite, weak)      MADocument *layout;
    @property (nonatomic, readwrite, strong)    MADSectionsLayout *sections;

    @property (nonatomic, strong)               RptqDocument *document;

    @property (nonatomic, readwrite, assign)    MADReportFormatterOptions options;

    @property (nonatomic, readwrite, strong)    MADPageOptions *page;

    //  These are the rowids by page.  These point to data in the cache.
    //      Once these arrays are populated, they are used by the print page render to
    //      draw the report.
    //
    @property (nonatomic, readwrite, strong)    MADArrayCaching <NSArray <NSNumber *> *> *reportIndexes;
    @property (nonatomic, readwrite, strong)    MADArrayCaching <NSArray <MADSectionRepresentation *> *> *reportLayout;

    @property (nonatomic, readwrite, strong)    MADReportFormatterState *machineState;
    @property (nonatomic, readwrite, strong)    MADReportFormatterCache *reportFormatterCache;

    @property (nonatomic, readwrite, strong)    NSMutableArray <__kindof MADSectionRepresentation *> *pageLayoutTemporary;
    @property (nonatomic, readwrite, strong)    NSMutableArray <NSNumber *> *pageIndexesTemporary;

    @property (nonatomic, readwrite, strong)    NSArray *lastComparsonValues;
    @property (nonatomic, readwrite, strong)    NSDictionary <NSNumber *, NSNumber *> *layoutHeightsBySectionKey;
    @property (nonatomic, readwrite, strong)    NSArray <RptqQueryGroup *> *sortedQueryGroups;

    @property (nonatomic, readwrite, strong)    NSDictionary <NSNumber *, MADSectionLayout *> *sectionTemplate;

@end

@implementation MADReportFormatter {
    NSUInteger _numberOfGroups;
    NSString *_filename;
}

- (void)dealloc {
    _document = nil;
}

- (instancetype)initWithDocument: (MADocument *)layout
                         options: (MADReportFormatterOptions)options  {
    if (self = [super init]) {
        
        self.cachedDelegate = layout;
        self.dataDelegate = layout;
        self.datasource = layout;
        self.layout = layout;
        
        for (NSString *entityName in layout.managedObjectModel.entitiesByName) {
            NSEntityDescription *entityDescription = layout.managedObjectModel.entitiesByName[entityName];
            NSLog(@"%@\n%@\n\n", entityName, entityDescription);
            for (NSPropertyDescription *propertyDescription in entityDescription.properties) {
                NSLog(@"Property: %@", propertyDescription);
            }
        }
        
        _filename = layout.filename.copy;
        
        MADPageOptions *page = [[MADPageOptions alloc] init];
        self.page = page;
        
        self.page.margins = (options & MADReportFormatterOptionsMargin) ?
                                    MADEdgeInsetsQuarterInch() :
                                    MADEdgeInsetsEmpty();
        
        MADReportFormatterState *machineState = [[MADReportFormatterState alloc] init];
        self.machineState = machineState;
        
        [self initializeStateMachine];
        
        MADReportFormatterCache *reportFormatterCache = [[MADReportFormatterCache alloc] init];
        self.reportFormatterCache = reportFormatterCache;
        
        NSMutableArray <__kindof MADSectionRepresentation *> *temporaryLayoutForPage;
        temporaryLayoutForPage = [[NSMutableArray alloc] init];
        self.pageLayoutTemporary = temporaryLayoutForPage;
        
        NSMutableArray *temporaryDataForPage = [[NSMutableArray alloc] init];
        self.pageIndexesTemporary = temporaryDataForPage;
        
        NSDictionary <NSNumber *, NSNumber *> *layoutHeightsBySectionKeys;
        layoutHeightsBySectionKeys = [layout layoutHeightsBySectionKey];
        self.layoutHeightsBySectionKey = layoutHeightsBySectionKeys;
    
        self.options = options;
        self.didRefresh = NO;
        
    }
    return self;
}

+ (instancetype)newReportFormatterWithLayout: (MADocument *)layout
                                     options: (MADReportFormatterOptions)options {
    MADReportFormatter *result = [[MADReportFormatter alloc] initWithDocument: layout
                                                                    options: options];
    return result;
}

#pragma mark - Accessors

- (NSArray <MADSectionRepresentation *> *)layoutForPage:(NSUInteger)page {
    NSArray <MADSectionRepresentation *> *result;
    result = page < (NSUInteger)_reportLayout.count ? _reportLayout[page] : nil;
    return result;
}

- (NSUInteger)layoutIdentifier {
    return _overrideIdentifier == nil ?
                    _filename.hash :
                    _overrideIdentifier.hash;
}

- (NSString *)newStringNameCurrentReportIndexes:(CGSize)size andHash:(unsigned long)hash {
    NSString *sizeString = NSStringFromCGSize(_page.layoutSize);
    NSString *name;
    name = [[NSString alloc] initWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier],
                                                        "ih", sizeString];
    return name;
}

- (NSString *)newStringNameCurrentReportLayout:(CGSize)size andHash:(unsigned long)hash {
    NSString *sizeString = NSStringFromCGSize(_page.layoutSize);
    NSString *name;
    name = [[NSString alloc] initWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier],
                                                        "lh", sizeString];
    return name;
}

- (void)initializeStateMachine {
    NSArray *sd = [self.dataDelegate sortDescriptors];
    NSArray *sortDescriptors = [[NSArray alloc] initWithArray:sd];
    
    _machineState.rowCounter = 0;
    _machineState.groupCounter = 0;
    _machineState.pageCounter = 0;
    _machineState.detailRowId = 0;
    _machineState.detailRowIdLast = 0;
    _machineState.sortDescriptors = sortDescriptors;
    _machineState.counterHeightUsedCurrentPage = CGSizeZero.height;
    self.document = [self.layout activeDocumentModel];
}

- (void)setMarginUsingPrintableRect:(CGRect)printableRect {
    self.page.margins = MADEdgeInsetsPrinting(printableRect, self.page.layoutSize);
}

#pragma mark - Reading cached data

- (BOOL)cachedIndexesExist {
    return _reportIndexes.count > 0 && _reportLayout.count > 0;
}

- (BOOL)needsFormat {
    id <MADReportFormatterDataSource> datasource = self.datasource;
    NSAssert(datasource != nil, @"We need a datatable way before here");
    return self.didRefresh ||
            (self.reportIndexes.count > 0 && self.reportLayout.count > 0) == NO ||
                ![datasource cacheExist];
}

- (void)formatForSize:(CGSize)printableSize {
    [self formatForSize:printableSize contentChanged:YES];
}

- (void)setLayoutSize:(CGSize)layoutSize {
    self.page.layoutSize = layoutSize;
}

- (void)loadFromCacheWithSize:(CGSize)printableSize {
    self.didRefresh = NO;
    self.page.layoutSize = printableSize;
    [self loadLayoutAndIndexesFromCache];
}

- (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged {

    if (contextChanged == NO || self.needsFormat) {
        @synchronized(self) {
            [self setLayoutSize:printableSize];
            [self loadLayoutAndIndexesFromCache];
            if (self.needsFormat) {
                
                if (contextChanged) {
                    [self dropIndexes];
                }
                [self formatDocument];
            }
        }
    } else {
        [self formatForSize:printableSize contentChanged:NO];
    }
}

- (void)formatDocument {
    
    
    
    MADocument *layout = _layout;
    NSManagedObjectContext *managedObjectContext = layout.managedObjectContext;
    
    MADSectionsLayout *sections;
    Class databaseClass = [layout.database class];
    sections = [[MADSectionsLayout alloc] initWithManagedObjectContext: managedObjectContext
                                                         databaseClass: databaseClass];
    self.sections = sections;
    
    //MADSectionLayout *sl = [[MADSectionLayout alloc] init];
    //_numberOfGroups = [RptqQueryGroup numberOfGroupsForQueryID:nil managedObjectContext:managedObjectContext];
    /*
    NSFetchRequest *fetchRequestDocumentSections = [RptqDocumentSection fetchRequestDocumentSections];

    NSError *error = nil;
    NSArray <NSDictionary *> *documentSections;
    documentSections = [managedObjectContext executeFetchRequest: fetchRequestDocumentSections
                                                           error: &error];
    
    NSLog(@"%@", documentSections);
    NSString *keyPathInReportHeader = [RptqDocumentSection keyPathInReportHeader];
    NSUInteger expressionInQueryCount = 2;
    NSExpression *pexpressions[expressionInQueryCount];
    pexpressions[0] = [NSExpression expressionForKeyPath:keyPathInReportHeader];
    pexpressions[1] = [NSExpression expressionForConstantValue:nil];
    
    NSPredicate *predicateReportHeaderNotNull;
    predicateReportHeaderNotNull = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                                      rightExpression: pexpressions[1]
                                                                             modifier: NSDirectPredicateModifier
                                                                                 type: NSNotEqualToPredicateOperatorType
                                                                              options: 0];
    
    NSArray <NSDictionary *> *reportHeaderSections = [documentSections filteredArrayUsingPredicate:predicateReportHeaderNotNull];
    
    NSLog(@"%@", reportHeaderSections);
    */
    [self.machineState resetWithDataDelegate:self.dataDelegate];
    NSUInteger i = 0;
    for (MADSectionGroupLayout *groupSection in self.sections.groupHeaders) {
        NSLog(@"Sort %lu: %@", (unsigned long)i, [groupSection sortDescriptor]);
        NSLog(@"Sort %lu: %@", (unsigned long)i, self.machineState.sortDescriptors[i]);
        i++;
    }

    [layout resetSectionLayoutManagers];
    
    self.machineState.counterHeightUsedCurrentPage += self.page.margins.top;

    NSDictionary <NSNumber *, NSNumber *> *layoutHeightsBySectionKeys;
    layoutHeightsBySectionKeys = [layout layoutHeightsBySectionKey];
    
    self.layoutHeightsBySectionKey = layoutHeightsBySectionKeys;
    [self cleanupTemporaryIndexes];
    
    [self beginBulkInserts];
    
    [self addReportHeaderToReportLayout];
    [self addPageHeaderToReportLayout];
    [self addDetailToReportLayout];
    [self addReportFooterToReportLayout];
    
    NSArray <MADSectionRepresentation *> *tlfp;
    tlfp = [NSMutableArray arrayWithArray:self.pageLayoutTemporary];
    [self.reportLayout addObject:tlfp];
    
    NSArray <NSNumber *> *tdfp = [NSArray arrayWithArray:self.pageIndexesTemporary];
    [self.reportIndexes addObject:tdfp];
    
    [self endBulkInserts];
    
    [self cleanupTemporaryIndexes];
    
    // FIXME: This cache is being set, but it is not being loaded.
    [self.reportFormatterCache setLayout: self.reportLayout.identifier
                              andIndexes: self.reportIndexes.identifier
                                 forSize: self.page.layoutSize];
    
}

- (void)dropIndexes {
    [self.reportIndexes removeAllObjects];
    [self.reportLayout removeAllObjects];
}

- (void)dumpCache {
    [self.reportFormatterCache dumpCache];
}

- (void)beginBulkInserts {
    [self.reportIndexes beginBulkInserts];
    [self.reportLayout beginBulkInserts];
}

- (void)endBulkInserts {
    [self.reportLayout endBulkInserts];
    [self.reportIndexes endBulkInserts];
}

- (void)loadLayoutAndIndexesFromCache {

    [self.reportIndexes finalizeDatabase];
    [self.reportLayout finalizeDatabase];

    id <MADCacheProtocol> cachedDelegate = self.cachedDelegate;
    
    NSString *nixarray;
    nixarray = [self newStringNameCurrentReportIndexes: _page.layoutSize
                                               andHash: (unsigned long)[self layoutIdentifier]];

    MADArrayCaching *ixarray;
    ixarray = [[MADArrayCaching alloc] initWithIdentifier: nixarray
                                           cachedDelegate: cachedDelegate];
    [ixarray initializeDatabase];
    
    self.reportIndexes = ixarray;
    
    NSString *nlyarray;
    nlyarray = [self newStringNameCurrentReportLayout: _page.layoutSize
                                              andHash: (unsigned long)[self layoutIdentifier]];
    
    MADArrayCaching *lyarray = [[MADArrayCaching alloc] initWithIdentifier: nlyarray
                                                            cachedDelegate: cachedDelegate];
    [lyarray initializeDatabase];
    self.reportLayout = lyarray;
    
    [self cleanupTemporaryIndexes];
}

- (void)initReportLayoutContainers {
    [self.reportLayout removeAllObjects];
    [self.reportIndexes removeAllObjects];
    self.lastComparsonValues = nil;
}

- (void)cleanupTemporaryIndexes {
    [_pageLayoutTemporary removeAllObjects];
    [_pageIndexesTemporary removeAllObjects];
}

- (NSUInteger)numberOfGroups {
    return self.machineState.sortDescriptors.count;
}

- (void)displayNewGroupFootersIfNeeded:(NSArray *)currentValues
                         andLastValues:(NSArray *)lastValues {
    for (NSUInteger groupLevel = lastValues.count; groupLevel > 0; groupLevel--) {
        @autoreleasepool {
            NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel - 1];
            NSComparisonResult comparsonResult = [self compareValue: lastValues[groupLevel - 1]
                                                          withValue: currentValues[groupLevel - 1]
                                                      usingSelector: sortDesc.selector];
            
            if (comparsonResult != NSOrderedSame) {
                RptqQueryGroup *group = self.sortedQueryGroups[groupLevel - 1];
                [self addHeightFromGroupFooterWithQueryGroup: group];
                [self addGroupFooterAtLevel:groupLevel - 1];
            }
        }
    }
}

- (void)displayNewGroupHeadersIfNeeded:(NSArray *)currentValues
                         andLastValues:(NSArray *)lastValues {

    for (NSUInteger groupLevel = 0; groupLevel < currentValues.count; groupLevel++) {
        @autoreleasepool {
            BOOL newHeader = lastValues.count == 0;
            if (newHeader == NO) {
                
                id value = lastValues[groupLevel];
                id value2 = currentValues[groupLevel];
                
                NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel];
                NSComparisonResult comparsonResult = [self compareValue:value
                                                              withValue:value2
                                                          usingSelector:sortDesc.selector];
                
                newHeader = comparsonResult != NSOrderedSame;
            }
            
            if (newHeader) {
                RptqQueryGroup *queryGroup = [self.document.mainQuery queryGroupForIndex:groupLevel];
                // Add group header height.
                for (RptqDocumentSection *documentSection in queryGroup.hasSection.allObjects) {
                    if (documentSection.type == MADDocumentSectionTypeGroupHeader) {
                        NSNumber *identifier = @(documentSection.identifier);
                        [self addHeightFromSectionToReportLayout:identifier
                                                producesFormFeed:documentSection.producesFormFeed];
                        break;
                    }
                }
                
                [self addGroupHeaderLevel:groupLevel];
            }
        }
    }
}

- (NSComparisonResult)compareValue:(id)value withValue:(id)value2 usingSelector:(SEL)selector {
    NSComparisonResult comparsonResult;
    
    if (value == [NSNull null]) {
        
        if (value2 == [NSNull null]) {
            comparsonResult = NSOrderedSame;
        
        } else {
            comparsonResult = NSOrderedAscending;
        
        }
    } else if (value2 == [NSNull null]) {
        
        comparsonResult = NSOrderedDescending;
        
    } else {
        if (selector == @selector(localizedCaseInsensitiveCompare:)) {
            comparsonResult = [value localizedCaseInsensitiveCompare:value2];
        } else if (selector == @selector(compareData:)) {
            if ([value respondsToSelector:@selector(compareData:)]) {
                comparsonResult = [value compareData:value2];
            } else if ([value respondsToSelector:@selector(localizedCaseInsensitiveCompare:)]) {
                comparsonResult = [value caseInsensitiveCompare:value2];
            } else {
                comparsonResult = [value compare:value2];
            }
        } else {
            comparsonResult = [value compare:value2];
        }
    }
    return comparsonResult;
}

- (NSArray <NSNumber *> *)rowidsForPage:(NSUInteger)pageIndex {
    return _reportIndexes[pageIndex];
}

/*- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails {
    for (NSInteger i=0; i<[containerDetails count]; i++) {
        @autoreleasepool {
            [self addHeightFromDocumentSectionToReportLayout: self.layout.document.hasDetailSection];
            NSNumber *rowid = containerDetails[i][MADIdentifierROWID];
            self.machineState.detailRowId = rowid;
            [self addDetail];

        }
    }
}*/

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupFooterWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in queryGroup.hasSection.allObjects) {
        if (documentSection.type == MADDocumentSectionTypeGroupFooter) {
            NSNumber *identifier = @(documentSection.identifier);
            [self addHeightFromSectionToReportLayout:identifier
                                    producesFormFeed:documentSection.producesFormFeed];
            break;
        }
    }
}



//  ObjectID from RptqDocumentSection *
- (CGFloat)heightForSectionWithObjectIdentifier:(NSNumber *)objectID {
    NSNumber *sectionHeight = _layoutHeightsBySectionKey[objectID];
    return sectionHeight.floatValue;
}

- (void)addHeightFromSectionToReportLayout:(NSNumber *)identifier
                          producesFormFeed:(BOOL)producesFormFeed {
    CGFloat layoutHeight = [self heightForSectionWithObjectIdentifier:identifier];
    if (producesFormFeed) {
        NSNumber *pageFooterIdentifier = @(self.document.hasPageFooterSection.identifier);
        [self forcePageBreakWithFooterHeight:
         [self heightForSectionWithObjectIdentifier: pageFooterIdentifier]
         ];
    } else {
        [self addPageBreakToReportLayoutWithNextItemHeight: layoutHeight];
    }
    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage + layoutHeight;
}

/*- (RptqQueryGroup *)sortGroupAtLevel:(NSUInteger)level {
    RptqQueryGroup *nextGroup = nil;
    if (level < self.sortedQueryGroups.count) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == %d", level];
        NSArray *filteredGroups = [self.sortedQueryGroups filteredArrayUsingPredicate: predicate];
        if (filteredGroups.count >= 1) {
            nextGroup = filteredGroups.firstObject;
        }
    }
    return nextGroup;
}*/

- (void)addDetailToReportLayout {
    [self initReportLayoutContainers];
    _machineState.rowCounter = 0;
    
    RptqDocumentSection *detailSection = self.document.hasDetailSection;
    
    BOOL firstRow = YES;
    
    NSArray *sortedQueryGroups = [self.layout.mainQuery.queryObject sortedQueryGroups];
    self.sortedQueryGroups = sortedQueryGroups.copy;
    
    BOOL rowIdOnly = YES;
    BOOL calculatedRowId = NO;

    id lastResultRow = nil;

    NSEnumerator *enumeratorForReportData = [self.datasource enumeratorForReportData];
    NSArray *keyValuesForComparson;
    
    for (id resultRow in enumeratorForReportData) {

        @autoreleasepool {
            
            //Get row id
            if (!calculatedRowId) {
                if ([resultRow isKindOfClass:[NSDictionary class]]) {
                    rowIdOnly = NO;
                }
                calculatedRowId = YES;
            }
            
            self.machineState.detailRowIdLast = self.machineState.detailRowId;
            
            self.machineState.detailRowId = rowIdOnly ? ((NSNumber *)resultRow).unsignedIntegerValue : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
            
            //Get row key values
            keyValuesForComparson = [self newObjectArrayKeyValuesForResultRow:resultRow];
            
            //Display new footers if needed.
            if (firstRow) {
                firstRow = NO;
            } else {
                [self displayNewGroupFootersIfNeeded: keyValuesForComparson
                                       andLastValues: self.lastComparsonValues];
            }
            
            //Display new group headers if needed.
            [self displayNewGroupHeadersIfNeeded: keyValuesForComparson
                                   andLastValues: self.lastComparsonValues];
            
            NSNumber *detailSectionIdentifier = @(detailSection.identifier);
            [self addHeightFromSectionToReportLayout: detailSectionIdentifier
                                    producesFormFeed: detailSection.producesFormFeed];
            
            [MADReportFormatter addDetailForRowID: self.machineState.detailRowId
                                       pageLayout: self.pageLayoutTemporary
                                      pageIndexes: self.pageIndexesTemporary];
            
            self.lastComparsonValues = keyValuesForComparson;
            
            self.machineState.rowCounter++;
            
        }
        lastResultRow = resultRow;
    }
    //Need to account for the last set of group footers.
    if (!lastResultRow) return;
        
    keyValuesForComparson = [self newObjectArrayKeyValuesForResultRow:lastResultRow];
    NSUInteger groupLevel = keyValuesForComparson.count;
    while (groupLevel >= 1) {
        @autoreleasepool {
            RptqQueryGroup *group = _sortedQueryGroups[groupLevel - 1];
            [self addHeightFromGroupFooterWithQueryGroup: group];
            [self addGroupFooterAtLevel:groupLevel-1];
        }
        groupLevel--;
    }
}

- (NSArray *)newObjectArrayKeyValuesForResultRow:(id)resultRow {


    NSMutableArray *keyValues;
    keyValues = [[NSMutableArray alloc] initWithCapacity:self.numberOfGroups];
    
    if ([resultRow isKindOfClass:[NSDictionary class]]) {

        id predicateValue;
        for (NSSortDescriptor *sortDesc in self.machineState.sortDescriptors) {
            NSString *key = sortDesc.key;
            if (key) {
                predicateValue = resultRow[key];
                if (predicateValue != nil) {
                    [keyValues addObject:predicateValue];
                } else {
                    [keyValues addObject:[NSNull null]];
                }
                predicateValue = nil;
            }
        }
    }
    return keyValues;
}

// FIXME: Make sure paper rect is passed in to the software
- (BOOL)addPageBreakToReportLayoutWithNextItemHeight:(CGFloat)nextItemHeight {
    
    BOOL newPageCreated = NO;
    
    NSNumber *identifer = @(self.document.hasPageFooterSection.identifier);
    CGFloat pageFooterSectionHeight = [self heightForSectionWithObjectIdentifier:identifer];
    
    if (HeightWithNextItem(self.machineState.counterHeightUsedCurrentPage, nextItemHeight, pageFooterSectionHeight) >
        PrintableHeightForPage(self.page)) {
        
        newPageCreated = YES;
        [self forcePageBreakWithFooterHeight:pageFooterSectionHeight];
    }

    return newPageCreated;
}

- (void)forcePageBreakWithFooterHeight:(CGFloat)footerHeight {

    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage +
                                                 footerHeight;
    [self addPageFooter];
    
    id pageInfo = self.pageLayoutTemporary != nil ?
                            [NSMutableArray arrayWithArray: self.pageLayoutTemporary] :
                            [[NSArray alloc] init];
    
    [self.reportLayout addObject:pageInfo];
    
    NSArray <NSNumber *> *rowids = self.pageIndexesTemporary != nil ?
                                [NSArray arrayWithArray: self.pageIndexesTemporary] : @[];
    [self.reportIndexes addObject:rowids];
    
    [self cleanupTemporaryIndexes];
    
    _machineState.pageCounter++;
    
    [[MADNotificationDidFormatPage sharedObject] reportFormatter: self
                                                   formattedPage: self.machineState.pageCounter];
    
    RptqDocumentSection *pageHeaderSection = (self.document).hasPageHeaderSection;
    
    //Reset height of the page to zero plus the hight of the page header section
    NSNumber *pageHeaderSectionIdentifier = @(pageHeaderSection.identifier);
    _machineState.counterHeightUsedCurrentPage = [self heightForSectionWithObjectIdentifier: pageHeaderSectionIdentifier];
    
    [self addPageHeader];
}

- (void)addReportHeaderToReportLayout {
    NSNumber *identifier = @(self.document.hasReportHeaderSection.identifier);
    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage +
                                                [self heightForSectionWithObjectIdentifier: identifier];
    [self addReportHeader];
}

- (void)addPageHeaderToReportLayout {
    NSNumber *identifier = @(self.document.hasPageHeaderSection.identifier);
    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage +
                                                 [self heightForSectionWithObjectIdentifier: identifier];
    [self addPageHeader];
}

- (void)addPageFooterToReportLayout {
    NSNumber *identifier = @(self.document.hasPageFooterSection.identifier);
    [self addHeightFromSectionToReportLayout: identifier
                            producesFormFeed: self.document.hasPageFooterSection.producesFormFeed];
    [self addPageFooter];
}

- (void)addReportFooterToReportLayout {
    NSNumber *identifier = @(self.document.hasReportFooterSection.identifier);
    [self addHeightFromSectionToReportLayout: identifier
                            producesFormFeed: self.document.hasReportFooterSection.producesFormFeed];
    [self addPageFooterToReportLayout];
    [self addReportFooter];
}

- (void)addGroupHeaderLevel:(NSUInteger)groupLevel {
    MADSectionRepresentation *header;
    header = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeGroupHeader
                                                     groupLevel: groupLevel
                                                            row: _machineState.detailRowId];
    if (groupLevel == self.numberOfGroups - 1) {
        self.machineState.groupCounter++;
    }
    [self.pageLayoutTemporary addObject: header];
}

- (void)addPageFooter {
    MADSectionRepresentation *footer;
    footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypePageFooter
                                                            row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addReportFooter {
    MADSectionRepresentation *footer;
    footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeReportFooter
                                                            row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addGroupFooterAtLevel:(NSUInteger)groupLevel {
    MADSectionRepresentation *footer;
    footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeGroupFooter
                                                     groupLevel: groupLevel
                                                            row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

+ (void)addDetailForRowID:(NSUInteger)rowID
               pageLayout:(byref inout NSMutableArray <__kindof MADSectionRepresentation *> *)pageLayout
              pageIndexes:(byref inout NSMutableArray <NSNumber *> *)pageIndexes {
    MADSectionRepresentation *detail;
    detail = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeBody
                                                            row: rowID];
    [pageLayout     addObject: detail];
    [pageIndexes    addObject: @(rowID)];
}

- (void)addReportHeader {
    MADSectionRepresentation *obj;
    obj = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeReportHeader
                                                        row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: obj];
}

- (void)addPageHeader {
    MADSectionRepresentation *obj;
    obj = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypePageHeader
                                                         row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject:  obj];
}

- (NSUInteger)numberOfPages {
    return (NSUInteger)self.reportLayout.count;
}

/*
 // FIXME: Write function to return results for keys without having data stored in memeory.
 */

+ (id)dataForGroupData:(id)data andKeys:(NSArray *)keys NS_RETURNS_RETAINED {
    id resultData = nil;
    if ([data isKindOfClass:[NSArray class]]) {
        resultData = [[NSArray alloc] initWithArray:data];
    } else {
        if (keys.count > 0) {
            id subData = data[keys[0]];
            NSArray *subKeys = nil;
            if (keys.count > 1) {
                NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, keys.count - 1)];
                subKeys = [keys objectsAtIndexes:set];
                resultData = [MADReportFormatter dataForGroupData:subData andKeys:subKeys];
            } else if (keys.count == 1) {
                resultData = subData;
            } else {
                resultData = subData;
            }
        } else {
            resultData = @[];
        }
    }
    return resultData;
}

- (NSEnumerator <__kindof MADSectionRepresentation *> *)layoutEnumeratorForPage:(NSUInteger)pageIndex {
    NSArray <MADSectionRepresentation *> *pageLayout = self.reportLayout[pageIndex];
    return pageLayout.objectEnumerator;
}

#pragma mark - Help functions

- (BOOL)isLandscape {
#ifdef MADWATCHKIT
    return NO;
#else
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
#endif
}

@end
