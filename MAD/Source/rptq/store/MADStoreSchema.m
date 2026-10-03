//
//  MADStoreSchema.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "MADStoreSchema.h"

NSString * const MADStorePositionColumn = @"position";
NSString * const MADStoreIdentifierColumnSuffix = @"_identifier";

#pragma mark - Attribute

@implementation MADStoreAttribute

+ (instancetype)attributeWithName:(NSString *)name
							 type:(MADStoreValueType)type
						 optional:(BOOL)optional {
	MADStoreAttribute *attribute = [MADStoreAttribute new];
	attribute.name = name;
	attribute.type = type;
	attribute.optional = optional;
	attribute.subentityAttribute = optional;
	return attribute;
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@ %@>", NSStringFromClass(self.class), self.name];
}

@end

#pragma mark - Relationship

@implementation MADStoreRelationship

+ (instancetype)toOneNamed:(NSString *)name
			   destination:(NSString *)destination
				   inverse:(NSString *)inverse
			ownsForeignKey:(BOOL)ownsForeignKey {
	MADStoreRelationship *relationship = [MADStoreRelationship new];
	relationship.name = name;
	relationship.destination = destination;
	relationship.inverse = inverse;
	relationship.toMany = NO;
	relationship.ordered = NO;
	relationship.ownsForeignKey = ownsForeignKey;
	return relationship;
}

+ (instancetype)toManyNamed:(NSString *)name
				destination:(NSString *)destination
					inverse:(NSString *)inverse
					ordered:(BOOL)ordered {
	MADStoreRelationship *relationship = [MADStoreRelationship new];
	relationship.name = name;
	relationship.destination = destination;
	relationship.inverse = inverse;
	relationship.toMany = YES;
	relationship.ordered = ordered;
	relationship.ownsForeignKey = NO;
	return relationship;
}

+ (instancetype)toManyNamed:(NSString *)name
				destination:(NSString *)destination
					inverse:(NSString *)inverse
				  joinTable:(NSString *)joinTable
				 joinColumn:(NSString *)joinColumn {
	MADStoreRelationship *relationship = [MADStoreRelationship new];
	relationship.name = name;
	relationship.destination = destination;
	relationship.inverse = inverse;
	relationship.toMany = YES;
	relationship.ordered = NO;
	relationship.ownsForeignKey = NO;
	relationship.joinTable = joinTable;
	relationship.joinColumn = joinColumn;
	return relationship;
}

- (NSString *)column {
	if (!self.ownsForeignKey) return nil;
	return [self.name stringByAppendingString:MADStoreIdentifierColumnSuffix];
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@ %@ -> %@>", NSStringFromClass(self.class), self.name, self.destination];
}

@end

#pragma mark - Entity

@interface MADStoreEntity ()
// The two flags the schema works out for itself; everything else on the entity is
// the description the descriptors hand it.
@property (nonatomic, assign) BOOL hasModelIdentifier;
@property (nonatomic, assign) BOOL hasPositionColumn;
// Memoized flattened arrays and name indexes, warmed once at the end of schema
// construction; the descriptors are immutable after that, so these never change.
@property (nonatomic, strong) NSArray<MADStoreAttribute *> *flattenedAttributes;
@property (nonatomic, strong) NSArray<MADStoreRelationship *> *flattenedRelationships;
@property (nonatomic, strong) NSDictionary<NSString *, MADStoreAttribute *> *attributesByName;
@property (nonatomic, strong) NSDictionary<NSString *, MADStoreRelationship *> *relationshipsByName;
@end

@implementation MADStoreEntity

+ (instancetype)entityWithName:(NSString *)name
					attributes:(NSArray<MADStoreAttribute *> *)attributes
				 relationships:(NSArray<MADStoreRelationship *> *)relationships {
	MADStoreEntity *entity = [MADStoreEntity new];
	entity.name = name;
	entity.attributes = attributes;
	entity.relationships = relationships;
	entity.subentities = @[];
	return entity;
}

+ (instancetype)subentityWithName:(NSString *)name
						   parent:(NSString *)parent
					   attributes:(NSArray<MADStoreAttribute *> *)attributes
					relationships:(NSArray<MADStoreRelationship *> *)relationships {
	MADStoreEntity *entity = [MADStoreEntity entityWithName:name
												 attributes:attributes
											  relationships:relationships];
	entity.kind = name;
	entity.parentName = parent;
	return entity;
}

- (BOOL)isSubentity { return self.parentName != nil; }

- (MADStoreAttribute *)attributeNamed:(NSString *)name {
	for (MADStoreAttribute *attribute in self.attributes) {
		if ([attribute.name isEqualToString:name]) return attribute;
	}
	return nil;
}

- (MADStoreRelationship *)relationshipNamed:(NSString *)name {
	for (MADStoreRelationship *relationship in self.relationships) {
		if ([relationship.name isEqualToString:name]) return relationship;
	}
	return nil;
}

