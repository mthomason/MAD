//
//  NSObject+RptqDocument_Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDocument+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQuerySort.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqDatabaseCredentals+Extras.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementChart.h"
#import "RptqDocumentElementGroupKey.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementLabelLink.h"
#import "RptqDocumentElementAggregate+Extras.h"
#import "RptqDocumentElementBarcode+Extras.h"
#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_IPHONE
#import <UIKit/UIImage.h>
#elif defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/NSImage.h>
#endif
#import "RptqDocumentElementFormula+Extras.h"
#import "RptqDataHelper.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MADAPI/MADErrorContainer.h>

#import <Foundation/NSException.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>

static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeHeader(NSUInteger);
static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeFooter(NSUInteger, NSUInteger);

//static inline BOOL validateSelectedIndexWithGroupCount(NSUInteger, NSUInteger);
//static inline BOOL validateSelectedIndexWithGroupCount(NSUInteger selectedIndex, NSUInteger numberOfGroups) {
//	return selectedIndex < (numberOfGroups * 2) + 5;
//}

static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeHeader(NSUInteger selectedIndex) {
	return selectedIndex - 2;
}

static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeFooter(NSUInteger selectedIndex, NSUInteger numberOfGroups) {
	return ((2 + numberOfGroups) - (selectedIndex - (2 + numberOfGroups))) - 2;
}

@implementation RptqDocument (Extras)

#pragma mark - Static

+ (void)deleteExistingDocuments:(RptqStoreContext *)context {
	NSArray *documents = [context objectsForEntity:NSStringFromClass([RptqDocument class])];
	for (RptqDocument *document in documents) {
		[context deleteObject:document error:NULL];
	}
	if (documents.count > 0) {
		NSError *error = nil;
		if (![context save:&error]) {
			os_log_error(GetMadLog(), "Failed to save after document deletion: %{public}@", error);
		}
	}
}

