//
//  NSObject+RptqDocument_Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocument+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqQuery+Extras.h"
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
#import "RptqDocumentElementFormula+Extras.h"
#import "RptqDataHelper.h"
#import "MADReportSectionsEnumerator.h"

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

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <UIKit/UIImage.h>

#import <os/log.h>

static os_log_t rptq_log;

@implementation RptqDocument (Extras)

+ (void)load {
	if (self == [RptqDocument class]) {
		NSString *c = NSStringFromClass([RptqDocument class]);
		rptq_log = os_log_create("com.mad", c.UTF8String);
	}
}

#pragma mark - Static

+ (void)deleteExistingDocuments:(NSManagedObjectContext *)context {
	NSString *rptqDocumentName = NSStringFromClass([RptqDocument class]);
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: rptqDocumentName];
	
	NSError *error = nil;
	NSArray *documents = [context executeFetchRequest:request error:&error];
	if (error != nil) {
		os_log_error(rptq_log, "Failed to fetch existing documents: %{public}@", error);
	} else if (documents.count > 0) {
		for (RptqDocument *document in documents) {
			[context deleteObject:document];
		}
		if (![context save:&error]) {
			os_log_error(rptq_log, "Failed to save after document deletion: %{public}@", error);
		}
	}
	
	if (!error) {
		if (documents && documents.count > 0) {
			for (RptqDocument *document in documents) {
				[context deleteObject:document];
			}
		}
	}
}

+ (instancetype)newDocumentForManagedObjectContext:(NSManagedObjectContext *)context {
	NSAssert(context != nil, @"Context must not be nil");
	
	[self deleteExistingDocuments:context];
	
	NSString *rptqDocumentName = NSStringFromClass([RptqDocument class]);
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName: rptqDocumentName
														 inManagedObjectContext: context];
	NSAssert(entityDescription != nil, @"Failed to get entity description for %@", rptqDocumentName);
	
	RptqDocument *document = [[RptqDocument alloc] initWithEntity: entityDescription insertIntoManagedObjectContext: context];
	NSAssert(document != nil, @"Failed to create new document");
	
	RptqDocumentSection*(^createSection)(NSManagedObjectContext *, int64_t, NSString *) =
	^RptqDocumentSection*(NSManagedObjectContext *ctx, int64_t identifier, NSString *sectionClass) {
		RptqDocumentSection *section = [NSEntityDescription insertNewObjectForEntityForName:sectionClass
																	 inManagedObjectContext:ctx];
		NSAssert(section != nil, @"Failed to create section");
		section.identifier = identifier;
		return section;
	};

	NSString *docSection = NSStringFromClass([RptqDocumentSection class]);
	NSString *rptqDocumentSectionRows = NSStringFromClass([RptqDocumentSectionRows class]);
	
	document.hasReportHeaderSection = createSection(context, 1, docSection);
	document.hasReportFooterSection = createSection(context, 2, docSection);
	document.hasPageHeaderSection = createSection(context, 3, docSection);
	document.hasPageFooterSection = createSection(context, 4, docSection);
	document.hasDetailSection = createSection(context, 5, docSection);

	RptqDocumentSectionRows *headerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
																	   inManagedObjectContext: context];
	NSAssert(headerRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows1 = [[NSOrderedSet alloc] initWithObject: headerRow];
	document.hasReportHeaderSection.hasRows = hasRows1;
	headerRow.inSection = document.hasReportHeaderSection;

	RptqDocumentSectionRows *footerRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
																	   inManagedObjectContext: context];
	NSAssert(footerRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows2 = [[NSOrderedSet alloc] initWithObject: footerRow];
	document.hasReportFooterSection.hasRows = hasRows2;
	footerRow.inSection = document.hasReportFooterSection;

	RptqDocumentSectionRows *pageHeaderRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
																		   inManagedObjectContext: context];
	NSAssert(pageHeaderRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows3 = [[NSOrderedSet alloc] initWithObject: pageHeaderRow];
	document.hasPageHeaderSection.hasRows = hasRows3;
	pageHeaderRow.inSection = document.hasPageHeaderSection;

	RptqDocumentSectionRows *pageFooterRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
																		   inManagedObjectContext: context];
	NSAssert(pageFooterRow != nil, @"Failed to create section row.");
	NSOrderedSet <RptqDocumentSectionRows *> *hasRows4 = [[NSOrderedSet alloc] initWithObject: pageFooterRow];
	document.hasPageFooterSection.hasRows = hasRows4;
	pageFooterRow.inSection = document.hasPageFooterSection;

	RptqDocumentSectionRows *detailSectionRow = [NSEntityDescription insertNewObjectForEntityForName: rptqDocumentSectionRows
																			  inManagedObjectContext: context];
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

	NSError *error1 = nil;
	if (![document.hasReportHeaderSection validateForUpdate: &error1]) {
		if (error1 != nil) {
			os_log_error(rptq_log, "%s: %@", __PRETTY_FUNCTION__, error1);
		}
	}
	
	NSError *error2 = nil;
	if (![document.hasDetailSection validateForUpdate: &error2]) {
		if (error2 != nil) {
			os_log_error(rptq_log, "%s: %@", __PRETTY_FUNCTION__, error2);
		}
	}
	
	NSError *error3 = nil;
	if (![document validateForUpdate: &error3]) {
		if (error3 != nil) {
			os_log_error(rptq_log, "%s: %@", __PRETTY_FUNCTION__, error3);
		}
	}
	
	return document;
}

