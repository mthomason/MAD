//
//  MADModelQueryLink.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADModelQueryLink.h"


#import <Foundation/NSArray.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSURL.h>

#import <MADFoundation/MADStringUtilities.h>

#import "MADTableFieldIdentifier.h"

#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqQueryLinks.h"

@interface MADModelQueryLink ()

@property (nonatomic, readwrite, strong) MADTableFieldIdentifier *leftFieldIdentifier;
@property (nonatomic, readwrite, strong) MADTableFieldIdentifier *rightFieldIdentifier;

@end

@implementation MADModelQueryLink

- (void)dealloc {
	_inQuery = nil;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
					   leftFieldID:(int64_t)leftFieldID
					   leftTableID:(int64_t)leftTableID
					  rightFieldID:(int64_t)rightFieldID
					  rightTableID:(int64_t)rightTableID {
	
	if (self = [self initWithIdentifier:identifier]) {
		
		MADTableFieldIdentifier *leftFieldIdentifier, *rightFieldIdentifier;
		
		leftFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: leftTableID
																	andFieldID: leftFieldID];
		self.leftFieldIdentifier = leftFieldIdentifier;
		
		rightFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: rightTableID
																	 andFieldID: rightFieldID];
		self.rightFieldIdentifier = rightFieldIdentifier;
		
	}
	return self;
}

- (instancetype)initWithRptqQueryLink:(RptqQueryLinks *)queryLink {
	
	if (self = [self initWithIdentifier:queryLink.identifier]) {
		
		MADTableFieldIdentifier *leftFieldIdentifier, *rightFieldIdentifier;
		
		leftFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: queryLink.hasLeftField.inQueryTable.identifier
																	andFieldID: queryLink.hasLeftField.identifier];
		self.leftFieldIdentifier = leftFieldIdentifier;
		
		rightFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: queryLink.hasRightField.inQueryTable.identifier
																	 andFieldID: queryLink.hasRightField.identifier];
		self.rightFieldIdentifier = rightFieldIdentifier;
		
	}
	return self;
}

- (BOOL)isAdjacentToQueryTable:(int64_t)queryTableID {
	return _leftFieldIdentifier.tableID == queryTableID || _rightFieldIdentifier.tableID == queryTableID;
}

- (NSSet <NSNumber *> *)tables {
	NSNumber *tableLeft = @(_leftFieldIdentifier.tableID),
			 *tableRight = @(_rightFieldIdentifier.tableID);
	NSSet *tables = [[NSSet alloc] initWithObjects: tableLeft,
													tableRight, nil];
	return tables;
}

- (NSNumber *)leftTableObjectID { return [self.leftFieldIdentifier tableObjectID]; }
- (NSNumber *)rightTableObjectID { return [self.rightFieldIdentifier tableObjectID]; }
- (NSNumber *)leftFieldObjectID { return [self.leftFieldIdentifier fieldObjectID]; }
- (NSNumber *)rightFieldObjectID { return [self.rightFieldIdentifier fieldObjectID]; }

- (int64_t)leftTableID { return [self.leftFieldIdentifier tableID]; }
- (int64_t)rightTableID { return [self.rightFieldIdentifier tableID]; }
- (int64_t)leftFieldID { return [self.leftFieldIdentifier fieldID]; }
- (int64_t)rightFieldID { return [self.rightFieldIdentifier fieldID]; }


@end