+ (instancetype)newDocumentForManagedObjectContext:(RptqStoreContext *)context {
	NSAssert(context != nil, @"Context must not be nil");
	
	[self deleteExistingDocuments:context];
	
	NSString *rptqDocumentName = NSStringFromClass([RptqDocument class]);
	RptqDocument *document = (RptqDocument *)[context insertObjectForEntity:rptqDocumentName identifier:1];
	NSAssert(document != nil, @"Failed to create new document");

	RptqDocumentSection*(^createSection)(RptqStoreContext *, int64_t, NSString *) =
	^RptqDocumentSection*(RptqStoreContext *ctx, int64_t identifier, NSString *sectionClass) {
		RptqDocumentSection *section = (RptqDocumentSection *)[ctx insertObjectForEntity:sectionClass identifier:identifier];
		NSAssert(section != nil, @"Failed to create section");
		return section;
	};

	NSString *docSection = NSStringFromClass([RptqDocumentSection class]);
	NSString *rptqDocumentSectionRows = NSStringFromClass([RptqDocumentSectionRows class]);
	
	document.hasReportHeaderSection = createSection(context, 1, docSection);
	document.hasReportFooterSection = createSection(context, 2, docSection);
	document.hasPageHeaderSection = createSection(context, 3, docSection);
	document.hasPageFooterSection = createSection(context, 4, docSection);
	document.hasDetailSection = createSection(context, 5, docSection);

	RptqDocumentSectionRows *headerRow = (RptqDocumentSectionRows *)[context insertObjectForEntity:rptqDocumentSectionRows identifier:0];
	NSAssert(headerRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows1 = [[NSOrderedSet alloc] initWithObject: headerRow];
	document.hasReportHeaderSection.hasRows = hasRows1;
	headerRow.inSection = document.hasReportHeaderSection;

	RptqDocumentSectionRows *footerRow = (RptqDocumentSectionRows *)[context insertObjectForEntity:rptqDocumentSectionRows identifier:0];
	NSAssert(footerRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows2 = [[NSOrderedSet alloc] initWithObject: footerRow];
	document.hasReportFooterSection.hasRows = hasRows2;
	footerRow.inSection = document.hasReportFooterSection;

	RptqDocumentSectionRows *pageHeaderRow = (RptqDocumentSectionRows *)[context insertObjectForEntity:rptqDocumentSectionRows identifier:0];
	NSAssert(pageHeaderRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows3 = [[NSOrderedSet alloc] initWithObject: pageHeaderRow];
	document.hasPageHeaderSection.hasRows = hasRows3;
	pageHeaderRow.inSection = document.hasPageHeaderSection;

	RptqDocumentSectionRows *pageFooterRow = (RptqDocumentSectionRows *)[context insertObjectForEntity:rptqDocumentSectionRows identifier:0];
	NSAssert(pageFooterRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows4 = [[NSOrderedSet alloc] initWithObject: pageFooterRow];
	document.hasPageFooterSection.hasRows = hasRows4;
	pageFooterRow.inSection = document.hasPageFooterSection;

	RptqDocumentSectionRows *detailSectionRow = (RptqDocumentSectionRows *)[context insertObjectForEntity:rptqDocumentSectionRows identifier:0];
	NSAssert(detailSectionRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows5 = [[NSOrderedSet alloc] initWithObject: detailSectionRow];
	document.hasDetailSection.hasRows = hasRows5;
	detailSectionRow.inSection = document.hasDetailSection;

	document.hasReportHeaderSection.type = MADDocumentSectionTypeReportHeader;
	document.hasReportFooterSection.type = MADDocumentSectionTypeReportFooter;
	document.hasPageHeaderSection.type = MADDocumentSectionTypePageHeader;
	document.hasPageFooterSection.type = MADDocumentSectionTypePageFooter;
	document.hasDetailSection.type = MADDocumentSectionTypeBody;

	[document.hasReportHeaderSection    setInterfaceHeight: 44.0];
	[document.hasReportFooterSection    setInterfaceHeight: 44.0];
	[document.hasPageHeaderSection      setInterfaceHeight: 44.0];
	[document.hasPageFooterSection      setInterfaceHeight: 44.0];
	[document.hasDetailSection          setInterfaceHeight: 88.0];

	document.hasReportHeaderSection.visibility = YES;
	document.hasReportFooterSection.visibility = YES;
	document.hasPageHeaderSection.visibility = YES;
	document.hasPageFooterSection.visibility = YES;
	document.hasDetailSection.visibility = YES;

	return document;
}

+ (instancetype)newDocumentReadFromManagedObjectContext:(RptqStoreContext *)objectContext {
	NSAssert(objectContext != nil, @"Context must not be nil");

	NSArray *documents = [objectContext objectsForEntity:NSStringFromClass([RptqDocument class])];
	NSAssert(documents.count > 0, @"No documents found");
	return documents.lastObject;
}

#pragma mark - Overrides

- (void)willChangeValueForKey:(NSString *)inKey
			  withSetMutation:(NSKeyValueSetMutationKind)inMutationKind
				 usingObjects:(NSSet *)inObjects {
	[super willChangeValueForKey: inKey
				 withSetMutation: inMutationKind
					usingObjects: inObjects];
}

- (RptqQuery *)mainQuery {
	// A composed document's root shares the first source's database (a placeholder
	// so ordinary accessors still resolve), so a bare anyObject over hasQueries can
	// hand back the root instead of the report's own source query.  Exclude the root
	// so `mainQuery` keeps meaning "the report's query" -- the same value an ordinary
	// document's single query has -- instead of being ambiguous once a root exists.
	RptqQuery *root = self.rootQuery;
	for (RptqDatabase *database in self.hasDatabaseSchemas) {
		for (RptqQuery *query in database.hasQueries) {
			if (query != root) return query;
		}
	}
	return self.hasDatabaseSchemas.anyObject.hasQueries.anyObject;
}

- (RptqDatabase *)defaultDatabase {
	return self.hasDatabaseSchemas.anyObject;
}

- (MTPaperType)paperType {
	return self.papersize;
}

- (RptqDocumentSection *)documentSectionForSelectedIndex:(NSUInteger)selectedIndex
									  withNumberOfGroups:(NSUInteger)numberOfGroups {
	
	RptqDocumentSection *resultSection = nil;
	
	switch ([RptqDocumentSection getSectionTypeforRow: selectedIndex
								   withNumberOfGroups: numberOfGroups]) {
			
		case MADDocumentSectionTypeReportHeader:
			resultSection = self.hasReportHeaderSection;
			break;
			
		case MADDocumentSectionTypePageHeader:
			resultSection = self.hasPageHeaderSection;
			break;
			
		case MADDocumentSectionTypeBody:
			resultSection = self.hasDetailSection;
			break;
			
		case MADDocumentSectionTypePageFooter:
			resultSection = self.hasPageFooterSection;
			break;
			
		case MADDocumentSectionTypeReportFooter:
			resultSection = self.hasReportFooterSection;
			break;
			
		case MADDocumentSectionTypeGroupHeader: {
			RptqDatabase *database = self.hasDatabaseSchemas.anyObject;
			RptqQuery *query = database.hasQueries.anyObject;
			RptqQueryGroup *group = [query queryGroupForIndex:
									 queryGroupIndexForSelectedIndexOfTypeHeader(selectedIndex)];
			resultSection = [RptqDocumentSection headerSectionInSections:group.hasSection];
			break;
		}
			
		case MADDocumentSectionTypeGroupFooter: {
			RptqDatabase *database = self.hasDatabaseSchemas.anyObject;
			RptqQuery *query = database.hasQueries.anyObject;
			RptqQueryGroup *group = [query queryGroupForIndex:
									 queryGroupIndexForSelectedIndexOfTypeFooter(selectedIndex,
																				 numberOfGroups)];
			resultSection = [RptqDocumentSection footerSectionInSections:group.hasSection];
			break;
		}
			
		default:
			break;
	}
	
	return resultSection;
}

- (RptqDocumentSection *)documentSectionForType:(MADDocumentSectionType)type
									   andLevel:(NSUInteger)level {
	
	switch (type) {
			
		case MADDocumentSectionTypeBody:
			return self.hasDetailSection;
			break;
			
		case MADDocumentSectionTypePageHeader:
			return self.hasPageHeaderSection;
			break;
			
		case MADDocumentSectionTypePageFooter:
			return self.hasPageFooterSection;
			break;
			
		case MADDocumentSectionTypeReportHeader:
			return self.hasReportHeaderSection;
			break;
			
		case MADDocumentSectionTypeReportFooter:
			return self.hasReportFooterSection;
			break;
			
		case MADDocumentSectionTypeGroupHeader:
			return [RptqDocumentSection groupHeaderForLevel: level
													  query: self.defaultDatabase.defaultQuery];
			break;
		case MADDocumentSectionTypeGroupFooter:
			return [RptqDocumentSection groupFooterForLevel: level
													  query: self.defaultDatabase.defaultQuery];
			break;
		default:
			//NSAssert(NO, @"Unknown type: %hd at level %ld", type, level);
			return nil;
			break;
	}
}

- (void)setLayoutHeight:(float)height forSectionAtRow:(NSUInteger)sectionRow {
	RptqQuery *query = self.defaultDatabase.defaultQuery;
	RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
													  withNumberOfGroups: query.hasQueryGroups.count];
	section.layoutHeight = height;
}

- (void)setNumberOfRows:(int32_t)numberOfRows forSectionAtRow:(NSUInteger)sectionRow {
	RptqQuery *query = self.defaultDatabase.defaultQuery;
	RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
													  withNumberOfGroups: query.hasQueryGroups.count];
	
	if (section.numberOfRows == numberOfRows) {
		
		//No change
		
	} else if (numberOfRows > section.numberOfRows) {
		
		RptqStoreContext *managedObjectContext = self.storeContext;
		NSString *entityNameSectionRows = NSStringFromClass([RptqDocumentSectionRows class]);
		RptqDocumentSectionRows *newRowToAppend = (RptqDocumentSectionRows *)[managedObjectContext insertObjectForEntity:entityNameSectionRows identifier:0];
		NSArray *hasRowsArray = section.hasRows.array;
		NSMutableOrderedSet *hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
															 [[NSMutableOrderedSet alloc] init];
		newRowToAppend.inSection = section;
		[hasRows addObject:newRowToAppend];
		section.hasRows = hasRows;
		
	} else if (numberOfRows < section.numberOfRows) {
		
		//Remove row
		RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
		NSArray *hasRowsArray = section.hasRows.array;
		NSMutableOrderedSet *hasRows;
		hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
										[[NSMutableOrderedSet alloc] init];
		[hasRows.lastObject setInSection:nil];
		[hasRows removeObjectAtIndex: hasRows.count - 1];
		section.hasRows = hasRows;
		[rowToDelete setInSection:nil];
		
	}
	section.numberOfRows = numberOfRows;
}

- (void)setHeight:(double)height forSectionAtRow:(NSUInteger)sectionRow {
	RptqQuery *query = self.defaultDatabase.defaultQuery;
	RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
													  withNumberOfGroups: query.hasQueryGroups.count];
	section.layoutHeight = height;
}

- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow {
	RptqQuery *query = self.defaultDatabase.defaultQuery;
	RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
													  withNumberOfGroups: query.hasQueryGroups.count];
	section.visibility = isVisible;
}

- (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSUInteger)sectionRow {
	RptqQuery *query = self.defaultDatabase.defaultQuery;
	RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
													  withNumberOfGroups: query.hasQueryGroups.count];
	[section setProducesFormFeed:newPageAfter];
}

