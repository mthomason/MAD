//
//  MTPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerPrintPageRenderer.h"

const NSString *MTReportSectionType = @"MTReportSectionType";
const NSString *MTReportSectionValues = @"MTReportSectionValues";
const NSString *MTReportGroupLevel = @"MTReportGroupLevel";

const NSString *MTPageDetail = @"MTPageDetail";
const NSString *MTPageHeader = @"MTPageHeader";
const NSString *MTPageFooter = @"MTPageFooter";
const NSString *MTReportHeader = @"MTReportHeader";
const NSString *MTReportFooter = @"MTReportFooter";
const NSString *MTReportGroupHeader = @"MTReportGroupHeader";
const NSString *MTReportGroupFooter = @"MTReportGroupFooter";

@interface MTReportViewerPrintPageRenderer ()

@property (nonatomic, assign) CGSize printableSize;

@property (nonatomic, assign) RptqDocument *document;

@property (nonatomic, copy) NSArray *cachedLayoutByPage;
@property (nonatomic, copy) NSArray *cachedSortedSortDescriptorsGroup;
@property (nonatomic, copy) NSArray *cachedDataByPage;
@property (nonatomic, copy) NSDictionary *cachedDataByGroup;
@property (nonatomic, copy) NSArray *cachedDataByReport;

@property (nonatomic, retain) NSMutableArray *temporaryLayoutByPage;
@property (nonatomic, retain) NSMutableArray *temporaryLayoutForPage;

@property (nonatomic, retain) NSMutableArray *temporaryDataByPage;
@property (nonatomic, retain) NSMutableArray *temporaryDataForPage;

@property (nonatomic, retain) NSMutableDictionary *temporaryDataByGroup;
@property (nonatomic, retain) NSMutableDictionary *temporaryDataByReport;

@property (nonatomic, assign) NSUInteger temporaryCachedDetailCounter;

@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;

@property (nonatomic, assign) BOOL debugMode;

@property (nonatomic, assign) CGSize cachedPageSize;
@property (nonatomic, assign) CGRect cachedPageRect;

@end

@implementation MTReportViewerPrintPageRenderer

- (oneway void)release {
    
    [_cachedLayoutByPage release];
    [_cachedDataByPage release];
    [_cachedDataByGroup release];
    [_cachedDataByReport release];

    [_temporaryLayoutByPage release];
    [_temporaryLayoutForPage release];
    
    [_temporaryDataByPage release];
    [_temporaryDataForPage release];
    
    [_temporaryDataByGroup release];
    [_temporaryDataByReport release];

    [_cachedSortedSortDescriptorsGroup release];
    
}

- (id)retain {
    self = [super retain];
    if (self) {
        
        [_cachedLayoutByPage retain];
        [_cachedDataByPage retain];
        [_cachedDataByGroup retain];
        [_cachedDataByReport retain];
        
        [_temporaryLayoutByPage retain];
        [_temporaryLayoutForPage retain];

        [_temporaryDataByPage retain];
        [_temporaryDataForPage retain];
        
        [_temporaryDataByGroup retain];
        [_temporaryDataByReport retain];

        [_cachedSortedSortDescriptorsGroup retain];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTReportViewerPrintPageRenderer *copy = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:[self document]];
    if (copy) {
        
        [copy setDocument:[self document]];
        [copy setCachedLayoutByPage:[self cachedLayoutByPage]];
        [copy setCachedDataByGroup:[self cachedDataByGroup]];
        [copy setCachedDataByPage:[self cachedDataByPage]];
        [copy setCachedDataByReport:[self cachedDataByReport]];
        [copy setCachedSortedSortDescriptorsGroup:[self cachedSortedSortDescriptorsGroup]];

    }
    return copy;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setDocument:[RptqDocument activeDocument]];
        [self initCommon];
    }
    return self;
}

- (void)initCommon {

    NSMutableArray *a1 = [[NSMutableArray alloc] init];
    [self setTemporaryLayoutByPage:a1];
    [a1 release];
    
    NSMutableArray *a2 = [[NSMutableArray alloc] init];
    [self setTemporaryLayoutForPage:a2];
    [a2 release];
    
    NSMutableDictionary *d2 = [[NSMutableDictionary alloc] init];
    [self setTemporaryDataByReport:d2];
    [d2 release];
    
    NSMutableArray *d3 = [[NSMutableArray alloc] init];
    [self setTemporaryDataByPage:d3];
    [d3 release];
    
    NSMutableDictionary *d4 = [[NSMutableDictionary alloc] init];
    [self setTemporaryDataByGroup:d4];
    [d4 release];
    
    NSMutableArray *d5 = [[NSMutableArray alloc] init];
    [self setTemporaryDataForPage:d5];
    [d5 release];
    
    [self setDebugMode:NO];

    [self setCachedPageSize:CGSizeZero];
    [self setCachedPageRect:CGRectZero];
}