- (void)buildNameIndexes {
	NSMutableDictionary<NSString *, MADStoreAttribute *> *attributesByName =
		[NSMutableDictionary dictionaryWithCapacity:self.flattenedAttributes.count];
	for (MADStoreAttribute *attribute in self.flattenedAttributes) {
		// First-match wins, the same order -allAttributes walks: an ancestor's
		// attribute comes first, so it shadows a subentity's of the same name.
		if (attributesByName[attribute.name] == nil) attributesByName[attribute.name] = attribute;
	}
	self.attributesByName = attributesByName;

	NSMutableDictionary<NSString *, MADStoreRelationship *> *relationshipsByName =
		[NSMutableDictionary dictionaryWithCapacity:self.flattenedRelationships.count];
	for (MADStoreRelationship *relationship in self.flattenedRelationships) {
		if (relationshipsByName[relationship.name] == nil) relationshipsByName[relationship.name] = relationship;
	}
	self.relationshipsByName = relationshipsByName;
}

// The lazy path -- sharedSchema is complete by the time anything outside the
// schema's own init can ask, so the recursion is safe.  The init warms every
// entity at the end anyway, so this only runs for a schema built before that.
- (void)warmLookupsLazily {
	if (self.flattenedAttributes != nil) return;
	if (!self.parentName) {
		self.flattenedAttributes = self.attributes;
		self.flattenedRelationships = self.relationships;
	} else {
		MADStoreEntity *parent = [[MADStoreSchema sharedSchema] entityNamed:self.parentName];
		[parent warmLookupsLazily];
		self.flattenedAttributes = [parent.flattenedAttributes arrayByAddingObjectsFromArray:self.attributes];
		self.flattenedRelationships = [parent.flattenedRelationships arrayByAddingObjectsFromArray:self.relationships];
	}
	[self buildNameIndexes];
}

// The init's form: the parent chain walks the local name dictionary, because
// +sharedSchema is still inside its dispatch_once and cannot be re-entered.
- (void)warmLookupsWithNames:(NSDictionary<NSString *, MADStoreEntity *> *)byName {
	if (self.flattenedAttributes != nil) return;
	if (!self.parentName) {
		self.flattenedAttributes = self.attributes;
		self.flattenedRelationships = self.relationships;
	} else {
		MADStoreEntity *parent = byName[self.parentName];
		[parent warmLookupsWithNames:byName];
		self.flattenedAttributes = [parent.flattenedAttributes arrayByAddingObjectsFromArray:self.attributes];
		self.flattenedRelationships = [parent.flattenedRelationships arrayByAddingObjectsFromArray:self.relationships];
	}
	[self buildNameIndexes];
}

- (MADStoreAttribute *)anyAttributeNamed:(NSString *)name {
	[self warmLookupsLazily];
	return self.attributesByName[name];
}

- (MADStoreRelationship *)anyRelationshipNamed:(NSString *)name {
	[self warmLookupsLazily];
	return self.relationshipsByName[name];
}

- (NSArray<MADStoreAttribute *> *)allAttributes {
	[self warmLookupsLazily];
	return self.flattenedAttributes;
}

- (NSArray<MADStoreRelationship *> *)allRelationships {
	[self warmLookupsLazily];
	return self.flattenedRelationships;
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@ %@>", NSStringFromClass(self.class), self.name];
}

@end

#pragma mark - Descriptors

static MADStoreAttribute *Int(NSString *name) {
	return [MADStoreAttribute attributeWithName:name type:MADStoreValueTypeInteger optional:NO];
}

static MADStoreAttribute *IntOpt(NSString *name) {
	return [MADStoreAttribute attributeWithName:name type:MADStoreValueTypeInteger optional:YES];
}

static MADStoreAttribute *Real(NSString *name) {
	return [MADStoreAttribute attributeWithName:name type:MADStoreValueTypeReal optional:NO];
}

static MADStoreAttribute *RealOpt(NSString *name) {
	return [MADStoreAttribute attributeWithName:name type:MADStoreValueTypeReal optional:YES];
}

static MADStoreAttribute *Text(NSString *name) {
	return [MADStoreAttribute attributeWithName:name type:MADStoreValueTypeText optional:NO];
}

static MADStoreAttribute *TextOpt(NSString *name) {
	return [MADStoreAttribute attributeWithName:name type:MADStoreValueTypeText optional:YES];
}

static MADStoreAttribute *BlobOpt(NSString *name) {
	return [MADStoreAttribute attributeWithName:name type:MADStoreValueTypeBlob optional:YES];
}

static MADStoreRelationship *ToOne(NSString *name, NSString *destination, NSString *inverse, BOOL ownsKey) {
	return [MADStoreRelationship toOneNamed:name destination:destination inverse:inverse ownsForeignKey:ownsKey];
}

static MADStoreRelationship *ToMany(NSString *name, NSString *destination, NSString *inverse) {
	return [MADStoreRelationship toManyNamed:name destination:destination inverse:inverse ordered:NO];
}

static MADStoreRelationship *ToManyOrdered(NSString *name, NSString *destination, NSString *inverse) {
	return [MADStoreRelationship toManyNamed:name destination:destination inverse:inverse ordered:YES];
}

/// The one many-to-many: a query selects schema fields, and a field knows the
/// queries that select it.  Both sides name the same join table and their own
/// column in it.
static MADStoreRelationship *QuerySelectsFields(void) {
	return [MADStoreRelationship toManyNamed:@"hasFields"
								 destination:@"RptqDatabaseSchemaField"
									 inverse:@"inQuery"
								   joinTable:@"RptqQueryHasFields"
								  joinColumn:@"query_identifier"];
}