- (BOOL)newPageAfterSectionAtRow:(NSUInteger)sectionRow {
	RptqQuery *query = self.defaultDatabase.defaultQuery;
	RptqDocumentSection *section = [self documentSectionForSelectedIndex: sectionRow
													  withNumberOfGroups: query.hasQueryGroups.count];
	return [section producesFormFeed];
}

- (void)storeDatabaseConnectionDefination:(MADDatabase *)database
				  forManagedObjectContext:(RptqStoreContext *)managedObjectContext {

	int64_t cid = (int64_t)self.hasDatabaseSchemas.count + 1;
	RptqDatabase *rptqDB = [RptqDatabase newDatabaseFactoryForManagedObjectContext: managedObjectContext
																			  driverType: database.identifier
																			connectionId: cid];
	
	RptqDatabaseCredentals *credentals = [RptqDatabaseCredentals newDatabaseCredental: managedObjectContext];
	
	NSString *databaseIdentifier = [database.identifier copy];;
	credentals.driverID = databaseIdentifier;

	if (database.databaseConnection != nil) {
		credentals.key = [database.databaseConnection.connectionString copy];
		switch (database.databaseConnection.databaseType) {
			case MADDatabaseTypeMySQL: {
				MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection = (MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)database.databaseConnection;
				credentals.port = databaseConnection.port;
				rptqDB.databaseDriverTypeEnum = MADDatabaseTypeMySQL;
				credentals.host = databaseConnection.host.length > 0 ? databaseConnection.host.copy : databaseConnection.server.copy;
				credentals.server = databaseConnection.server.copy;
				credentals.dbname = databaseConnection.database.copy;
				break;
			}

			case MADDatabaseTypeSqlite3: {
				MADDatabaseConnection *databaseConnection;
				databaseConnection = database.databaseConnection;
				NSURL *sqliteURL = ((id <MADDatabaseConnectionsPropertiesURL>)databaseConnection).databaseUrl;
				credentals.dbname = sqliteURL.path.lastPathComponent.copy;
				credentals.host = sqliteURL.path.copy;
				rptqDB.databaseDriverTypeEnum = MADDatabaseTypeSqlite3;
				break;
			}

			case MADDatabaseTypeTDS: {
				MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection;
				databaseConnection = (MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)database.databaseConnection;
				credentals.port = databaseConnection.port;
				rptqDB.databaseDriverTypeEnum = MADDatabaseTypeTDS;
				credentals.server = databaseConnection.server.copy;
				credentals.host = databaseConnection.host.length > 0 ? databaseConnection.host.copy : databaseConnection.server.copy;
				credentals.dbname = databaseConnection.database.copy;
				break;
			}

			case MADDatabaseTypePostgres: {
				MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection = (MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)database.databaseConnection;
				credentals.port = databaseConnection.port;
				rptqDB.databaseDriverTypeEnum = MADDatabaseTypePostgres;
				credentals.host = databaseConnection.host.length > 0 ? databaseConnection.host.copy : databaseConnection.server.copy;
				credentals.server = databaseConnection.server.copy;
				credentals.dbname = databaseConnection.database.copy;
				break;
			}
			
			default:
				break;
		}
	}
	
	rptqDB.ownedByUser = credentals;
	NSString *rptqQueryId = NSStringFromClass([RptqQuery class]);
	RptqQuery *newQuery = (RptqQuery *)[managedObjectContext insertObjectForEntity:rptqQueryId identifier:0];
	[rptqDB addHasQueriesObject:newQuery];
	
	
	NSSet *databaseSchemas = [self.hasDatabaseSchemas setByAddingObject: rptqDB];
	NSSet *dbs = [[NSSet alloc] initWithSet:databaseSchemas];
	self.hasDatabaseSchemas = dbs;

}