- (id)initWithDocument:(RptqDocument *)document {
    CGSize printableSize = CGSizeMake(CGFloatPointsForInches(8.5000f), CGFloatPointsForInches(11.0000f));
    return [self initWithDocument:document andPrintableAreaSize:printableSize];
}

- (id)initWithDocument:(RptqDocument *)document andPrintableAreaSize:(CGSize)printableAreaSize {
    self = [super init];
    if (self) {
        
        [self initCommon];
        [self setPrintableSize:printableAreaSize];
        [self setDocument:document];
        
    }
    return self;
}

#pragma mark - UIPrintPageRenderer Overrides

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    
    CGFloat originY = pageRect.origin.y;
    CGFloat originX = pageRect.origin.x;
    CGFloat sizeWidth = pageRect.size.width;

    NSUInteger detailRowsCounter = 0;
    NSUInteger pageNumber = 0;

    RptqQuery *query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];

    NSUInteger numberOfGroups = [[query hasQueryGroups] count];
    NSMutableArray *groupLevelKeys = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
    
    if (index < [[self cachedLayoutByPage] count]) {

        NSArray *pageArray = [[[self cachedLayoutByPage] objectAtIndex:index] retain];
        NSArray *pageSectionsToPrint = [[NSArray alloc] initWithArray:pageArray];
        [pageArray release];
        
        CGRect sectionRect = CGRectZero;
        
        for (NSDictionary *pageSection in pageSectionsToPrint) {
            
            NSString *pageSectionId = [[NSString alloc] initWithString:[pageSection objectForKey: MTReportSectionType]];
            id reportSectionValues = nil;
            
            NSNumber *groupLevel = nil;
            
            RptqDocumentSection *documentSection = nil;
            CGFloat sizeHeight = CGSizeZero.height;
            
            if ([MTPageDetail isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasDetailSection];
                sizeHeight = [[documentSection layoutHeight] floatValue];
                
                [[UIColor whiteColor] set];
                
                detailRowsCounter++;
                
            } else if ([MTPageHeader isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageHeaderSection];
                sizeHeight = [[documentSection layoutHeight] floatValue];
                
                if ([self debugMode]) {
                    [[UIColor yellowColor] set];
                } else {
                    [[UIColor whiteColor] set];
                }
            
            } else if ([MTPageFooter isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageFooterSection];
                sizeHeight = [[documentSection layoutHeight] floatValue];
                originY = pageRect.origin.y + pageRect.size.height - sizeHeight;

                if ([self debugMode]) {
                    [[UIColor yellowColor] set];
                } else {
                    [[UIColor whiteColor] set];
                }
                
                pageNumber++;
                
            } else if ([MTReportHeader isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasReportHeaderSection];
                sizeHeight = [[documentSection layoutHeight] floatValue];

                if ([self debugMode]) {
                    [[UIColor greenColor] set];
                } else {
                    [[UIColor whiteColor] set];
                }
                
            } else if ([MTReportFooter isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasReportFooterSection];
                CGFloat sizeHeightReportFooter = [[documentSection layoutHeight] floatValue];
                RptqDocumentSection *pageFooterSection = [[self document] hasPageFooterSection];
                CGFloat sizeHeightPageFooter = [[pageFooterSection layoutHeight] floatValue];
                originY = pageRect.origin.y + pageRect.size.height - sizeHeightReportFooter - sizeHeightPageFooter;
                sizeHeight = sizeHeightReportFooter;

                if ([self debugMode]) {
                    [[UIColor greenColor] set];
                } else {
                    [[UIColor whiteColor] set];
                }

            } else if ([MTReportGroupHeader isEqualToString:pageSectionId]) {
                
                groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                documentSection = [RptqDocumentSection getDocumentGroupHeaderAtLevel:[groupLevel integerValue] forQuery:query];
                
                sizeHeight = [[documentSection layoutHeight] floatValue];

                if ([self debugMode]) {
                    [[UIColor lightGrayColor] set];
                } else {
                    [[UIColor whiteColor] set];
                }
                
            } else if ([MTReportGroupFooter isEqualToString:pageSectionId]) {
                
                groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                
                //[groupLevelKeys setObject:@"" atIndexedSubscript:groupLevel];
                query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                documentSection = [RptqDocumentSection getDocumentGroupFooterAtLevel:[groupLevel integerValue] forQuery:query];
                sizeHeight = [[documentSection layoutHeight] floatValue];
                
                if ([self debugMode]) {
                    [[UIColor lightTextColor] set];
                } else {
                    [[UIColor whiteColor] set];
                }

            }
        
            sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
            
            CGFloat sectionHeight = CGSizeZero.height;
            
            for (RptqDocumentSectionRows *row in [documentSection hasRows]) {

                CGFloat rowHeight = CGSizeZero.height;
                CGFloat objectHeight;
                
                for (RptqDocumentObject *object in [row hasObjects]) {
                    objectHeight = [object viewSize].height;
                    if (objectHeight > rowHeight) {
                        rowHeight = objectHeight;
                    }
                }
                
                if (rowHeight > sectionHeight) {
                    sectionHeight = rowHeight;
                }
                
            }
            
            [[UIBezierPath bezierPathWithRect:sectionRect] fill];
            
            id obj = [pageSection objectForKey:MTReportSectionValues];

            if ([obj isKindOfClass:[NSDictionary class]]) {
            
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:obj];
            
            } else if ([obj isKindOfClass:[NSArray class]]) {
            
                reportSectionValues = [[NSArray alloc] initWithArray:obj];
            
            }
            
            NSUInteger detailRowToPrint = (detailRowsCounter == 0 ? detailRowsCounter : detailRowsCounter - 1);
            NSDictionary *rowData = [self rowDataForRow: detailRowToPrint
                                                 onPage: index];
            if (rowData != nil) {

                [groupLevelKeys removeAllObjects];
                for (NSSortDescriptor *sortDescriptor in [self cachedSortedSortDescriptorsGroup]) {
                    id sortKey = [[rowData objectForKey:[sortDescriptor key]] retain];
                    [groupLevelKeys addObject:sortKey];
                    [sortKey release];
                }
            
                for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                    for (RptqDocumentObject *item in [row hasObjects]) {
                        
                        NSString *displayString = nil;
                        id drawingObject = nil;

                        switch ([item getType]) {
                                
                            case MTDocumentObjectTypeAggregate: {
                                
                                RptqDocumentObjectAggregate *aggregateField = [item isAggregate];
                                
                                RptqQueryField *queryField = [aggregateField aggregateField];
                                
                                NSArray *dataForGroup = nil;

                                MTAggregateGroupByType aggregateGroupType = [[aggregateField groupType] integerValue];

                                switch (aggregateGroupType) {
                                        
                                    case MTAggregateGroupByTypePage:
                                        dataForGroup = [[[self cachedDataByPage] objectAtIndex:pageNumber] retain];
                                        break;
                                        
                                    case MTAggregateGroupByTypeSection:
                                        dataForGroup = [[self dataForCachedGroupData:[self cachedDataByGroup] andKeys:groupLevelKeys] retain];
                                        break;
                                        
                                    case MTAggregateGroupByTypeReport:
                                        dataForGroup = [[[self cachedDataByReport] objectAtIndex:pageNumber] retain];
                                        break;
                                        
                                    default:
                                        dataForGroup = [[[self cachedDataByReport] objectAtIndex:pageNumber] retain];
                                        break;
                                }
                                
                                NSString *fieldKey = [queryField toString];
                                
                                MTDataType aggregateType = [[[queryField databaseSchemaField] dataType] integerValue];
                                id aggregateResult = nil;
                                switch ([[aggregateField function] integerValue]) {
                                        
                                    case MTAggregateFunctionTypeCount:
                                        aggregateResult = @([dataForGroup count]);
                                        break;
                                        
                                    case MTAggregateFunctionTypeFirst:
                                        aggregateResult = [[dataForGroup objectAtIndex:0] objectForKey:fieldKey];
                                        break;
                                        
                                    case MTAggregateFunctionTypeLast:
                                        aggregateResult = [[dataForGroup lastObject] objectForKey:fieldKey];
                                        break;
                                        
                                    case MTAggregateFunctionTypeMax: {
                                        
                                        id result = nil;
                                        for (id object in dataForGroup) {
                                            id n = [self valueForGroupDetailData:object ofType:aggregateGroupType withKey:fieldKey andPage:index];
                                            if ([n compare:result] == NSOrderedDescending) {result = n;}
                                        }
                                        aggregateResult = result;
                                        
                                        break;
                                    }
                                    
                                    case MTAggregateFunctionTypeMean: {
                                        
                                        
                                        id sum = @(0);
                                        for (id object in dataForGroup) {
                                            id n = [self valueForGroupDetailData:object ofType:aggregateGroupType withKey:fieldKey andPage:index];
                                            
                                            sum = [self sumObject:sum andObject:n forType:aggregateType];
                                            
                                        }
                                        NSUInteger dataForGroupCount = [dataForGroup count];

                                        // FIXME: Should this sum float value be typed with a devideObject as the sumObject above?
                                        
                                        aggregateResult = @(dataForGroupCount > 0 ? ([sum floatValue] / dataForGroupCount) : dataForGroupCount);

                                        
                                        break;
                                    }
                                    
                                    case MTAggregateFunctionTypeMin: {
                                        
                                        id result = nil;
                                        for (id object in dataForGroup) {
                                            id n = [self valueForGroupDetailData:object ofType:aggregateGroupType withKey:fieldKey andPage:index];
                                            if ([n compare:result] == NSOrderedAscending) {result = n;}
                                        }
                                        aggregateResult = result;
                                        
                                        break;
                                    }
                                    case MTAggregateFunctionTypeSum: {
                                        
                                        id sum = @(0);
                                        for (id object in dataForGroup) {
                                            id n = [self valueForGroupDetailData:object ofType:aggregateGroupType withKey:fieldKey andPage:index];

                                            sum = [self sumObject:sum andObject:n forType:aggregateType];
                                            
                                        }
                                        aggregateResult = sum;
                                        
                                        
                                        break;
                                    }
                                    default:
                                        
                                        break;
                                }
                                
                                [dataForGroup release];
                                
                                displayString = [MTDatabaseField formattedString:aggregateType
                                                                        forValue:aggregateResult];
                                break;
                            }
                            
                            case MTDocumentObjectTypeImage: {
                                drawingObject = [[[item isImage] image] retain];
                                displayString = @"";
                                break;
                            }
                            
                            case MTDocumentObjectTypeLabelDynamic: {
                                
                                RptqQueryField *queryField = [[item isLabelDataField] referencesQueryField];
                                NSString *tableFieldKey = [queryField tableFieldKey];
                                NSDictionary *rowData = [self rowDataForRow:detailRowToPrint onPage:index];
                                id value = [rowData objectForKey: tableFieldKey];
                                MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
                                displayString = [MTDatabaseField formattedString:dataType
                                                                        forValue:value];
                                break;
                            }
                            
                            case MTDocumentObjectTypeLabelStatic: {
                                displayString = [[item isLabel] text];
                                break;
                            }
                            
                            default: {
                                displayString = @"";
                                break;
                            }
                        }

                        //CGRect elementViewFrame = [item elementViewFrame]
                        
                        CGFloat originPointX        = [[item dropPointX] floatValue] + originX;
                        CGFloat originPointY        = [[item dropPointY] floatValue] + originY;
                        CGRect elementCanvasRect    = [item frameInSectionForDrawingWithOriginPoint:CGPointMake(originPointX, originPointY)];


                        if (drawingObject == nil) {
                            
                            NSMutableAttributedString *dObject = [[NSMutableAttributedString alloc] initWithString: displayString
                                                                                   attributes: [self attributesForDocumentObject:item]];
                            [dObject drawInRect:elementCanvasRect];
                            [dObject release];

                        } else {
                        
                            [drawingObject drawInRect:elementCanvasRect];
                        
                        }
                        
                        [drawingObject release];
                        drawingObject = nil;
                        
                    }
                }
            
            }

            originY += sizeHeight;
            
            [pageSectionId release];
            [reportSectionValues release];

        }
        [pageSectionsToPrint release];
    }
    [groupLevelKeys release];
}

