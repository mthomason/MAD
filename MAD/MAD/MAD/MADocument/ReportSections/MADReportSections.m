//
//  MADReportSections.m
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSections.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

#import "RptqDocument+Extras.h"
#import "RptqDocumentSectionEnumerator.h"
#import "RptqQuery+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup.h"

#import "MADReportSectionEnumerator.h"
#import "MADReportSection.h"

#ifdef DEBUG
  #import <Foundation/NSString.h>
#endif

@interface MADReportSections () {
  @private
    NSUInteger _numberOfGroups;
    
    MADReportSection *_reportHeader;
    MADReportSection *_pageHeader;
    NSMutableArray <MADReportSection *> *_groupHeaders;
    MADReportSection *_detail;
    NSMutableArray <MADReportSection *> *_groupFooters;
    MADReportSection *_pageFooter;
    MADReportSection *_reportFooter;
}

    @property (nonatomic, readwrite, strong)    NSArray <MADReportSection *> *reportSections;
    @property (nonatomic, readwrite, strong)    RptqDocument *document;
    @property (nonatomic, readwrite, strong)    RptqQuery *mainQuery;

    @property (nonatomic, readwrite, strong)    MADReportSectionEnumerator *sectionEnumerator;


@end

@implementation MADReportSections

- (void)dealloc {
    NSString *path = NSStringFromSelector(@selector(hasQueryGroups));
    [_document.mainQuery removeObserver: self
                             forKeyPath: path];
}

- (instancetype)init {
    return [self initWithDocument:nil];
}

