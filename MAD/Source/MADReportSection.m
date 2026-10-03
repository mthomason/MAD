//
//  MADReportSection.m
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSection.h"
#import <MAD/RptqStoreContext.h>

#import "RptqDocument.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup+Extras.h"

#import "MADSectionLayoutManager.h"

#import <Foundation/NSBundle.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>

@interface MADReportSection ()

@property (nonatomic, readwrite, strong) MADSectionLayoutManager *layoutManager;

@property (nonatomic, readwrite, strong) NSNumber *objectID;
@property (nonatomic, readwrite, assign) RptqStoreContext *managedObjectContext;

@property (nonatomic, readwrite, strong, getter=hasReportRows) MADReportRows *reportRows;
@property (nonatomic, readwrite, strong) RptqDocumentSection *documentSection;

@end

@interface MADReportSectionReportHeader : MADReportSection
@end

@interface MADReportSectionPageHeader : MADReportSection
@end

@interface MADReportSectionGroupHeader : MADReportSection
@end

@interface MADReportSectionDetail : MADReportSection
@end

@interface MADReportSectionGroupFooter : MADReportSection
@end

@interface MADReportSectionPageFooter : MADReportSection
@end

@interface MADReportSectionReportFooter : MADReportSection
@end

@implementation MADReportSection

- (instancetype)initWithReportSection:(RptqDocumentSection *)reportSection {
	
	MADReportSection *instance;
	switch (reportSection.type) {
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
		instance.objectID = @(reportSection.identifier);
		instance.managedObjectContext = reportSection.storeContext;
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
		_documentSection = [RptqDocumentSection newDocumentSectionWithIdentifier:self.identifier
															   fromObjectContext:_managedObjectContext];
	}
	return _documentSection;
}

- (MADDocumentSectionType)type { return self.documentSection.type; }
- (CGFloat)height { return self.documentSection.height; }
- (BOOL)isVisible { return self.documentSection.visibility; }
- (NSInteger)identifier { return self.documentSection.identifier; }

@end

@implementation MADReportSectionReportHeader
- (NSString *)localizedDisplayName { return NSLocalizedString(@"Report Header", @"Report Header"); }
@end

@implementation MADReportSectionPageHeader
- (NSString *)localizedDisplayName { return NSLocalizedString(@"Page Header", @"Page Header"); }
@end

@implementation MADReportSectionGroupHeader
- (NSString *)localizedDisplayName {
	id fieldName =  [self.documentSection.inGroup fieldNameQuery];
	return [NSString stringWithFormat:NSLocalizedString(@"Group Header (%@)", @"Group Header (%@)"), fieldName];
}
@end

@implementation MADReportSectionDetail
- (NSString *)localizedDisplayName { return NSLocalizedString(@"Report Detail", @"Report Detail"); }
@end

@implementation MADReportSectionGroupFooter
- (NSString *)localizedDisplayName {
	id fieldName =  [self.documentSection.inGroup fieldNameQuery];
	return [[NSString alloc] initWithFormat:NSLocalizedString(@"Group Footer - (%@)", @"Group Footer - (%@)"), fieldName];
}
@end

@implementation MADReportSectionPageFooter
- (NSString *)localizedDisplayName { return NSLocalizedString(@"Page Footer", @"Page Footer"); }
@end

@implementation MADReportSectionReportFooter
- (NSString *)localizedDisplayName { return NSLocalizedString(@"Report Footer", @"Report Footer"); }
@end