- (NSDictionary *)attributesForDocumentObject:(RptqDocumentObject *)documentObject {
    NSString *fontname = [documentObject fontname];
    NSLog(@"%@", fontname);
    MTFont *font = [[MTFont alloc] initWithFamilyName:[documentObject fontname] andPointSize:[[documentObject fontsize] floatValue] isBold:[[documentObject bold] boolValue] isItalic:[[documentObject italic] boolValue]];
    UIFont *customFont = [font font];
    //    UIFont *customFont = [UIFont systemFontOfSize:[[documentObject fontsize] floatValue]];
    NSNumber *underline = [[documentObject underline] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    NSNumber *strikethough = [[documentObject strike] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
//    NSNumber *strokeWidth = [[documentObject bold] boolValue] ? @(3.0000f) : @(0.0000f);
    
    return @{NSFontAttributeName : customFont,
             NSUnderlineStyleAttributeName : underline,
             NSStrikethroughStyleAttributeName : strikethough};

}

- (id)sumObject:(id)obj1 andObject:(id)obj2 forType:(MTDataType)dataType {
    id result;
    switch (dataType) {
        case MTDataTypeBit:
            result = @([obj1 boolValue] + [obj2 boolValue]);
            break;
        case MTDataTypeFloat:
            result = @([obj1 floatValue] + [obj2 floatValue]);
            break;
        case MTDataTypeInteger:
            result = @([obj1 integerValue] + [obj2 integerValue]);
            break;
        case MTDataTypeNumber:
        case MTDataTypeDecimal:
        case MTDataTypeDouble:
            result = @([obj1 integerValue] + [obj2 doubleValue]);
            break;
        case MTDataTypeEnum:
        case MTDataTypeInt24:
            result = @([obj1 intValue] + [obj2 intValue]);
            break;
        case MTDataTypeLong:
            result = @([obj1 longValue] + [obj2 longValue]);
            break;
        case MTDataTypeLongLong:
            result = @([obj1 longLongValue] + [obj2 longLongValue]);
            break;
        case MTDataTypeShort:
            result = @([obj1 shortValue] + [obj2 shortValue]);
            break;
        case MTDataTypeBlob:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeString:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
        case MTDataTypeVarChar:
        default: {
            if ([obj1 isKindOfClass:[NSString class]] == NO) {
                obj1 = @"";
            }
            if ([obj2 isKindOfClass:[NSString class]]) {
                result = [obj1 stringByAppendingString:obj2];
            } else {
                obj1 = [NSString stringWithFormat:@"%@", obj1];
                [obj1 appendFormat:@"%@", obj2];
                result = obj1;
            }
            break;
        }
    }
    return result;
}

- (id)divideObject:(id)obj1 andObject:(id)obj2 forType:(MTDataType)dataType {
    id result;
    switch (dataType) {
        case MTDataTypeBit:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 boolValue] / [obj2 boolValue]);
            break;
        case MTDataTypeFloat:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 floatValue] / [obj2 floatValue]);
            break;
        case MTDataTypeInteger:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 integerValue] / [obj2 integerValue]);
            break;
        case MTDataTypeNumber:
        case MTDataTypeDecimal:
        case MTDataTypeDouble:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 integerValue] / [obj2 doubleValue]);
            break;
        case MTDataTypeEnum:
        case MTDataTypeInt24:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 intValue] / [obj2 intValue]);
            break;
        case MTDataTypeLong:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 longValue] / [obj2 longValue]);
            break;
        case MTDataTypeLongLong:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 longLongValue] / [obj2 longLongValue]);
            break;
        case MTDataTypeShort:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 shortValue] / [obj2 shortValue]);
            break;
        case MTDataTypeBlob:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeString:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
        case MTDataTypeVarChar:
        default: {
            if ([obj1 isKindOfClass:[NSString class]] == NO) {
                obj1 = @"";
            }
            if ([obj2 isKindOfClass:[NSString class]]) {
                [obj1 removeCharactersInString:obj2];
                result = obj1;
            } else {
                obj1 = [NSString stringWithFormat:@"%@", obj1];
                [obj1 appendFormat:@"%@", obj2];
                result = obj1;
            }
            break;
        }
    }
    return result;
}

