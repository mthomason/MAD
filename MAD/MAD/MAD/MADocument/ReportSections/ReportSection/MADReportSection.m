//
//  MADReportSection.m
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSection.h"
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import "RptqDocumentSection+Extras.h"
#import "RptqDocument+CoreDataClass.h"
#import "RptqDocumentSection+CoreDataProperties.h"

#import "MADReportSectionReportHeader.h"
#import "MADReportSectionPageHeader.h"
#import "MADReportSectionGroupHeader.h"
#import "MADReportSectionDetail.h"
#import "MADReportSectionGroupFooter.h"
#import "MADReportSectionPageFooter.h"
#import "MADReportSectionReportFooter.h"

#import "MADSectionLayoutManager.h"

@interface MADReportSection ()

    @property (nonatomic, readwrite, strong)                            MADSectionLayoutManager *layoutManager;

    @property (nonatomic, readwrite, strong)                            NSManagedObjectID *objectID;
    @property (nonatomic, readwrite, assign)                            NSManagedObjectContext *managedObjectContext;

    @property (nonatomic, readwrite, strong, getter=hasReportRows)      MADReportRows *reportRows;
    @property (nonatomic, readwrite, strong)                            RptqDocumentSection *documentSection;

@end

@implementation MADReportSection

- (instancetype)initWithReportSection:(RptqDocumentSection *)reportSection {

    MADReportSection *instance;
    switch (reportSection.type.shortValue) {
        case MADDocumentSectionTypeReportHeader:
            instance = [[MADReportSectionReportHeader alloc] init];
            break;
            
        case MADDocumentSectionTypePageHeader:
            instance = [[MADReportSectionPageHeader alloc] init];
            break;
            
        case MADDocumentSectionTypeGroupHeader:
            instance = [[MADReportSectionGroupHeader alloc] init];
            break;

        case MADDocumentSectionTypeBody:
            instance = [[MADReportSectionDetail alloc] init];
            break;

        case MADDocumentSectionTypeGroupFooter:
            instance = [[MADReportSectionGroupFooter alloc] init];
            break;

        case MADDocumentSectionTypePageFooter:
            instance = [[MADReportSectionPageFooter alloc] init];
            break;
            
        case MADDocumentSectionTypeReportFooter:
            instance = [[MADReportSectionReportFooter alloc] init];
            break;
            
        default:
            break;
    }

    if (instance) {
        instance.objectID = reportSection.objectID.copy;
        instance.managedObjectContext = reportSection.managedObjectContext;
        instance.documentSection = reportSection;
    }
    
    return instance;
}

- (MADSectionLayoutManager *)layoutManager {
    if (_layoutManager == nil) {
        MADSectionLayoutManager *layoutManager;
        layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:self.documentSection];
        _layoutManager = layoutManager;
    }
    return _layoutManager;
}

- (RptqDocumentSection *)documentSection {
    if (_documentSection == nil) {
        _documentSection = [_managedObjectContext objectWithID: _objectID];
    }
    return _documentSection;
}

- (MADDocumentSectionType)type {
    return self.documentSection.type.shortValue;
}

- (CGFloat)height {
    return self.documentSection.height.floatValue;
}

- (BOOL)isVisible {
    return self.documentSection.visibility.boolValue;
}

- (NSInteger)identifier {
    return self.documentSection.identifier;
}

@end
