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
#import <Foundation/NSString.h>

#import "RptqDocument.h"
#import "RptqDocumentSectionEnumerator.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"
#import "RptqDatabase.h"

#import "RptqDocumentSection+Extras.h"
#import "RptqDocument+Extras.h"
#import "RptqQuery+Extras.h"

#import "MADReportSectionEnumerator.h"
#import "MADReportSection.h"

#ifdef DEBUG
  #import <Foundation/NSString.h>
#endif

@interface MADReportSections ()

    @property (nonatomic, readwrite, strong)    RptqDocument *document;
    @property (nonatomic, readwrite, strong)    RptqQuery *mainQuery;
    @property (nonatomic, readwrite, strong)    MADReportSectionEnumerator *sectionEnumerator;

@end

@implementation MADReportSections {
    NSUInteger _numberOfGroups;
    MADReportSection *_reportHeader;
    MADReportSection *_pageHeader;
    NSMutableArray <MADReportSection *> *_groupHeaders;
    MADReportSection *_detail;
    NSMutableArray <MADReportSection *> *_groupFooters;
    MADReportSection *_pageFooter;
    MADReportSection *_reportFooter;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    NSString *path = NSStringFromSelector(@selector(hasQueryGroups));
    [_document.mainQuery removeObserver: self
                             forKeyPath: path];
}

#pragma mark -
#pragma mark Constructors

- (instancetype)init {
    return [self initWithDocument:nil];
}

- (instancetype)initWithDocument:(RptqDocument *)document {
    if (self = [super init]) {

        NSString *path = NSStringFromSelector(@selector(hasQueryGroups));

        RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
        RptqQuery *query =  database.hasQueries.anyObject;

        [query addObserver: self
                forKeyPath: path
                   options: NSKeyValueObservingOptionNew
                   context: NULL];
        
        _numberOfGroups = document.mainQuery.hasQueryGroups.count;
        _document = document;
    }
    return self;
}

#pragma mark -
#pragma mark KVO

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

#pragma mark -
#pragma mark Properties (Report Sections)

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
            header = [RptqDocumentSection headerSectionInSections:queryGroup.hasSection];
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
        NSArray <RptqQueryGroup *> *sortedQueryGroups = [self.mainQuery sortedQueryGroups];
        RptqDocumentSection *footer;
        id reportSection;
        for (RptqQueryGroup *queryGroup in sortedQueryGroups) {
            footer = [RptqDocumentSection footerSectionInSections:queryGroup.hasSection];
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

#pragma mark -
#pragma mark NSFastEnumerator

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

- (NSUInteger)count {
    return [self.mainQuery sectionCount];
}

#pragma mark -
#pragma mark Helper

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

#pragma mark -
#pragma mark Debugging

#ifdef DEBUG

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendString:@"-------------------------------\n"];
    [debug appendFormat:@"Section Count: \t%lu\n", (unsigned long)[self count]];
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