- (NSInteger)numberOfPages {
    if ([self cachedLayoutByPage] == nil) {
        [self cachePrintPageRenderDataForSize:[self printableRect].size];
    }
    return [[self cachedLayoutByPage] count];
}

- (void)drawHeaderForPageAtIndex:(NSInteger)index inRect:(CGRect)headerRect {
    [super drawHeaderForPageAtIndex:index inRect:headerRect];
}

- (void)drawContentForPageAtIndex:(NSInteger)index inRect:(CGRect)contentRect {
    [super drawContentForPageAtIndex:index inRect:contentRect];
}

- (void)drawFooterForPageAtIndex:(NSInteger)index inRect:(CGRect)footerRect {
    [super drawFooterForPageAtIndex:index inRect:footerRect];
}

- (id)valueForGroupDetailData:(id)object ofType:(MTAggregateGroupByType)groupType withKey:(NSString *)fieldKey andPage:(NSUInteger)page {
    id value;
    if (groupType == MTAggregateGroupByTypePage) {
        NSUInteger row = [object integerValue];
        NSDictionary *rd = [self rowDataForRow:row onPage:index];
        value = [rd objectForKey: fieldKey];
        
    } else if (groupType == MTAggregateGroupByTypeReport) {
        
        value = [object objectForKey: fieldKey];
    } else if (groupType == MTAggregateGroupByTypeSection) {
        value = [object objectForKey: fieldKey];
    } else {
        value = [object objectForKey: fieldKey];
    }
    return value;
}

