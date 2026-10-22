//
//  MADSQLStatementResolver.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "MADSQLStatementResolver.h"

#import "MADSQLCompileError.h"
#import "MADSQLStatement.h"

#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

@interface MADSQLStatementResolver ()

@property (nonatomic, strong) MADSQLStatement *statement;
@property (nonatomic, strong) RptqDatabase *database;

// The schema, lowercase: table name -> (lowercase field name -> field).
@property (nonatomic, copy) NSDictionary<NSString *, RptqDatabaseSchemaTable *> *tableByName;
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary<NSString *, RptqDatabaseSchemaField *> *> *fieldsByTable;
// The FROM set's resolution: lowercase alias -> the plan table it names.
@property (nonatomic, strong) NSMutableDictionary<NSString *, MADSQLPlanTable *> *planTableByAlias;
// Every plan table in the FROM set's order.
@property (nonatomic, strong) NSMutableArray<MADSQLPlanTable *> *planTables;

@end

@implementation MADSQLPlanTable
@end

@implementation MADSQLPlanLink
@end

@implementation MADSQLPlanPredicate
@end

@implementation MADSQLPlanGroup
@end

@implementation MADSQLQueryPlan
@end

@implementation MADSQLStatementResolver

- (instancetype)initWithStatement:(MADSQLStatement *)statement
						 database:(RptqDatabase *)database {
	self = [super init];
	if (!self) return nil;
	_statement = statement;
	_database = database;

	NSMutableDictionary<NSString *, RptqDatabaseSchemaTable *> *tableByName = [NSMutableDictionary dictionary];
	NSMutableDictionary<NSString *, NSDictionary<NSString *, RptqDatabaseSchemaField *> *> *fieldsByTable = [NSMutableDictionary dictionary];
	for (RptqDatabaseSchemaTable *table in database.hasTables) {
		if (table.name == nil) continue;
		tableByName[table.name.lowercaseString] = table;

		NSMutableDictionary<NSString *, RptqDatabaseSchemaField *> *fields = [NSMutableDictionary dictionary];
		for (RptqDatabaseSchemaField *field in table.hasFields) {
			if (field.name == nil) continue;
			fields[field.name.lowercaseString] = field;
		}
		fieldsByTable[table.name.lowercaseString] = fields;
	}
	_tableByName = tableByName;
	_fieldsByTable = fieldsByTable;

	return self;
}

#pragma mark - The plan