- (MADErrorContainer *)storeTablesAndFieldsForTables:(NSArray *)tables
									   fieldsByTable:(NSDictionary *)fieldsByTable
							 andManagedObjectContext:(RptqStoreContext *)managedObjectContext {
	
	MADErrorContainer * __autoreleasing errorContainer = [[MADErrorContainer alloc] init];
	for (MADDatabaseTable *table in tables) {
		
		NSArray *fields = fieldsByTable[table.name];
		
		if (fields.count) {
			
			RptqDatabaseSchemaTable *rptqTable;
			rptqTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext: managedObjectContext
																							 andTable: table];
			[self.defaultDatabase addHasTablesObject: rptqTable];
			
			NSMutableArray <RptqDatabaseSchemaField *> *schemaFields;
			schemaFields = [[NSMutableArray alloc] initWithCapacity:fields.count];
			RptqDatabaseSchemaField *schemaField;
			for (MADDatabaseField *field in fields) {
				schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext: managedObjectContext
																								   andField: field];
				[schemaFields addObject:schemaField];
			}
			
			NSOrderedSet *hasFields = [[NSOrderedSet alloc] initWithArray:schemaFields];
			rptqTable.hasFields = hasFields;
			
			BOOL success = NO;
			NSError *saveError = nil;
			if (!(success = [rptqTable.storeContext save:&saveError])) {
				os_log_error(OS_LOG_DEFAULT, "Error saving managed object: %@", saveError);
			}

		} else {
			
			NSError *error = [NSError errorWithDomain:@"MADReportDocument" code:38292 userInfo:@{
				NSLocalizedDescriptionKey : NSLocalizedString(@"Fields not found.", @"Fields not found."),
				NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Table %@ not Added.", @"Table %@ not Added."), table.name]
			}];
			[errorContainer addError:error];
			
		}
	}
	return errorContainer;
}

- (void)addQueryLink:(RptqQueryLinks *)queryLink {
	NSSet *linkSet = [NSSet setWithObject: queryLink];
	[self.defaultDatabase.defaultQuery addHasQueryLinks: linkSet];
}

- (void)addPredicate:(RptqQueryPredicate *)predicate {
	
	RptqQuery *query = self.defaultDatabase.defaultQuery;
	NSSet *predicates = [NSSet setWithObject: predicate];
	[query addHasQueryPredicate:predicates];
	
}