#pragma mark - Object methods

- (NSDictionary *)rowDataForRow:(NSUInteger)row onPage:(NSUInteger)page {
    id rowData = nil;
    if (page < [[self cachedDataByPage] count]) {
        NSArray *pageData = [[self cachedDataByPage] objectAtIndex:page];
        if (row < [pageData count]) {
            NSUInteger cachedDataIndex = [[pageData objectAtIndex:row] integerValue];
            rowData = [[self cachedDataByReport] objectAtIndex:cachedDataIndex];
        }
    }
    return rowData;
}

- (NSString *)printDynamicDocumentLabel:(RptqDocumentObjectLabelDataField *)documentObjectDataField forRow:(NSUInteger)row onPage:(NSUInteger)page {
    NSString *result = @"";
    RptqQueryField *queryField = [documentObjectDataField referencesQueryField];
    NSString * tableFieldKey = [queryField tableFieldKey];
    NSDictionary *rowData = [self rowDataForRow:row onPage:page];
    id value = [rowData objectForKey: tableFieldKey];
    MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
    result = [[[MTDatabaseField formattedString:dataType
                                       forValue:value] retain] autorelease];
    return result;
}

- (id)dataForCachedGroupData:(id)data andKeys:(NSArray *)keys {
    id resultData = nil;
    if ([data isKindOfClass:[NSArray class]]) {
        resultData = [data retain];
    } else {
        id subData = [[data objectForKey:[keys objectAtIndex:0]] retain];
        NSArray *subKeys = nil;
        if ([keys count] > 1) {
            NSRange range = NSMakeRange(1, [keys count] - 1);
            subKeys = [[[keys objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] retain] autorelease];
            resultData = [[self dataForCachedGroupData:subData andKeys:subKeys] retain];
        } else if ([keys count] == 1) {
            resultData = [subData retain];
        } else {
            resultData = [subData retain];
        }
        [subData release];
    }
    return [resultData autorelease];
}