- (instancetype)initWithDocument:(RptqDocument *)document {
    if (self = [super init]) {

        NSString *path = NSStringFromSelector(@selector(hasQueryGroups));

        [document.mainQuery addObserver: self
                             forKeyPath: path
                                options: NSKeyValueObservingOptionNew
                                context: NULL];
        
        _numberOfGroups = document.mainQuery.hasQueryGroups.count;
        _document = document;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    NSString *pathToObserve = NSStringFromSelector(@selector(hasQueryGroups));
    if ([keyPath isEqualToString: pathToObserve]) {
    
        //reset the group count and read remove the group objects so they will be read again
        //  next time around.
        _numberOfGroups = ((RptqQuery *)object).hasQueryGroups.count;
        
        [_groupHeaders removeAllObjects];
        _groupHeaders = nil;

        [_groupFooters removeAllObjects];
        _groupFooters = nil;
        
    }
    
}


- (MADReportSection *)sectionAtIndex:(NSUInteger)index
                      numberOfGroups:(NSUInteger)numberOfGroups {

    switch (documentSectionType(index, numberOfGroups)) {
        case MADDocumentSectionTypeReportHeader:
            return self.reportHeader;
            break;
            
        case MADDocumentSectionTypePageHeader:
            return self.pageHeader;
            break;
            
        case MADDocumentSectionTypeBody:
            return self.detail;
            break;
            
        case MADDocumentSectionTypePageFooter:
            return self.pageFooter;
            break;
            
        case MADDocumentSectionTypeReportFooter:
            return self.reportFooter;
            break;
            
        case MADDocumentSectionTypeGroupHeader:
            return self.groupHeaders[queryGroupIndexForSelectedIndexOfTypeHeader(index)];
            break;
            
        case MADDocumentSectionTypeGroupFooter:
            return self.groupFooters[queryGroupIndexForSelectedIndexOfTypeFooter(index, numberOfGroups)];
            break;
            
        default:
            return nil;
            break;
    }
}

- (MADReportSection *)reportHeader {
    if (_reportHeader == nil) {
        id section;
        section = [[MADReportSection alloc] initWithReportSection:_document.hasReportHeaderSection];
        _reportHeader = section;
    }
    return _reportHeader;
}

- (MADReportSection *)pageHeader {
    if (_pageHeader == nil) {
        id section;
        section = [[MADReportSection alloc] initWithReportSection:_document.hasPageHeaderSection];
        _pageHeader = section;
    }
    return _pageHeader;
}

- (NSArray <MADReportSection *> *)groupHeaders {
    if (_groupHeaders == nil) {
        NSMutableArray <MADReportSection *> *headers = [[NSMutableArray alloc] init];
        RptqQuery *mainQuery = self.mainQuery;
        NSArray <RptqQueryGroup *> *sortedQueryGroups = [mainQuery sortedQueryGroups];
        RptqDocumentSection *header;
        id reportSection;
        for (RptqQueryGroup *queryGroup in sortedQueryGroups) {
            header = [mainQuery headerSectionInSections:queryGroup.hasSection];
            reportSection = [[MADReportSection alloc] initWithReportSection:header];
            [headers addObject:reportSection];
        }
        _groupHeaders = headers;
    }
    return _groupHeaders;
}

- (MADReportSection *)detail {
    if (_detail == nil) {
        id section;
        section = [[MADReportSection alloc] initWithReportSection:_document.hasDetailSection];
        _detail = section;
    }
    return _detail;
}

- (NSArray <MADReportSection *> *)groupFooters {
    if (_groupFooters == nil) {
        NSMutableArray <MADReportSection *> *footers = [[NSMutableArray alloc] init];
        RptqQuery *mainQuery = self.mainQuery;
        NSArray <RptqQueryGroup *> *sortedQueryGroups = [self.mainQuery sortedQueryGroups];
        RptqDocumentSection *footer;
        id reportSection;
        for (RptqQueryGroup *queryGroup in sortedQueryGroups) {
            footer = [mainQuery footerSectionInSections:queryGroup.hasSection];
            reportSection = [[MADReportSection alloc] initWithReportSection:footer];
            [footers addObject:reportSection];
        }
        _groupFooters = footers;
    }
    return _groupFooters;
}

- (MADReportSection *)reportFooter {
    if (_reportFooter == nil) {
        id section;
        section = [[MADReportSection alloc] initWithReportSection:_document.hasReportFooterSection];
        _reportFooter = section;
    }
    return _reportFooter;
}

- (MADReportSection *)pageFooter {
    if (_pageFooter == nil) {
        id section;
        section = [[MADReportSection alloc] initWithReportSection:_document.hasPageFooterSection];
        _pageFooter = section;
    }
    return _pageFooter;
}

- (RptqQuery *)mainQuery {
    return _mainQuery ?: (_mainQuery = [_document mainQuery]);
}

- (MADReportSectionEnumerator *)sectionEnumerator {
    if (_sectionEnumerator == nil) {
        id query = self.mainQuery;
        id sectionEnumerator = [[MADReportSectionEnumerator alloc] initWithQuery:query];
        _sectionEnumerator = sectionEnumerator;
    }
    return _sectionEnumerator;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)stackbufLength {
    NSUInteger count = 0;
    
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    if(countOfItemsAlreadyEnumerated == 0) {
        RptqQuery *query = self.mainQuery;
        state->mutationsPtr = &state->extra[MADIndexMutationPointer];
        state->extra[MADIndexSectionCount] = query ? [query sectionCount] : 0;
        state->extra[MADIndexGroupCounter] = 0;
        state->extra[MADIndexGroupCount]   = query ?  query.hasQueryGroups.count : 0;
    }
    
    if(countOfItemsAlreadyEnumerated < state->extra[MADIndexSectionCount]) {
        state->itemsPtr = stackbuf;
        while((countOfItemsAlreadyEnumerated < state->extra[MADIndexSectionCount]) && (count < stackbufLength)) {
            stackbuf[count] = [self sectionAtIndex:countOfItemsAlreadyEnumerated numberOfGroups:state->extra[MADIndexGroupCount]];
            countOfItemsAlreadyEnumerated++;
            count++;
        }
    } else {
        count = 0;
    }
    state->state = countOfItemsAlreadyEnumerated;
    return count;
}

- (NSArray <MADReportSection *> *)reportSections {
    if (!_reportSections) {
        MADReportSectionEnumerator *sectionEnumerator;
        id query = self.mainQuery;
        sectionEnumerator = [[MADReportSectionEnumerator alloc] initWithQuery:query];
        NSMutableArray  <MADReportSection *> *reportSections;
        reportSections = [[NSMutableArray alloc] initWithCapacity:[query sectionCount]];
        for (MADReportSection *section in sectionEnumerator) {
            [reportSections addObject:section];
        }
        _reportSections = reportSections;
    }
    return _reportSections;
}

- (NSUInteger)count {
    return [self.mainQuery sectionCount];
}

- (RptqDocumentSection *)documentSectionForSelectedIndex:(NSUInteger)selectedIndex
                                      withNumberOfGroups:(NSUInteger)numberOfGroups {
    
    RptqDocumentSection *resultSection = nil;
    
    if (validateSelectedIndexWithGroupCount(selectedIndex, numberOfGroups)) {
        
        switch ([RptqDocumentSection getSectionTypeforRow: selectedIndex
                                       withNumberOfGroups: numberOfGroups]) {
                
            case MADDocumentSectionTypeReportHeader:
                resultSection = self.document.hasReportHeaderSection;
                break;
                
            case MADDocumentSectionTypePageHeader:
                resultSection = self.document.hasPageHeaderSection;
                break;
                
            case MADDocumentSectionTypeBody:
                resultSection = self.document.hasDetailSection;
                break;
                
            case MADDocumentSectionTypePageFooter:
                resultSection = self.document.hasPageFooterSection;
                break;
                
            case MADDocumentSectionTypeReportFooter:
                resultSection = self.document.hasReportFooterSection;
                break;
                
            case MADDocumentSectionTypeGroupHeader: {
                RptqQueryGroup *group = [self.mainQuery queryGroupForIndex: queryGroupIndexForSelectedIndexOfTypeHeader(selectedIndex)];
                resultSection = [self headerSectionInSections:group.hasSection];
                break;
            }
                
            case MADDocumentSectionTypeGroupFooter: {
                RptqQueryGroup *group = [self.mainQuery queryGroupForIndex: queryGroupIndexForSelectedIndexOfTypeFooter(selectedIndex, numberOfGroups)];
                resultSection = [self footerSectionInSections:group.hasSection];
                break;
            }
                
            default:
                break;
        }
        
    }
    return resultSection;
}

- (RptqDocumentSection *)footerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
    for (RptqDocumentSection *section in sections) {
        if (section.type.integerValue == MADDocumentSectionTypeGroupFooter) {
            return section;
            break;
        }
    }
    return nil;
}

- (RptqDocumentSection *)headerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
    for (RptqDocumentSection *section in sections) {
        if (section.type.integerValue == MADDocumentSectionTypeGroupHeader) {
            return section;
            break;
        }
    }
    return nil;
}

#pragma mark -
#pragma mark Debugging

#ifdef DEBUG

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendString:@"-------------------------------\n"];
    [debug appendFormat:@"Section Count: \t%d\n", [self count]];
    [debug appendFormat:@"Report Header: \t%@\n", [self reportHeader]];
    [debug appendFormat:@"Page Header:   \t%@\n", [self pageHeader]];
    [debug appendFormat:@"Group Header:  \t%@\n", [self groupHeaders]];
    [debug appendFormat:@"Detail:        \t%@\n", [self detail]];
    [debug appendFormat:@"Group Footer:  \t%@\n", [self groupFooters]];
    [debug appendFormat:@"Page Footer:   \t%@\n", [self pageFooter]];
    [debug appendFormat:@"Report Footer: \t%@\n", [self reportFooter]];
    [debug appendString:@"-------------------------------\n"];
    return debug;
}

#endif

@end