static MADStoreRelationship *FieldSelectedByQueries(void) {
	return [MADStoreRelationship toManyNamed:@"inQuery"
								 destination:@"RptqQuery"
									 inverse:@"hasFields"
								   joinTable:@"RptqQueryHasFields"
								  joinColumn:@"field_identifier"];
}

static MADStoreEntity *Table(NSString *name, NSArray *attributes, NSArray *relationships) {
	return [MADStoreEntity entityWithName:name attributes:attributes relationships:relationships];
}

static MADStoreEntity *Element(NSString *name, NSArray *attributes, NSArray *relationships) {
	return [MADStoreEntity subentityWithName:name
									  parent:@"RptqDocumentElement"
								  attributes:attributes
							   relationships:relationships];
}

/// The whole model, transcribed entity by entity from `MAD 3.xcdatamodel`.
static NSArray<MADStoreEntity *> *MADStoreEntityDescriptors(void) {
	static NSArray<MADStoreEntity *> *descriptors = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableArray *entities = [NSMutableArray arrayWithCapacity:33];

		#pragma mark Schema part

		[entities addObject:Table(@"RptqDatabase", @[
			TextOpt(@"databaseDriverType"),
			IntOpt(@"databaseDriverTypeEnum"),
			Int(@"identifier"),
		], @[
			ToMany(@"hasQueries", @"RptqQuery", @"inDatabase"),
			ToMany(@"hasTables", @"RptqDatabaseSchemaTable", @"inDatabase"),
			ToOne(@"ownedByQueryAsStaticResource", @"RptqDocument", @"hasDatabaseSchemas", YES),
			ToOne(@"ownedByUser", @"RptqDatabaseCredentals", @"inDatabase", NO),
		])];

		// The model names this attribute `dbkey`; the Rptq header calls it `key`, and the
		// header is the contract.  Nothing reads it today, so the two cannot be reconciled
		// by observation -- the fidelity test carries the exception.
		[entities addObject:Table(@"RptqDatabaseCredentals", @[
			TextOpt(@"driverID"),
			Int(@"identifier"),
			IntOpt(@"inUse"),
			TextOpt(@"dbname"),
			TextOpt(@"host"),
			IntOpt(@"port"),
			TextOpt(@"server"),
			TextOpt(@"domain"),
			TextOpt(@"key"),
			TextOpt(@"url"),
		], @[
			ToOne(@"inDatabase", @"RptqDatabase", @"ownedByUser", YES),
		])];

		[entities addObject:Table(@"RptqDatabaseSchemaTable", @[
			Int(@"identifier"),
			Text(@"name"),
			IntOpt(@"queryable"),
		], @[
			ToManyOrdered(@"hasFields", @"RptqDatabaseSchemaField", @"inTable"),
			ToOne(@"inDatabase", @"RptqDatabase", @"hasTables", YES),
			ToManyOrdered(@"inQueryTable", @"RptqQueryTable", @"databaseSchemaTable"),
		])];

		[entities addObject:Table(@"RptqDatabaseSchemaField", @[
			TextOpt(@"name"),
			IntOpt(@"primaryKey"),
			IntOpt(@"dataType"),
			IntOpt(@"dataTypeNative"),
			IntOpt(@"decimals"),
			IntOpt(@"width"),
			Int(@"identifier"),
		], @[
			ToOne(@"inTable", @"RptqDatabaseSchemaTable", @"hasFields", YES),
			ToMany(@"inQueryField", @"RptqQueryField", @"databaseSchemaField"),
			FieldSelectedByQueries(),
		])];

		#pragma mark Query part

		[entities addObject:Table(@"RptqQuery", @[
			TextOpt(@"cachedText"),
			Int(@"identifier"),
			Int(@"override"),
			TextOpt(@"overrideText"),
		], @[
			QuerySelectsFields(),
			ToMany(@"hasQueryGroups", @"RptqQueryGroup", @"inQuery"),
			ToMany(@"hasQueryLinks", @"RptqQueryLinks", @"inQuery"),
			ToMany(@"hasQueryPredicate", @"RptqQueryPredicate", @"inQuery"),
			ToOne(@"hasQuerySort", @"RptqQuerySort", @"inQuery", NO),
			ToMany(@"hasQueryTables", @"RptqQueryTable", @"inQuery"),
			ToOne(@"inDatabase", @"RptqDatabase", @"hasQueries", YES),
		])];

		[entities addObject:Table(@"RptqQueryTable", @[
			TextOpt(@"alias"),
			IntOpt(@"dropIndex"),
			Int(@"identifier"),
		], @[
			ToOne(@"databaseSchemaTable", @"RptqDatabaseSchemaTable", @"inQueryTable", YES),
			ToMany(@"hasQueryFields", @"RptqQueryField", @"inQueryTable"),
			ToOne(@"inQuery", @"RptqQuery", @"hasQueryTables", YES),
		])];

		[entities addObject:Table(@"RptqQueryField", @[
			Int(@"identifier"),
		], @[
			ToOne(@"databaseSchemaField", @"RptqDatabaseSchemaField", @"inQueryField", YES),
			ToMany(@"inAggregateObject", @"RptqDocumentElementAggregate", @"aggregateField"),
			ToMany(@"inBarcodeField1", @"RptqDocumentElementBarcode", @"referencesField1"),
			ToMany(@"inBarcodeField2", @"RptqDocumentElementBarcode", @"referencesField2"),
			ToMany(@"inDataObject", @"RptqDocumentElementLabelDataField", @"referencesQueryField"),
			ToMany(@"inQueryGroup", @"RptqQueryGroup", @"hasField"),
			ToMany(@"inQueryLinkLeft", @"RptqQueryLinks", @"hasLeftField"),
			ToMany(@"inQueryLinkRight", @"RptqQueryLinks", @"hasRightField"),
			ToMany(@"inQueryPredicateLeft", @"RptqQueryPredicate", @"hasLeftField"),
			ToMany(@"inQueryPredicateRight", @"RptqQueryPredicate", @"hasRightField"),
			ToMany(@"inQuerySort", @"RptqQuerySort", @"hasField"),
			ToOne(@"inQueryTable", @"RptqQueryTable", @"hasQueryFields", YES),
		])];

		[entities addObject:Table(@"RptqQueryLinks", @[
			TextOpt(@"fieldLeftID"),
			TextOpt(@"fieldRightID"),
			Int(@"identifier"),
			TextOpt(@"tableLeftID"),
			TextOpt(@"tableRightID"),
			IntOpt(@"type"),
		], @[
			ToOne(@"hasLeftField", @"RptqQueryField", @"inQueryLinkLeft", YES),
			ToOne(@"hasRightField", @"RptqQueryField", @"inQueryLinkRight", YES),
			ToOne(@"inQuery", @"RptqQuery", @"hasQueryLinks", YES),
		])];

		[entities addObject:Table(@"RptqQueryPredicate", @[
			IntOpt(@"comparson"),
			Int(@"identifier"),
			TextOpt(@"leftFieldID"),
			TextOpt(@"rigthFieldID"),
		], @[
			ToOne(@"hasLeftField", @"RptqQueryField", @"inQueryPredicateLeft", YES),
			ToOne(@"hasRightField", @"RptqQueryField", @"inQueryPredicateRight", YES),
			ToOne(@"inQuery", @"RptqQuery", @"hasQueryPredicate", YES),
		])];

		[entities addObject:Table(@"RptqQuerySort", @[
			Int(@"identifier"),
			IntOpt(@"ascending"),
		], @[
			ToOne(@"hasField", @"RptqQueryField", @"inQuerySort", YES),
			ToOne(@"inQuery", @"RptqQuery", @"hasQuerySort", YES),
		])];

		[entities addObject:Table(@"RptqQueryGroup", @[
			Int(@"identifier"),
			IntOpt(@"sort"),
			IntOpt(@"weight"),
		], @[
			ToOne(@"hasField", @"RptqQueryField", @"inQueryGroup", YES),
			ToMany(@"hasSection", @"RptqDocumentSection", @"inGroup"),
			ToOne(@"inQuery", @"RptqQuery", @"hasQueryGroups", YES),
		])];

		#pragma mark Layout part

		[entities addObject:Table(@"RptqDocument", @[
			Int(@"identifier"),
			IntOpt(@"papersize"),
		], @[
			ToMany(@"hasDatabaseSchemas", @"RptqDatabase", @"ownedByQueryAsStaticResource"),
			ToOne(@"hasDetailSection", @"RptqDocumentSection", @"inReport", NO),
			ToOne(@"hasPageFooterSection", @"RptqDocumentSection", @"inReportPageFooter", NO),
			ToOne(@"hasPageHeaderSection", @"RptqDocumentSection", @"inReportPageHeader", NO),
			ToOne(@"hasReportFooterSection", @"RptqDocumentSection", @"inReportReportFooter", NO),
			ToOne(@"hasReportHeaderSection", @"RptqDocumentSection", @"inReportReportHeader", NO),
		])];

		[entities addObject:Table(@"RptqDocumentSection", @[
			IntOpt(@"identifier"),
			Int(@"numberOfRows"),
			IntOpt(@"type"),
			IntOpt(@"wrappingStyle"),
			IntOpt(@"visibility"),
			RealOpt(@"height"),
			RealOpt(@"layoutHeight"),
		], @[
			ToManyOrdered(@"hasRows", @"RptqDocumentSectionRows", @"inSection"),
			ToOne(@"inGroup", @"RptqQueryGroup", @"hasSection", YES),
			ToOne(@"inReport", @"RptqDocument", @"hasDetailSection", YES),
			ToOne(@"inReportPageFooter", @"RptqDocument", @"hasPageFooterSection", YES),
			ToOne(@"inReportPageHeader", @"RptqDocument", @"hasPageHeaderSection", YES),
			ToOne(@"inReportReportFooter", @"RptqDocument", @"hasReportFooterSection", YES),
			ToOne(@"inReportReportHeader", @"RptqDocument", @"hasReportHeaderSection", YES),
		])];

		[entities addObject:Table(@"RptqDocumentSectionRows", @[
			RealOpt(@"layoutHeight"),
			Int(@"rowNumber"),
		], @[
			ToOne(@"inSection", @"RptqDocumentSection", @"hasRows", YES),
			ToManyOrdered(@"hasObjects", @"RptqDocumentElement", @"inSectionRow"),
		])];

		// The element family shares one table and is told apart by its `kind` column,
		// exactly as Core Data tells the subclasses apart by Z_ENT.
		MADStoreEntity *element = Table(@"RptqDocumentElement", @[
			Int(@"identifier"),
			IntOpt(@"type"),
			IntOpt(@"dropIndex"),
			RealOpt(@"fontsize"),
			TextOpt(@"fontname"),
			RealOpt(@"backgroundColorR"),
			RealOpt(@"backgroundColorG"),
			RealOpt(@"backgroundColorB"),
			RealOpt(@"backgroundColorA"),
			RealOpt(@"foregroundColorR"),
			RealOpt(@"foregroundColorG"),
			RealOpt(@"foregroundColorB"),
			RealOpt(@"foregroundColorA"),
		], @[
			ToOne(@"inSectionRow", @"RptqDocumentSectionRows", @"hasObjects", YES),
			ToOne(@"dropPoint", @"RptqPoint", @"inElement", NO),
			ToOne(@"padding", @"RptqDirectionalAsymmetry", @"inElementPadding", NO),
			ToOne(@"rect", @"RptqRect", @"inElement", NO),
			ToOne(@"margin", @"RptqDirectionalAsymmetry", @"inElementMargin", NO),
			ToOne(@"border", @"RptqBorder", @"inElement", NO),
			ToOne(@"textStyle", @"RptqTextStyle", @"inElement", NO),
			ToOne(@"alignment", @"RptqAlignment", @"inElement", NO),
			ToOne(@"numericFormat", @"RptqNumericFormat", @"inElement", NO),
		]);
		element.subentities = @[
			Element(@"RptqDocumentElementAggregate", @[
				IntOpt(@"groupNumber"),
				IntOpt(@"groupType"),
				IntOpt(@"functionType"),
			], @[
				ToOne(@"aggregateField", @"RptqQueryField", @"inAggregateObject", YES),
				ToOne(@"aggregateFunction", @"RptqDocumentElementFormula", @"includedInAggregateObject", NO),
			]),
			Element(@"RptqDocumentElementBarcode", @[
				IntOpt(@"add2dComponent"),
				IntOpt(@"humanReadable"),
				IntOpt(@"showErrorMessage"),
				IntOpt(@"useStaticInput1"),
				IntOpt(@"useStaticInput2"),
				RealOpt(@"scale"),
				IntOpt(@"barcodeType"),
				IntOpt(@"barcodeBorderStyle"),
				IntOpt(@"barcodeBorderType"),
				IntOpt(@"barcodeBorderWidth"),
				IntOpt(@"barcodeHeight"),
				IntOpt(@"option1"),
				IntOpt(@"option2"),
				IntOpt(@"option3"),
				IntOpt(@"whitespaceWidth"),
				IntOpt(@"inputMode"),
				TextOpt(@"inputField1"),
				TextOpt(@"inputField2"),
				TextOpt(@"inputStatic1"),
				TextOpt(@"inputStatic2"),
			], @[
				ToOne(@"referencesField1", @"RptqQueryField", @"inBarcodeField1", YES),
				ToOne(@"referencesField2", @"RptqQueryField", @"inBarcodeField2", YES),
			]),
			Element(@"RptqDocumentElementChart", @[], @[]),
			Element(@"RptqDocumentElementFormula", @[
				IntOpt(@"functionScope"),
				IntOpt(@"functionType"),
				IntOpt(@"inputType"),
				TextOpt(@"name"),
				IntOpt(@"resultType"),
				TextOpt(@"source"),
			], @[
				ToOne(@"includedInAggregateObject", @"RptqDocumentElementAggregate", @"aggregateFunction", YES),
			]),
			Element(@"RptqDocumentElementGroupKey", @[
				IntOpt(@"groupNumber"),
			], @[]),
			Element(@"RptqDocumentElementImage", @[
				BlobOpt(@"image"),
			], @[]),
			Element(@"RptqDocumentElementLabel", @[
				TextOpt(@"text"),
			], @[]),
			Element(@"RptqDocumentElementLabelDataField", @[
				TextOpt(@"fieldID"),
				TextOpt(@"tableID"),
				TextOpt(@"text"),
			], @[
				ToOne(@"referencesQueryField", @"RptqQueryField", @"inDataObject", YES),
			]),
			Element(@"RptqDocumentElementLabelLink", @[
				TextOpt(@"text"),
				TextOpt(@"url"),
			], @[]),
		];
		[entities addObject:element];

		[entities addObject:Table(@"RptqAlignment", @[
			Int(@"horizontal"),
			Int(@"vertical"),
		], @[
			ToOne(@"inElement", @"RptqDocumentElement", @"alignment", YES),
		])];

		[entities addObject:Table(@"RptqBorder", @[], @[
			ToOne(@"inElement", @"RptqDocumentElement", @"border", YES),
			ToOne(@"style", @"RptqDirectionalProperty", @"inBorder", NO),
			ToOne(@"width", @"RptqDirectionalAsymmetry", @"inBorder", NO),
		])];

		[entities addObject:Table(@"RptqDirectionalAsymmetry", @[
			Real(@"top"),
			Real(@"bottom"),
			Real(@"left"),
			Real(@"right"),
		], @[
			ToOne(@"inBorder", @"RptqBorder", @"width", YES),
			ToOne(@"inElementMargin", @"RptqDocumentElement", @"margin", YES),
			ToOne(@"inElementPadding", @"RptqDocumentElement", @"padding", YES),
		])];

		[entities addObject:Table(@"RptqDirectionalProperty", @[
			Int(@"top"),
			Int(@"bottom"),
			Int(@"left"),
			Int(@"right"),
		], @[
			ToOne(@"inBorder", @"RptqBorder", @"style", YES),
		])];

		[entities addObject:Table(@"RptqNumericFormat", @[
			TextOpt(@"locale"),
			Int(@"enabled"),
			Int(@"decimalCount"),
		], @[
			ToOne(@"inElement", @"RptqDocumentElement", @"numericFormat", YES),
		])];

		[entities addObject:Table(@"RptqPoint", @[
			Real(@"x"),
			Real(@"y"),
		], @[
			ToOne(@"inElement", @"RptqDocumentElement", @"dropPoint", YES),
			ToOne(@"inRect", @"RptqRect", @"origin", YES),
		])];

		[entities addObject:Table(@"RptqRect", @[], @[
			ToOne(@"inElement", @"RptqDocumentElement", @"rect", YES),
			ToOne(@"origin", @"RptqPoint", @"inRect", NO),
			ToOne(@"size", @"RptqSize", @"inRect", NO),
		])];

		[entities addObject:Table(@"RptqSize", @[
			Real(@"width"),
			Real(@"height"),
		], @[
			ToOne(@"inRect", @"RptqRect", @"size", YES),
		])];

		[entities addObject:Table(@"RptqTextStyle", @[
			Int(@"strikethrough"),
			Int(@"underline"),
			Int(@"italic"),
			Int(@"bold"),
		], @[
			ToOne(@"inElement", @"RptqDocumentElement", @"textStyle", YES),
		])];

		descriptors = entities;
	});
	return descriptors;
}