- (void)prepareForDrawingPages:(NSRange)range {
    [self cachePrintPageRenderDataForSize:[self printableRect].size];
}

#pragma mark - Routines to cache the data

//  Data is cached by group, page, and report.

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize {

    if (CGSizeEqualToSize([self cachedPageSize], printableSize) == NO) {
        [self setCachedPageSize:printableSize];
        [self setCachedPageRect:[self printableRect]];
        [self setPrintableSize:printableSize];
        
        [self setTemporaryCachedDetailCounter:0];

        RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        RptqQueryCache *queryCache = [query hasQueryCache];
        
        SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[query managedObjectContext]];
        for (RptqDocumentSection *sec in enumerator) {
            CGFloat layoutHight = [RptqDocumentSection layoutHeightForSection:sec];
            [sec setLayoutHeight:@(layoutHight)];
            [[sec managedObjectContext] save:nil];
        }
        
        NSMutableDictionary *cachedResultsForReport = [[NSMutableDictionary alloc] init];
        
        [[self temporaryLayoutByPage] removeAllObjects];
        [self setPrintableSpaceUsedPageHeight:CGSizeZero.height];
        
        for (RptqQueryResultFields *queryResultField in [queryCache hasQueryResultFields]) {
            for (RptqQueryResultValues *queryResultValue in [queryResultField hasValues]) {
        
                id results = [cachedResultsForReport objectForKey:[queryResultValue rowId]];
                
                NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] initWithDictionary:results];
                
                id queryResultCValue = [[queryResultValue cachedValue] retain];
                
                id obj1 = queryResultCValue == nil ? @"" : queryResultCValue;
                [resultDictionary setObject: obj1
                                     forKey: [queryResultField fieldname]];
                
                [cachedResultsForReport setObject: resultDictionary
                                           forKey: [queryResultValue rowId]];

                [queryResultCValue release];
                [resultDictionary release];
            }
        }
        
        NSSet *resultsByRowSet = [NSSet setWithArray:[cachedResultsForReport allValues]];
        NSSet *hasQueryGroups = [query hasQueryGroups];
        
        NSString *sortKey = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: sortKey
                                                                       ascending: YES];
        NSArray *sortedHasQueryGroups = [hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
        
        for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
            
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: [queryGroup fieldNameQuery]
                                                                           ascending: sortAscending];
            [sortedSortDescriptorsGroup addObject:sortDescriptor];
            [sortDescriptor release];
        }
        
        [self setCachedSortedSortDescriptorsGroup:[sortedSortDescriptorsGroup copy]];
        [sortedSortDescriptorsGroup release];

        NSArray *sortedResultsByRow = [resultsByRowSet sortedArrayUsingDescriptors:[self cachedSortedSortDescriptorsGroup]];
        sortedResultsByRow = [sortedResultsByRow retain];
        
        [self setCachedDataByReport:[sortedResultsByRow copy]];
        
        id groupedRows = [[self cachedGroupedResults:sortedResultsByRow
                                         level:0] retain];
        
        [self setPrintableSpaceUsedPageHeight: CGSizeZero.height];
        
        CGFloat printableSpaceUsed = [self printableSpaceUsedPageHeight] + [[[[self document] hasPageHeaderSection] layoutHeight] floatValue];
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cachePageHeaderWithValueDictionary:groupedRows];

        printableSpaceUsed = [self printableSpaceUsedPageHeight] + [[[[self document] hasReportHeaderSection] layoutHeight] floatValue];
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cacheReportHeaderWithValueDictionary:groupedRows];
        
        BOOL detailPrinted = NO;
        [self cacheGroupLevel:[query firstQueryGroup]
                  groupedRows:groupedRows
             groupedRowsLevel:0
                detailPrinted:&detailPrinted];
        
        CGFloat reportFooterHeight = [[[[self document] hasReportFooterSection] layoutHeight] floatValue];
        
        [self cachePageBreakWithNextItemHeight: reportFooterHeight
                                   groupedRows: groupedRows];
        
        printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportFooterHeight;
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cacheReportFooterWithValueDictionary:groupedRows];
        
        CGFloat pageFooterHeight = [[[[self document] hasPageFooterSection] layoutHeight] floatValue];
        
        printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageFooterHeight;
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cachePageFooterWithValueDictionary:groupedRows];
        
        [[self temporaryLayoutByPage] addObject:[[self temporaryLayoutForPage] copy]];
        [[self temporaryDataByPage] addObject:[[self temporaryDataForPage] copy]];
        
        [self setCachedDataByGroup:[groupedRows copy]];
        [self setCachedLayoutByPage:[[self temporaryLayoutByPage] copy]];
        [self setCachedDataByPage:[[self temporaryDataByPage] copy]];
        
        [cachedResultsForReport release];
        [groupedRows release];
        [sortedResultsByRow release];
        [sortDescriptor release];

    }
}