- (RptqDocumentElement *)addDocumentObject:(NSDictionary *)defination managedObjectContext:(RptqStoreContext *)managedObjectContext {
	
	NSNumber *objectTypeObj = defination[MTDocumentObjectDefinationType];
	MADPrintPageElementType objectType = (MADPrintPageElementType)objectTypeObj.unsignedIntegerValue;
	
	RptqDocumentElement *reportObject;
	// Initialize elementSize with the default for non-image elements
	CGSize elementSize = CGSizeMake(75.0f, 22.0f);
	
	switch (objectType) {
		case MADPrintPageElementTypeLabelDynamic: {
			
			int64_t fieldObjectID;
			RptqQueryField *field;
			
			fieldObjectID = [defination[MTDocumentObjectDefinationObject] longLongValue];
			field = (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:fieldObjectID];
			
			
			reportObject = (RptqDocumentElement *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier:0];
			
			((RptqDocumentElementLabelDataField *)reportObject).referencesQueryField = field;
			
			((RptqDocumentElementLabelDataField *)reportObject).referencesQueryField = field;
			
			reportObject.type = MADPrintPageElementTypeLabelDynamic;
			
			break;
		}
		case MADPrintPageElementTypeLabelStatic: {
			
			NSString *labelText = defination[MTDocumentObjectDefinationObject];
			
			reportObject = (RptqDocumentElement *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabel class]) identifier:0];
			
			((RptqDocumentElementLabel *)reportObject).text = labelText;
			
			reportObject.type = MADPrintPageElementTypeLabelStatic;
			
			break;
		}
		case MADPrintPageElementTypeAggregate: {
			
			NSDictionary *aggregateOptions = defination[MTDocumentObjectDefinationObject];
			// Gives "CoreData: warning: Sort descriptor key "identifier" may refer to a modelled property or an expression; the modelled property will be used."
			reportObject = (RptqDocumentElement *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqDocumentElementAggregate class]) identifier:0]; // Changed self.managedObjectContext to managedObjectContext for consistency
			
			NSNumber *functionInputType = aggregateOptions[MTDocumentObjectDefinationAggregateFunctionInputType];
			((RptqDocumentElementAggregate *)reportObject).groupNumber = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotNumber] intValue];
			((RptqDocumentElementAggregate *)reportObject).groupType = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotType] shortValue];
			((RptqDocumentElementAggregate *)reportObject).functionType = [aggregateOptions[MTDocumentObjectDefinationAggregateType] shortValue];
			
			int64_t objectId = [aggregateOptions[MTDocumentObjectDefinationAggregateObjectId] longLongValue];
			
			switch ((MTAggregateFunctionInputType)functionInputType.integerValue) {
				case MTAggregateFunctionInputTypeField: {
					RptqQueryField *field = [RptqQueryField queryFieldForObjectID: objectId
															 managedObjectContext: managedObjectContext];
					((RptqDocumentElementAggregate *)reportObject).aggregateField = field;
					[((RptqDocumentElementAggregate *)reportObject) setAggregateFunction:nil];
					break;
				}
				case MTAggregateFunctionInputTypeFormula: {
					RptqDocumentElementFormula *formula = (RptqDocumentElementFormula *)[managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:objectId];
					[((RptqDocumentElementAggregate *)reportObject) setAggregateField:nil];
					((RptqDocumentElementAggregate *)reportObject).aggregateFunction = formula;
					break;
				}
				default:
					break;
			}
			
			reportObject.type = MADPrintPageElementTypeAggregate;
			
			break;
		}
#if __APPLE__
		case MADPrintPageElementTypeImage: {
			
			MADElementImage *image = defination[MTDocumentObjectDefinationObject];
			
			reportObject = (RptqDocumentElement *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqDocumentElementImage class]) identifier:0];
			((RptqDocumentElementImage *)reportObject).image = image; // This sets the original image data and sizeValue to image.size
			
			// Calculate initial size to maintain aspect ratio, with a max width of 75pt
			CGSize originalImageSize = image.size;
			CGFloat maxWidth = 75.0f;
			
			if (originalImageSize.width > maxWidth) {
				// Scale down to maxWidth while maintaining aspect ratio
				CGFloat aspectRatio = originalImageSize.width / originalImageSize.height;
				elementSize = CGSizeMake(maxWidth, maxWidth / aspectRatio);
			} else {
				// Use original width if it's already within the limit, scale height proportionally
				elementSize = originalImageSize;
			}
			
			((RptqDocumentElementImage *)reportObject).type = MADPrintPageElementTypeImage;
			
			image = nil;
			
			break;
		}
#else
		case MADPrintPageElementTypeImage:
			// An image element is created from a UIImage, which is UIKit's;
			// the designer does this and the Linux build does not.
			os_log_error(OS_LOG_DEFAULT, "An image element was skipped: UIImage is not available on this platform.");
			break;
#endif
		case MADPrintPageElementTypeWhtiespace: {
			reportObject = (RptqDocumentElement *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:0];
			reportObject.type = MADPrintPageElementTypeWhtiespace;
			break;
		}
		case MADPrintPageElementTypeBarcode: {

			MADBarcode *barcode = defination[MTDocumentObjectDefinationObject];
			int64_t field1ObjectId = [defination[MTDocumentObjectDefinationField1] longLongValue];
			int64_t field2ObjectId = [defination[MTDocumentObjectDefinationField2] longLongValue];
			RptqQueryField *field1 = [RptqQueryField queryFieldForObjectID: field1ObjectId managedObjectContext: managedObjectContext];
			RptqQueryField *field2 = [RptqQueryField queryFieldForObjectID: field2ObjectId managedObjectContext: managedObjectContext];
			reportObject = [RptqDocumentElementBarcode barcodeWithMtBarcode: barcode
															  queryFieldOne: field1
															  queryFieldTwo: field2];
			reportObject.type = MADPrintPageElementTypeBarcode;

			break;
		}
		default:
			break;
	}
	[reportObject setOriginPoint:CGPointZero];
	// Apply the calculated 'elementSize' for images, or the default size for other elements
	[reportObject setSizeWidth:(float)elementSize.width height:(float)elementSize.height];
	
	NSMutableOrderedSet *hasObjects = [self.hasDetailSection.hasRows[0] hasObjects].mutableCopy;
	[hasObjects insertObject:reportObject atIndex:0];
	[self.hasDetailSection.hasRows[0] setHasObjects:hasObjects];
	return reportObject;
}