#pragma mark - Schema

@interface MADStoreSchema ()
@property (nonatomic, copy) NSArray<MADStoreEntity *> *entities;
@property (nonatomic, copy) NSArray<MADStoreEntity *> *tables;
@property (nonatomic, copy) NSDictionary<NSString *, MADStoreEntity *> *byName;
@property (nonatomic, copy) NSDictionary<NSString *, MADStoreEntity *> *byTable;
@end

@implementation MADStoreSchema

+ (instancetype)sharedSchema {
	static MADStoreSchema *schema = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		schema = [MADStoreSchema new];
	});
	return schema;
}

- (instancetype)init {
	self = [super init];
	if (!self) return nil;

	// Flatten the descriptors: the element subentities hang off their table's
	// descriptor, but they are entities in their own right everywhere else.
	NSMutableArray<MADStoreEntity *> *all = [NSMutableArray arrayWithCapacity:33];
	for (MADStoreEntity *entity in MADStoreEntityDescriptors()) {
		[all addObject:entity];
		[all addObjectsFromArray:entity.subentities];
	}
	NSMutableDictionary<NSString *, MADStoreEntity *> *byName = [NSMutableDictionary dictionaryWithCapacity:all.count];
	for (MADStoreEntity *entity in all) byName[entity.name] = entity;

	// Resolve each entity to its table, then let the table adopt the subentities that
	// share it.
	NSMutableArray<MADStoreEntity *> *tables = [NSMutableArray array];
	for (MADStoreEntity *entity in all) {
		if (entity.parentName) {
			MADStoreEntity *parent = byName[entity.parentName];
			NSAssert(parent != nil, @"Subentity %@ names an unknown parent %@", entity.name, entity.parentName);
			entity.table = parent.table ?: parent.name;
		} else {
			entity.table = entity.name;
			[tables addObject:entity];
		}
	}
	for (MADStoreEntity *table in tables) {
		NSMutableArray<MADStoreEntity *> *subentities = [NSMutableArray array];
		for (MADStoreEntity *entity in all) {
			if (entity.parentName && [entity.table isEqualToString:table.name]) {
				[subentities addObject:entity];
			}
		}
		table.subentities = subentities;
	}

	// An entity carries a model identifier when the model gives it one.  The tables
	// that do not are the value-type satellites and RptqDocumentSectionRows; those
	// rows take a store-assigned surrogate.
	for (MADStoreEntity *entity in all) {
		BOOL hasIdentifier = NO;
		for (MADStoreEntity *walk = entity; walk && !hasIdentifier; walk = walk.parentName ? byName[walk.parentName] : nil) {
			for (MADStoreAttribute *attribute in walk.attributes) {
				if ([attribute.name isEqualToString:@"identifier"]) { hasIdentifier = YES; break; }
			}
		}
		entity.hasModelIdentifier = hasIdentifier;
	}

	// A `position` column belongs to the child end of an ordered to-many.  This walks
	// the parent chain through the local dictionary: -allRelationships would reach
	// back into +sharedSchema, which is still inside its dispatch_once.
	MADStoreRelationship *(^findRelationship)(MADStoreEntity *, NSString *) =
	^MADStoreRelationship *(MADStoreEntity *entity, NSString *name) {
		while (entity) {
			MADStoreRelationship *found = [entity relationshipNamed:name];
			if (found) return found;
			entity = entity.parentName ? byName[entity.parentName] : nil;
		}
		return nil;
	};
	NSMutableArray<MADStoreRelationship *> *(^relationshipsOf)(MADStoreEntity *) =
	^NSMutableArray<MADStoreRelationship *> *(MADStoreEntity *entity) {
		NSMutableArray<MADStoreRelationship *> *result = [NSMutableArray array];
		for (MADStoreEntity *walk = entity; walk; walk = walk.parentName ? byName[walk.parentName] : nil) {
			[result addObjectsFromArray:walk.relationships];
		}
		return result;
	};

	for (MADStoreEntity *entity in all) {
		__block BOOL positioned = NO;
		for (MADStoreRelationship *relationship in relationshipsOf(entity)) {
			if (relationship.isToMany) continue;
			MADStoreEntity *destination = byName[relationship.destination];
			MADStoreRelationship *inverse = findRelationship(destination, relationship.inverse);
			if (inverse.isToMany && inverse.isOrdered) { positioned = YES; break; }
		}
		entity.hasPositionColumn = positioned;
	}

	self.entities = all;
	self.tables = tables;
	self.byName = byName;

	NSMutableDictionary<NSString *, MADStoreEntity *> *byTable = [NSMutableDictionary dictionaryWithCapacity:tables.count];
	for (MADStoreEntity *table in tables) byTable[table.name] = table;
	self.byTable = byTable;

	// Warm every entity's flattened arrays and name indexes now, so the first
	// property read cannot race and the render path never allocates a lookup.
	for (MADStoreEntity *entity in all) {
		[entity warmLookupsWithNames:byName];
	}

	return self;
}