- (void)cacheGroupLevel:(RptqQueryGroup *)queryGroup
            groupedRows:(NSDictionary *)groupedRows
       groupedRowsLevel:(NSUInteger)groupedRowsLevel
          detailPrinted:(BOOL *)detailPrinted {
    
        if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
            
            SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
            
            NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys]];
            NSSortDescriptor *desc = [[[self cachedSortedSortDescriptorsGroup] objectAtIndex:groupedRowsLevel] retain];
            NSArray *allKeysSorted = [[allKeys sortedArrayUsingSelector:sortSelector] retain];
            NSEnumerator *loopEnumerator;

            if ([desc ascending] == NO) {
                loopEnumerator = [[allKeysSorted reverseObjectEnumerator] retain];
            } else {
                loopEnumerator = [[allKeysSorted objectEnumerator] retain];
            }

            [desc release];
            for (id key in loopEnumerator) {
                id obj = [[groupedRows objectForKey:key] retain];
                
                //Group header section
                for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                    if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                        [self cachePageBreakWithNextItemHeight: [[documentSection layoutHeight] floatValue]
                                                   groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection layoutHeight] floatValue];
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }

                [self cacheGroupHeaderWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                RptqQueryGroup *nextGroup = [queryGroup next];
                
                
                if (nextGroup != nil) {
                    [self cacheGroupLevel: nextGroup
                              groupedRows: obj
                         groupedRowsLevel: groupedRowsLevel
                            detailPrinted: detailPrinted];
                } else {
                    [self cacheDetailLevelWithDetails:obj
                                          groupedRows:groupedRows];
                }
                
                //Group footer section
                for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                    if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                        [self cachePageBreakWithNextItemHeight: [[documentSection layoutHeight] floatValue]
                                                   groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection layoutHeight] floatValue];
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }

                [self cacheGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                [obj release];
            }
            [loopEnumerator release];
            [allKeysSorted release];
            [allKeys release];

        } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...

            [self cacheDetailLevelWithDetails:(NSArray *)groupedRows
                                  groupedRows:groupedRows];
        }
}

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails
                        groupedRows:(NSDictionary *)groupedRows {

    RptqDocumentSection *detailSection = [[self document] hasDetailSection];
    for (NSDictionary *resultDictionary in containerDetails) {
        
        [self cachePageBreakWithNextItemHeight: [[detailSection layoutHeight] floatValue]
                                   groupedRows: groupedRows];
        [self cacheDetailWithValueDictionary:resultDictionary];
        CGFloat printableHeightUsed = ([self printableSpaceUsedPageHeight] + [[detailSection layoutHeight] floatValue]);
        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
    }

}