- (MADSQLQueryPlan *)resolveWithError:(NSError * __autoreleasing *)error {
	self.planTableByAlias = [NSMutableDictionary dictionary];
	self.planTables = [NSMutableArray array];

	NSMutableArray<MADSQLPlanLink *> *links = [NSMutableArray arrayWithCapacity:self.statement.joins.count];
	NSMutableArray<MADSQLPlanPredicate *> *predicates = [NSMutableArray arrayWithCapacity:self.statement.predicates.count];
	NSMutableArray<MADSQLPlanGroup *> *groups = [NSMutableArray arrayWithCapacity:self.statement.groupByColumns.count];

	// The FROM set: one plan table per item, in the written order, with the copy
	// index the alias's digits name.
	NSMutableDictionary<NSString *, NSNumber *> *nextDropIndex = [NSMutableDictionary dictionary];
	for (MADSQLFromItem *item in self.statement.fromItems) {
		RptqDatabaseSchemaTable *schemaTable = self.tableByName[item.tableName.lowercaseString];
		if (schemaTable == nil) {
			return [self fail:MADSQLCompileErrorUnknownTable line:item.line column:item.column
					   message:[[NSString alloc] initWithFormat:@"Unknown table '%@'.", item.tableName] error:error];
		}

		NSString *alias = item.alias != nil ? item.alias : item.tableName;
		NSInteger dropIndex = [self dropIndexForAlias:alias tableName:schemaTable.name];
		if (dropIndex < 0) {
			return [self fail:MADSQLCompileErrorUnsupportedAlias line:item.aliasLine column:item.aliasColumn
					   message:[[NSString alloc] initWithFormat:@"'%@' is not a copy of '%@' the model can name.", alias, schemaTable.name] error:error];
		}

		// The generator numbers copies 0, 1, ... in the FROM set's order; a copy
		// index out of that sequence would alias a table the generator writes
		// under another name.
		NSString *tableKey = schemaTable.name.lowercaseString;
		NSNumber *expected = nextDropIndex[tableKey] ?: @0;
		if (dropIndex != expected.integerValue) {
			return [self fail:MADSQLCompileErrorUnsupportedAlias line:item.aliasLine column:item.aliasColumn
					   message:[[NSString alloc] initWithFormat:@"'%@' skips the copy order; the model names copies '%@0', '%@1', ... in the FROM order.", alias, schemaTable.name, schemaTable.name] error:error];
		}
		nextDropIndex[tableKey] = @(dropIndex + 1);

		MADSQLPlanTable *planTable = [MADSQLPlanTable new];
		planTable.schemaTable = schemaTable;
		planTable.alias = alias;
		planTable.dropIndex = dropIndex;
		[self.planTables addObject:planTable];
		self.planTableByAlias[alias.lowercaseString] = planTable;
	}

	// The joins: the ON condition's sides resolve to plan tables and schema
	// fields.
	for (MADSQLJoinClause *join in self.statement.joins) {
		MADSQLPlanTable *leftTable = [self planTableForColumn:join.leftColumn];
		MADSQLPlanTable *rightTable = [self planTableForColumn:join.rightColumn];
		if (leftTable == nil || rightTable == nil) {
			return [self fail:MADSQLCompileErrorUnknownColumn line:join.leftColumn.line column:join.leftColumn.column
					   message:@"The ON condition's columns do not resolve." error:error];
		}

		MADSQLPlanLink *link = [MADSQLPlanLink new];
		link.type = join.type;
		link.leftTable = leftTable;
		link.leftField = [self fieldNameForColumn:join.leftColumn onTable:leftTable];
		link.rightTable = rightTable;
		link.rightField = [self fieldNameForColumn:join.rightColumn onTable:rightTable];
		[links addObject:link];
	}

	// The predicates: each side is a plan field or a literal.
	for (MADSQLPredicateTerm *predicate in self.statement.predicates) {
		MADSQLPlanPredicate *planPredicate = [MADSQLPlanPredicate new];
		planPredicate.operator = predicate.operator;

		if (predicate.leftColumn != nil) {
			planPredicate.leftTable = [self planTableForColumn:predicate.leftColumn];
			planPredicate.leftField = [self fieldNameForColumn:predicate.leftColumn onTable:planPredicate.leftTable];
		} else {
			planPredicate.leftLiteral = predicate.leftLiteral.text;
		}
		if (predicate.rightColumn != nil) {
			planPredicate.rightTable = [self planTableForColumn:predicate.rightColumn];
			planPredicate.rightField = [self fieldNameForColumn:predicate.rightColumn onTable:planPredicate.rightTable];
		} else {
			planPredicate.rightLiteral = predicate.rightLiteral.text;
		}
		[predicates addObject:planPredicate];
	}

	// The groups: each GROUP BY column's sort comes from the ORDER BY term that
	// names the same field, ascending when nothing does.
	for (MADSQLColumnReference *column in self.statement.groupByColumns) {
		MADSQLPlanTable *planTable = [self planTableForColumn:column];
		if (planTable == nil) {
			return [self fail:MADSQLCompileErrorUnknownColumn line:column.line column:column.column
					   message:@"A GROUP BY column does not resolve." error:error];
		}

		MADSQLPlanGroup *group = [MADSQLPlanGroup new];
		group.table = planTable;
		group.field = [self fieldNameForColumn:column onTable:planTable];
		group.sortOrder = MADSortOrderAccending;

		for (MADSQLOrderTerm *term in self.statement.orderByTerms) {
			MADSQLPlanTable *termTable = [self planTableForColumn:term.column];
			if (termTable == planTable &&
				[[self fieldNameForColumn:term.column onTable:termTable].lowercaseString isEqualToString:group.field.lowercaseString]) {
				group.sortOrder = term.isAscending ? MADSortOrderAccending : MADSortOrderDecending;
				break;
			}
		}
		[groups addObject:group];
	}

	MADSQLQueryPlan *plan = [MADSQLQueryPlan new];
	plan.sourceText = self.statement.sourceText;
	plan.tables = self.planTables;
	plan.links = links;
	plan.predicates = predicates;
	plan.groups = groups;
	return plan;
}

#pragma mark - Resolution

// The copy index an alias names: 0 for the table's own name, the digits for
// `name0`, `name1`, ...; -1 for anything else.
- (NSInteger)dropIndexForAlias:(NSString *)alias tableName:(NSString *)tableName {
	NSString *lowerName = tableName.lowercaseString;
	NSString *lowerAlias = alias.lowercaseString;
	if ([lowerAlias isEqualToString:lowerName]) return 0;
	if (lowerAlias.length <= lowerName.length || ![lowerAlias hasPrefix:lowerName]) return -1;
	NSString *digits = [lowerAlias substringFromIndex:lowerName.length];
	if (digits.length == 0 ||
		[digits rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location != NSNotFound) {
		return -1;
	}
	return digits.integerValue;
}

// The plan table a column names: its qualifier's alias when qualified, its
// unique FROM table when bare.  The parser already checked these; a nil here
// means the resolver could not bind what the parser accepted.
- (MADSQLPlanTable *)planTableForColumn:(MADSQLColumnReference *)column {
	if (column.table != nil) {
		return self.planTableByAlias[column.table.lowercaseString];
	}
	MADSQLPlanTable *match = nil;
	for (MADSQLPlanTable *planTable in self.planTables) {
		NSDictionary<NSString *, RptqDatabaseSchemaField *> *fields =
			self.fieldsByTable[planTable.schemaTable.name.lowercaseString];
		if (fields[column.name.lowercaseString] != nil) {
			if (match != nil) return nil;	// ambiguous
			match = planTable;
		}
	}
	return match;
}

// The schema field's name on the plan table, matched case-insensitively.
- (NSString *)fieldNameForColumn:(MADSQLColumnReference *)column onTable:(MADSQLPlanTable *)planTable {
	NSDictionary<NSString *, RptqDatabaseSchemaField *> *fields =
		self.fieldsByTable[planTable.schemaTable.name.lowercaseString];
	RptqDatabaseSchemaField *field = fields[column.name.lowercaseString];
	return field.name != nil ? field.name : column.name;
}

- (id)fail:(MADSQLCompileErrorCode)code line:(NSInteger)line column:(NSInteger)column
	message:(NSString *)message error:(NSError * __autoreleasing *)error {
	if (error) {
		*error = [MADSQLCompileError errorWithCode:code line:line column:column message:message];
	}
	return nil;
}

@end