- (MADStoreEntity *)entityNamed:(NSString *)name { return self.byName[name]; }

- (MADStoreEntity *)entityForTable:(NSString *)table { return self.byTable[table]; }

- (BOOL)entityName:(NSString *)name belongsToPart:(MADStorePart)part {
	MADStoreEntity *entity = self.byName[name];
	if (!entity) return NO;
	NSString *table = entity.table;
	switch (part) {
		case MADStorePartSchema:
			return [table isEqualToString:@"RptqDatabase"]
				|| [table isEqualToString:@"RptqDatabaseCredentals"]
				|| [table isEqualToString:@"RptqDatabaseSchemaTable"]
				|| [table isEqualToString:@"RptqDatabaseSchemaField"];
		case MADStorePartQuery:
			return [table isEqualToString:@"RptqQuery"]
				|| [table isEqualToString:@"RptqQueryTable"]
				|| [table isEqualToString:@"RptqQueryField"]
				|| [table isEqualToString:@"RptqQueryLinks"]
				|| [table isEqualToString:@"RptqQueryGroup"]
				|| [table isEqualToString:@"RptqQueryPredicate"]
				|| [table isEqualToString:@"RptqQuerySort"];
		case MADStorePartLayout:
			return [table isEqualToString:@"RptqDocument"]
				|| [table isEqualToString:@"RptqDocumentSection"]
				|| [table isEqualToString:@"RptqDocumentSectionRows"]
				|| [table isEqualToString:@"RptqDocumentElement"]
				|| [table isEqualToString:@"RptqAlignment"]
				|| [table isEqualToString:@"RptqBorder"]
				|| [table isEqualToString:@"RptqDirectionalAsymmetry"]
				|| [table isEqualToString:@"RptqDirectionalProperty"]
				|| [table isEqualToString:@"RptqNumericFormat"]
				|| [table isEqualToString:@"RptqPoint"]
				|| [table isEqualToString:@"RptqRect"]
				|| [table isEqualToString:@"RptqSize"]
				|| [table isEqualToString:@"RptqTextStyle"];
	}
	return NO;
}