- (id)debugQuickLookObject {
	NSMutableString *document = [[NSMutableString alloc] init];
	[document appendFormat:@"*********\n"];
	[document appendFormat:@"Number of sections %lu\n", (unsigned long)[((RptqQuery *)((RptqDatabase *)self.hasDatabaseSchemas.anyObject).hasQueries.anyObject) sectionCount]];
	[document appendFormat:@"Identifier:        %lld\n", self.identifier];
	[document appendFormat:@"Papersize:         %hd\n", self.papersize];
	[document appendFormat:@"Database schemas:  %@\n", self.hasDatabaseSchemas];
	[document appendFormat:@"Page header:       %@\n", self.hasPageHeaderSection];
	[document appendFormat:@"Page footer:       %@\n", self.hasPageFooterSection];
	[document appendFormat:@"Report header:     %@\n", self.hasReportHeaderSection];
	[document appendFormat:@"Report footer:     %@\n", self.hasReportFooterSection];
	[document appendFormat:@"*********"];
	return document;
}

#pragma mark - Composition validation

static NSError *MADCompositionError(NSInteger code, NSString *message) {
	return [NSError errorWithDomain: @"MADCompositionValidationErrorDomain" code: code
						   userInfo: @{ NSLocalizedDescriptionKey: message }];
}

- (BOOL)validateCompositionGraphWithError:(NSError * __autoreleasing *)error {
	RptqQuery *root = self.rootQuery;
	if (root == nil) return YES;	// an ordinary report has nothing to validate
	return [self validateCompositionQuery: root visited: [NSMutableSet set] path: [NSMutableSet set] error: error];
}

- (BOOL)validateCompositionQuery:(RptqQuery *)query
						  visited:(NSMutableSet<NSNumber *> *)visited
							 path:(NSMutableSet<NSNumber *> *)path
							error:(NSError * __autoreleasing *)error {
	NSNumber *key = @(query.identifier);
	if ([path containsObject: key]) {
		if (error != NULL) {
			NSString *name = query.name ?: NSLocalizedString(@"<unnamed>", @"Unnamed query in a composition error.");
			*error = MADCompositionError(1, [[NSString alloc] initWithFormat:
				NSLocalizedString(@"The composition graph has a cycle involving the query '%@'.", @"Cycle validation error."), name]);
		}
		return NO;
	}
	if ([visited containsObject: key]) return YES;
	[path addObject: key];

	// A node's tables are either all children (a composing node) or all remote schema
	// tables (a leaf).  Mixing the two is invalid: a remote table cannot be attached,
	// and the walk classifies a node by whether any table carries an upstream reference
	// (MAD_COMPOSITION_SPEC.md §6).  Reject it here so the failure names the node.
	BOOL hasUpstreamTable = NO;
	BOOL hasRemoteTable = NO;
	for (RptqQueryTable *table in query.hasQueryTables) {
		if ([table.backingObject referenceForName: @"upstreamQuery"] != nil) hasUpstreamTable = YES;
		else hasRemoteTable = YES;
	}
	if (hasUpstreamTable && hasRemoteTable) {
		if (error != NULL) {
			NSString *name = query.name ?: NSLocalizedString(@"<unnamed>", @"Unnamed query in a composition error.");
			*error = MADCompositionError(3, [[NSString alloc] initWithFormat:
				NSLocalizedString(@"The query '%@' mixes remote tables with other reports.  A composing query references only other reports, never a remote table.", @"Mixed composition node."), name]);
		}
		return NO;
	}

	// A composing node attaches each child read-only; SQLITE_MAX_ATTACHED caps a
	// node's direct children at ten in this milestone (MAD_COMPOSITION_SPEC.md §6).
	NSMutableSet<NSNumber *> *directChildren = [NSMutableSet set];
	for (RptqQueryTable *table in query.hasQueryTables) {
		NSNumber *upstreamIdentifier = [table.backingObject referenceForName: @"upstreamQuery"];
		if (upstreamIdentifier != nil) {
			[directChildren addObject: upstreamIdentifier];
		}
	}
	if (directChildren.count > 10) {
		if (error != NULL) {
			NSString *name = query.name ?: NSLocalizedString(@"<unnamed>", @"Unnamed query in a composition error.");
			*error = MADCompositionError(4, [[NSString alloc] initWithFormat:
				NSLocalizedString(@"The query '%@' has more than ten direct sources, which this build cannot attach.", @"Too many composition children."), name]);
		}
		return NO;
	}

	for (RptqQueryTable *table in query.hasQueryTables) {
		NSNumber *upstreamIdentifier = [table.backingObject referenceForName: @"upstreamQuery"];
		if (upstreamIdentifier == nil) continue;
		RptqQuery *upstream = table.upstreamQuery;
		if (upstream == nil) {
			if (error != NULL) {
				NSString *name = query.name ?: NSLocalizedString(@"<unnamed>", @"Unnamed query in a composition error.");
				*error = MADCompositionError(2, [[NSString alloc] initWithFormat:
					NSLocalizedString(@"The query '%@' references a missing upstream query (%@).", @"Missing-upstream validation error."), name, upstreamIdentifier]);
			}
			return NO;
		}
		if (![self validateCompositionQuery: upstream visited: visited path: path error: error]) return NO;
	}

	[path removeObject: key];
	[visited addObject: key];
	return YES;
}