//Roll through the groups
//Returns dictionary for group levels (level < n), and array of dictionaries for details/results (level == n-1).
- (id)cachedGroupedResults:(NSArray *)sortedResults level:(NSUInteger)level {
    
    BOOL detailLevel = level == [[self cachedSortedSortDescriptorsGroup] count];
    id resultsDictionary = nil;
    
    if (detailLevel) {
        resultsDictionary = [sortedResults copy];
    } else {
        resultsDictionary = [[NSMutableDictionary alloc] init];
        NSMutableArray *resultsForGroup = [[NSMutableArray alloc] init];
        
        NSSortDescriptor *sortDescriptor = detailLevel ? nil : [[self cachedSortedSortDescriptorsGroup] objectAtIndex:level];
        
        NSString *sortFieldName =  detailLevel ? nil : [sortDescriptor key];

        id valueForField = nil, lastValueForField = nil;
        
        NSUInteger groupResultIndexForLevel = 0;
        
        for (NSDictionary *result in sortedResults) {
            valueForField = detailLevel ? nil : [result objectForKey:sortFieldName];
            
            if (![valueForField isEqual: lastValueForField] && lastValueForField != nil) {

                id resultOfNextGroup = [self cachedGroupedResults: resultsForGroup
                                                      level: (level + 1)];
                
                [resultsDictionary setObject:resultOfNextGroup forKey:lastValueForField];
                //[resultsDictionary setObject:resultOfNextGroup forKey:@(groupResultIndexForLevel)];
                
                
                [resultsForGroup removeAllObjects];
                
            }
            [resultsForGroup addObject:result];
            lastValueForField = valueForField;
            groupResultIndexForLevel++;
        }

        NSArray *resultsCopy = [[NSArray alloc] initWithArray: resultsForGroup];                //Last item
        if (valueForField != nil) {
            id resultOfNextGroup = [self cachedGroupedResults: resultsForGroup
                                                  level: (level + 1)];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            [resultsDictionary setObject:resultOfNextGroup forKey:key];
        }
        
        [resultsCopy release];
        
        [resultsForGroup removeAllObjects];
        [resultsForGroup release];
    }
    return [resultsDictionary autorelease];
}

- (BOOL)cachePageBreakWithNextItemHeight:(CGFloat)nextItemHeight
                             groupedRows:(NSDictionary *)groupedRows {

    BOOL newPageCreated = NO;
    CGRect pageRect;
    CGFloat pageFooterSectionHeight = [[[[self document] hasPageFooterSection] layoutHeight] floatValue];
    
    if (CGRectIsEmpty([self printableRect])) {
        pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    } else {
        pageRect = [self paperRect];
    }
    
    if ([self printableSpaceUsedPageHeight] + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        newPageCreated = YES;
        CGFloat newHeight = [self printableSpaceUsedPageHeight] + pageFooterSectionHeight;
        [self setPrintableSpaceUsedPageHeight:newHeight];
        [self cachePageFooterWithValueDictionary:groupedRows];
        
        [[self temporaryLayoutByPage] addObject:[[self temporaryLayoutForPage] copy]];
        [[self temporaryDataByPage] addObject:[[self temporaryDataForPage] copy]];
        
        [self setPrintableSpaceUsedPageHeight: (CGPointZero.y + [[[[self document] hasPageHeaderSection] layoutHeight] floatValue])];

        [self cachePageHeaderWithValueDictionary:groupedRows];
        
    }
    return newPageCreated;
}

- (void)cachePageHeaderWithValueDictionary:(NSDictionary *)values {
    [[self temporaryLayoutForPage] removeAllObjects];
    [[self temporaryDataForPage] removeAllObjects];
    
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageHeader forKey:MTReportSectionType];
    if (newValue != nil) {
        [sectionData setObject:newValue forKey:MTReportSectionValues];
    }
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cachePageFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheReportHeaderWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheReportFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheGroupHeaderWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheGroupFooterWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheDetailWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageDetail forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [[self temporaryDataForPage] addObject:@([self temporaryCachedDetailCounter])];
    self.temporaryCachedDetailCounter++;
    [sectionData release];
    [newValue release];
}

@end