#pragma mark DDL

static NSString *MADStoreSQLType(MADStoreValueType type) {
	switch (type) {
		case MADStoreValueTypeInteger: return @"INTEGER";
		case MADStoreValueTypeReal: return @"REAL";
		case MADStoreValueTypeText: return @"TEXT";
		case MADStoreValueTypeBlob: return @"BLOB";
	}
	return @"BLOB";
}

static NSString *MADStoreColumnDefinition(MADStoreAttribute *attribute, BOOL forceNullable) {
	if (forceNullable || attribute.isOptional) {
		return [[NSString alloc] initWithFormat:@"\t\"%@\" %@", attribute.name, MADStoreSQLType(attribute.type)];
	}
	return [[NSString alloc] initWithFormat:@"\t\"%@\" %@ NOT NULL", attribute.name, MADStoreSQLType(attribute.type)];
}

- (NSString *)createSchemaSQL {
	NSMutableString *sql = [NSMutableString string];

	for (MADStoreEntity *table in self.tables) {
		NSMutableArray<NSString *> *columns = [NSMutableArray array];
		[columns addObject:[[NSString alloc] initWithFormat:@"\t\"identifier\" INTEGER PRIMARY KEY"]];

		if (table.subentities.count > 0) {
			[columns addObject:[[NSString alloc] initWithFormat:@"\t\"kind\" TEXT NOT NULL"]];
		}

		NSMutableSet<NSString *> *emitted = [NSMutableSet setWithCapacity:table.allAttributes.count];
		for (MADStoreAttribute *attribute in table.allAttributes) {
			// The model's `identifier` attribute is the row key above, not a column.
			if ([attribute.name isEqualToString:@"identifier"]) continue;
			[emitted addObject:attribute.name];
			[columns addObject:MADStoreColumnDefinition(attribute, NO)];
		}

		// A subentity's columns are shared by every kind in the table, so they are
		// nullable whatever the attribute itself says.  Two subentities may name the
		// same attribute -- functionType is on both the aggregate and the formula --
		// and the table carries it once.
		for (MADStoreEntity *subentity in table.subentities) {
			for (MADStoreAttribute *attribute in subentity.attributes) {
				if ([emitted containsObject:attribute.name]) continue;
				[emitted addObject:attribute.name];
				[columns addObject:MADStoreColumnDefinition(attribute, YES)];
			}
		}

		NSMutableArray<MADStoreRelationship *> *relationships = [NSMutableArray arrayWithArray:table.allRelationships];
		for (MADStoreEntity *subentity in table.subentities) {
			[relationships addObjectsFromArray:subentity.relationships];
		}

		NSMutableSet<NSString *> *emittedColumns = [NSMutableSet set];
		for (MADStoreRelationship *relationship in relationships) {
			// Many-to-many relationships store their edges in a join table, emitted
			// after every table; a derived to-one stores its foreign key on the far side.
			if (!relationship.ownsForeignKey) continue;
			if ([emittedColumns containsObject:relationship.column]) continue;
			[emittedColumns addObject:relationship.column];
			MADStoreEntity *destination = self.byName[relationship.destination];
			[columns addObject:[[NSString alloc] initWithFormat:@"\t\"%@\" INTEGER REFERENCES \"%@\" (\"identifier\")",
								relationship.column, destination.table ?: destination.name]];
		}

		if (table.hasPositionColumn) {
			[columns addObject:[[NSString alloc] initWithFormat:@"\t\"%@\" INTEGER", MADStorePositionColumn]];
		}

		[sql appendFormat:@"CREATE TABLE IF NOT EXISTS \"%@\" (\n%@\n);\n", table.name, [columns componentsJoinedByString:@",\n"]];

		if (table.subentities.count > 0) {
			[sql appendFormat:@"CREATE INDEX IF NOT EXISTS \"idx_%@_kind\" ON \"%@\" (\"kind\");\n", table.name, table.name];
		}
		NSMutableSet<NSString *> *indexed = [NSMutableSet set];
		for (MADStoreRelationship *relationship in relationships) {
			if (!relationship.ownsForeignKey || [indexed containsObject:relationship.column]) continue;
			[indexed addObject:relationship.column];
			[sql appendFormat:@"CREATE INDEX IF NOT EXISTS \"idx_%@_%@\" ON \"%@\" (\"%@\");\n",
				table.name, relationship.column, table.name, relationship.column];
		}
		if (table.hasPositionColumn) {
			[sql appendFormat:@"CREATE INDEX IF NOT EXISTS \"idx_%@_%@\" ON \"%@\" (\"%@\");\n",
				table.name, MADStorePositionColumn, table.name, MADStorePositionColumn];
		}
		[sql appendString:@"\n"];
	}

	// Join tables, gathered from the many-to-many relationships.  Each side names
	// the same table and its own column, so both columns and their indexes come out
	// of one pass.
	NSMutableDictionary<NSString *, NSMutableArray<MADStoreRelationship *> *> *joinTables = [NSMutableDictionary dictionary];
	for (MADStoreEntity *entity in self.entities) {
		for (MADStoreRelationship *relationship in entity.relationships) {
			if (!relationship.joinTable) continue;
			NSMutableArray *sides = joinTables[relationship.joinTable];
			if (!sides) { sides = [NSMutableArray array]; joinTables[relationship.joinTable] = sides; }
			[sides addObject:relationship];
		}
	}
	for (NSString *joinTable in joinTables) {
		NSArray<MADStoreRelationship *> *sides = joinTables[joinTable];
		NSMutableArray<NSString *> *columns = [NSMutableArray array];
		NSMutableArray<NSString *> *names = [NSMutableArray array];
		for (MADStoreRelationship *side in sides) {
			[columns addObject:[[NSString alloc] initWithFormat:@"\t\"%@\" INTEGER NOT NULL", side.joinColumn]];
			[names addObject:[[NSString alloc] initWithFormat:@"\"%@\"", side.joinColumn]];
		}
		[sql appendFormat:@"CREATE TABLE IF NOT EXISTS \"%@\" (\n%@,\n\tPRIMARY KEY (%@)\n);\n",
			joinTable, [columns componentsJoinedByString:@",\n"], [names componentsJoinedByString:@", "]];
		for (MADStoreRelationship *side in sides) {
			[sql appendFormat:@"CREATE INDEX IF NOT EXISTS \"idx_%@_%@\" ON \"%@\" (\"%@\");\n",
				joinTable, side.joinColumn, joinTable, side.joinColumn];
		}
		[sql appendString:@"\n"];
	}

	return sql;
}

@end