- (NSArray<RptqQueryField *> *)orderedCompositionOutputsWithError:(NSError * __autoreleasing *)error {
	RptqQuery *root = self.rootQuery;
	if (root == nil) return @[];
	return [root orderedOutputFieldsWithError: error];
}

- (nullable RptqQuery *)convertToCompositionWithChildName:(nullable NSString *)childName
													 error:(NSError * __autoreleasing *)error {
	if (self.rootQuery != nil) {
		if (error != NULL) *error = MADCompositionError(5, NSLocalizedString(@"This report is already a composition.", @"Conversion error: already composed."));
		return nil;
	}
	RptqQuery *child = self.mainQuery;
	if (child == nil) {
		if (error != NULL) *error = MADCompositionError(6, NSLocalizedString(@"This report has no query to convert.", @"Conversion error: no query."));
		return nil;
	}
	RptqStoreContext *context = self.storeContext;
	if (context == nil) {
		if (error != NULL) *error = MADCompositionError(7, NSLocalizedString(@"No report store to convert.", @"Conversion error: no store."));
		return nil;
	}

	// A composed child is named; an ordinary report's query is not.  Derive a stable
	// name from the child's first schema table when the caller names none.
	if (childName.length > 0) {
		child.name = childName;
	} else if (child.name.length == 0) {
		NSString *tableName = child.hasQueryTables.anyObject.databaseSchemaTable.name;
		child.name = tableName.length > 0 ? tableName : NSLocalizedString(@"child", @"Default converted child name.");
	}

	// The new root and its single upstream table over the child.
	RptqQuery *root = (RptqQuery *)[context insertObjectForEntity:@"RptqQuery" identifier:0];
	root.name = @"root";
	root.inDatabase = child.inDatabase;
	RptqQueryTable *rootTable = (RptqQueryTable *)[context insertObjectForEntity:@"RptqQueryTable" identifier:0];
	rootTable.inQuery = root;
	rootTable.upstreamQuery = child;
	self.rootQuery = root;

	// One root field per child field, in a stable (identifier) order, and a map from
	// each child field to its root counterpart for the group/sort/layout rebinding.
	NSArray<RptqQueryTable *> *childTables = [[child.hasQueryTables allObjects] sortedArrayUsingComparator:
		^NSComparisonResult(RptqQueryTable *a, RptqQueryTable *b) { return [@(a.identifier) compare:@(b.identifier)]; }];
	NSMutableArray<RptqQueryField *> *rootFields = [NSMutableArray array];
	NSMutableDictionary<NSNumber *, RptqQueryField *> *rootFieldForChildField = [NSMutableDictionary dictionary];
	for (RptqQueryTable *childTable in childTables) {
		NSArray<RptqQueryField *> *childFields = [[childTable.hasQueryFields allObjects] sortedArrayUsingComparator:
			^NSComparisonResult(RptqQueryField *a, RptqQueryField *b) { return [@(a.identifier) compare:@(b.identifier)]; }];
		for (RptqQueryField *childField in childFields) {
			RptqQueryField *rootField = (RptqQueryField *)[context insertObjectForEntity:@"RptqQueryField" identifier:0];
			rootField.inQueryTable = rootTable;
			rootField.databaseSchemaField = childField.databaseSchemaField;
			[rootFields addObject:rootField];
			rootFieldForChildField[@(childField.identifier)] = rootField;
		}
	}

	// Name and order the root outputs (bare names, alias-qualified on collision).
	NSArray<NSString *> *keys = [RptqQuery composeOutputKeysForFields:rootFields existingKeys:[NSSet set]];
	for (NSUInteger i = 0; i < rootFields.count; i++) {
		rootFields[i].outputKey = keys[i];
		rootFields[i].outputIndex = (int64_t)i;
	}

	// Move the child's groups to the root, rebinding each group's field and keeping
	// its bands and sort direction.
	for (RptqQueryGroup *group in [child.hasQueryGroups copy]) {
		RptqQueryField *rootField = (group.hasField != nil) ? rootFieldForChildField[@(group.hasField.identifier)] : nil;
		if (rootField != nil) {
			RptqQueryGroup *rootGroup = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
			rootGroup.inQuery = root;
			rootGroup.hasField = rootField;
			rootGroup.sort = group.sort;
			rootGroup.weight = group.weight;
			if (group.hasSection.count > 0) {
				rootGroup.hasSection = group.hasSection;
			}
		}
		[child removeHasQueryGroupsObject:group];
		[context deleteObject:group error:NULL];
	}

	// Move the child's sort to the root.
	RptqQuerySort *childSort = child.hasQuerySort;
	if (childSort != nil) {
		RptqQueryField *rootField = (childSort.hasField != nil) ? rootFieldForChildField[@(childSort.hasField.identifier)] : nil;
		if (rootField != nil) {
			RptqQuerySort *rootSort = (RptqQuerySort *)[context insertObjectForEntity:@"RptqQuerySort" identifier:0];
			rootSort.inQuery = root;
			rootSort.hasField = rootField;
			rootSort.ascending = childSort.ascending;
		}
		[context deleteObject:childSort error:NULL];
	}

	// Rebind the layout's field references from the child's fields to the root's, so
	// the existing labels, aggregates, and barcodes keep resolving to the same values.
	for (RptqQueryTable *childTable in childTables) {
		for (RptqQueryField *childField in childTable.hasQueryFields) {
			RptqQueryField *rootField = rootFieldForChildField[@(childField.identifier)];
			if (rootField == nil) continue;
			for (RptqDocumentElementLabelDataField *label in [childField.inDataObject copy]) {
				label.referencesQueryField = rootField;
			}
			for (RptqDocumentElementAggregate *aggregate in [childField.inAggregateObject copy]) {
				aggregate.aggregateField = rootField;
			}
			for (RptqDocumentElementBarcode *barcode in [childField.inBarcodeField1 copy]) {
				barcode.referencesField1 = rootField;
			}
			for (RptqDocumentElementBarcode *barcode in [childField.inBarcodeField2 copy]) {
				barcode.referencesField2 = rootField;
			}
		}
	}

	return root;
}