+ (instancetype)newDocumentReadFromManagedObjectContext:(NSManagedObjectContext *)objectContext {
	NSAssert(objectContext != nil, @"Context must not be nil");

	NSFetchRequest *docFetchRequest = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocument class])];
	docFetchRequest.fetchLimit = 1;

	NSError *error = nil;
	NSArray *documents = [objectContext executeFetchRequest:docFetchRequest error:&error];
	if (error != nil) {
		os_log_error(rptq_log, "Failed to fetch document: %{public}@", error);
		NSAssert(NO, @"Failed to fetch document: %@", error);
	}
	NSAssert(documents.count > 0, @"No documents found");
	return documents.lastObject;
}

#pragma mark - Overrides

- (void)willTurnIntoFault {
	[super willTurnIntoFault];
}

- (void)didTurnIntoFault {
	[super didTurnIntoFault];
}

- (void)willChangeValueForKey:(NSString *)inKey
			  withSetMutation:(NSKeyValueSetMutationKind)inMutationKind
				 usingObjects:(NSSet *)inObjects {
	[super willChangeValueForKey: inKey
				 withSetMutation: inMutationKind
					usingObjects: inObjects];
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	self.identifier = 1;
	if (self.managedObjectContext.parentContext && self.identifier <= 0) {
		[[NSNotificationCenter defaultCenter] willChangeValueForKey:NSStringFromSelector(@selector(identifier))];
		self.identifier = [RptqDataHelper nextIdentifierForClass:[self class] managedObjectContext:self.managedObjectContext];
		[[NSNotificationCenter defaultCenter] didChangeValueForKey:NSStringFromSelector(@selector(identifier))];
	}
}

- (RptqQuery *)mainQuery {
	RptqDatabase *defaultDatabase = self.hasDatabaseSchemas.anyObject;
	return defaultDatabase.hasQueries.anyObject;
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
		
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		NSString *entityNameSectionRows = NSStringFromClass([RptqDocumentSectionRows class]);
		RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: entityNameSectionRows
																				inManagedObjectContext: managedObjectContext];
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
				  forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

	int64_t cid = (int64_t)self.hasDatabaseSchemas.count + 1;
	RptqDatabase *rptqDB = [RptqDatabase newDatabaseFactoryForManagedObjectContext: managedObjectContext
																			  driverType: database.identifier
																			connectionId: cid];
	
	RptqDatabaseCredentals *credentals = [RptqDatabaseCredentals newDatabaseCredental: managedObjectContext];
	
	NSString *databaseIdentifier = [database.identifier copy];;
	credentals.driverID = databaseIdentifier;

	if (database.databaseConnection != nil) {
		
		switch (database.databaseConnection.databaseType) {
			case MADDatabaseTypeMySQL: {
				MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection = (MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)database.databaseConnection;
				credentals.port = databaseConnection.port;
				credentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeMySQL;
				credentals.host = databaseConnection.server.copy;
				credentals.dbname = databaseConnection.database.copy;
				break;
			}

			case MADDatabaseTypeSqlite3: {
				MADDatabaseConnection *databaseConnection;
				databaseConnection = database.databaseConnection;
				credentals.dbname = ((id <MADDatabaseConnectionsPropertiesURL>)databaseConnection).databaseUrl.path.lastPathComponent.copy;
				credentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeSqlite3;
				break;
			}

			case MADDatabaseTypeTDS: {
				MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection;
				databaseConnection = (MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)database.databaseConnection;
				credentals.port = databaseConnection.port;
				credentals.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeTDS;
				credentals.server = databaseConnection.server.copy;
				credentals.host = databaseConnection.server.copy;
				credentals.dbname = databaseConnection.database.copy;
				break;
			}
			
			default:
				break;
		}
	}
	
	rptqDB.ownedByUser = credentals;
	NSString *rptqQueryId = NSStringFromClass([RptqQuery class]);
	RptqQuery *newQuery = [NSEntityDescription insertNewObjectForEntityForName: rptqQueryId
														inManagedObjectContext: managedObjectContext];
	[rptqDB addHasQueriesObject:newQuery];
	
	
	NSSet *databaseSchemas = [self.hasDatabaseSchemas setByAddingObject: rptqDB];
	NSSet *dbs = [[NSSet alloc] initWithSet:databaseSchemas];
	self.hasDatabaseSchemas = dbs;

}