- (nullable RptqQueryTable *)addChildQuery:(RptqQuery *)child
									  error:(NSError * __autoreleasing *)error {
	RptqQuery *root = self.rootQuery;
	if (root == nil) {
		if (error != NULL) *error = MADCompositionError(8, NSLocalizedString(@"This report has no root to add a child to.", @"Add-child error: no root."));
		return nil;
	}
	if (child == nil) {
		if (error != NULL) *error = MADCompositionError(9, NSLocalizedString(@"No child report to add.", @"Add-child error: no child."));
		return nil;
	}
	RptqStoreContext *context = self.storeContext;
	if (context == nil) {
		if (error != NULL) *error = MADCompositionError(10, NSLocalizedString(@"No report store to add a child to.", @"Add-child error: no store."));
		return nil;
	}

	for (RptqQueryTable *existing in root.hasQueryTables) {
		if (existing.upstreamQuery == child) return existing;
	}

	// Existing root outputs reserve their keys and their place in the order.
	NSMutableSet<NSString *> *existingKeys = [NSMutableSet set];
	int64_t maxIndex = -1;
	for (RptqQueryTable *table in root.hasQueryTables) {
		for (RptqQueryField *field in table.hasQueryFields) {
			if (field.outputKey.length > 0) {
				[existingKeys addObject:field.outputKey];
				if (field.outputIndex > maxIndex) maxIndex = field.outputIndex;
			}
		}
	}

	RptqQueryTable *rootTable = (RptqQueryTable *)[context insertObjectForEntity:@"RptqQueryTable" identifier:0];
	rootTable.inQuery = root;
	rootTable.upstreamQuery = child;

	NSArray<RptqQueryTable *> *childTables = [[child.hasQueryTables allObjects] sortedArrayUsingComparator:
		^NSComparisonResult(RptqQueryTable *a, RptqQueryTable *b) { return [@(a.identifier) compare:@(b.identifier)]; }];
	NSMutableArray<RptqQueryField *> *rootFields = [NSMutableArray array];
	for (RptqQueryTable *childTable in childTables) {
		NSArray<RptqQueryField *> *childFields = [[childTable.hasQueryFields allObjects] sortedArrayUsingComparator:
			^NSComparisonResult(RptqQueryField *a, RptqQueryField *b) { return [@(a.identifier) compare:@(b.identifier)]; }];
		for (RptqQueryField *childField in childFields) {
			RptqQueryField *rootField = (RptqQueryField *)[context insertObjectForEntity:@"RptqQueryField" identifier:0];
			rootField.inQueryTable = rootTable;
			rootField.databaseSchemaField = childField.databaseSchemaField;
			[rootFields addObject:rootField];
		}
	}

	NSArray<NSString *> *keys = [RptqQuery composeOutputKeysForFields:rootFields existingKeys:existingKeys];
	for (NSUInteger i = 0; i < rootFields.count; i++) {
		rootFields[i].outputKey = keys[i];
		rootFields[i].outputIndex = maxIndex + 1 + (int64_t)i;
	}
	return rootTable;
}

@end