- (MADErrorContainer *)storeTablesAndFieldsForTables:(NSArray *)tables
									   fieldsByTable:(NSDictionary *)fieldsByTable
							 andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
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
			if (!(success = [rptqTable.managedObjectContext save:&saveError])) {
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

- (RptqDocumentElement *)addDocumentObject:(NSDictionary *)defination managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	NSNumber *objectTypeObj = defination[MTDocumentObjectDefinationType];
	MADPrintPageElementType objectType = (MADPrintPageElementType)objectTypeObj.unsignedIntegerValue;
	
	RptqDocumentElement *reportObject;
	NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
	
	// Initialize elementSize with the default for non-image elements
	CGSize elementSize = CGSizeMake(75.0f, 22.0f);
	
	switch (objectType) {
		case MADPrintPageElementTypeLabelDynamic: {
			
			NSManagedObjectID *fieldObjectID;
			RptqQueryField *field;
			
			entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentElementLabelDataField class])
																 inManagedObjectContext: managedObjectContext];
			
			fieldObjectID = defination[MTDocumentObjectDefinationObject];
			field = (RptqQueryField *)[managedObjectContext objectWithID:fieldObjectID];
			
			
			reportObject = [[RptqDocumentElementLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
													  insertIntoManagedObjectContext: managedObjectContext];
			
			((RptqDocumentElementLabelDataField *)reportObject).referencesQueryField = field;
			
			((RptqDocumentElementLabelDataField *)reportObject).referencesQueryField = field;
			
			reportObject.type = MADPrintPageElementTypeLabelDynamic;
			
			break;
		}
		case MADPrintPageElementTypeLabelStatic: {
			
			entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentElementLabel class])
																 inManagedObjectContext: managedObjectContext];
			
			NSString *labelText = defination[MTDocumentObjectDefinationObject];
			
			reportObject = [[RptqDocumentElementLabel alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
											 insertIntoManagedObjectContext: managedObjectContext];
			
			((RptqDocumentElementLabel *)reportObject).text = labelText;
			
			reportObject.type = MADPrintPageElementTypeLabelStatic;
			
			break;
		}
		case MADPrintPageElementTypeAggregate: {
			
			entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentElementAggregate class])
																 inManagedObjectContext: managedObjectContext];
			
			NSDictionary *aggregateOptions = defination[MTDocumentObjectDefinationObject];
			// Gives "CoreData: warning: Sort descriptor key "identifier" may refer to a modelled property or an expression; the modelled property will be used."
			reportObject = [[RptqDocumentElementAggregate alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
												 insertIntoManagedObjectContext: managedObjectContext]; // Changed self.managedObjectContext to managedObjectContext for consistency
			
			NSNumber *functionInputType = aggregateOptions[MTDocumentObjectDefinationAggregateFunctionInputType];
			((RptqDocumentElementAggregate *)reportObject).groupNumber = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotNumber] intValue];
			((RptqDocumentElementAggregate *)reportObject).groupType = [aggregateOptions[MTDocumentObjectDefinationAggregatePivotType] shortValue];
			((RptqDocumentElementAggregate *)reportObject).functionType = [aggregateOptions[MTDocumentObjectDefinationAggregateType] shortValue];
			
			NSManagedObjectID *objectId = aggregateOptions[MTDocumentObjectDefinationAggregateObjectId];
			
			switch ((MTAggregateFunctionInputType)functionInputType.integerValue) {
				case MTAggregateFunctionInputTypeField: {
					RptqQueryField *field = [RptqQueryField queryFieldForObjectID: objectId
															 managedObjectContext: managedObjectContext];
					((RptqDocumentElementAggregate *)reportObject).aggregateField = field;
					[((RptqDocumentElementAggregate *)reportObject) setAggregateFunction:nil];
					break;
				}
				case MTAggregateFunctionInputTypeFormula: {
					RptqDocumentElementFormula *formula = [managedObjectContext objectWithID: objectId];
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
		case MADPrintPageElementTypeImage: {
			
			entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentElementImage class])
																 inManagedObjectContext: managedObjectContext];
			
			UIImage *image = defination[MTDocumentObjectDefinationObject];
			
			reportObject = [[RptqDocumentElementImage alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
											 insertIntoManagedObjectContext: managedObjectContext];
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
		case MADPrintPageElementTypeWhtiespace: {
			reportObject.type = MADPrintPageElementTypeWhtiespace;
			
			break;
		}
		case MADPrintPageElementTypeBarcode: {
			
			MTBarcode *barcode = defination[MTDocumentObjectDefinationObject];
			NSManagedObjectID *field1ObjectId = defination[MTDocumentObjectDefinationField1];
			NSManagedObjectID *field2ObjectId = defination[MTDocumentObjectDefinationField2];
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

@end
