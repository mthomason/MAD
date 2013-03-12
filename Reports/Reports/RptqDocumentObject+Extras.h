//
//  RptqDocumentObject+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObject_Extras_h
#define Reports_RptqDocumentObject_Extras_h

#import "RptqDocumentObject.h"
#import "MTProtocolCompare.h"
#import "MTProtocolLog.h"
#import "RptqDocumentObjectFactory.h"
#import "RptqDocument.h"
#import "MTFont.h"
#import "Constants.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqDocumentObjectLabel+Extras.h"
#import "RptqDocumentObjectLabelLink+Extras.h"
#import "RptqDocumentObjectFormula.h"

typedef NS_ENUM(NSUInteger, MNSSectionType) {
	MNSObjectTypeLabel = 1,
	MNSObjectTypeLabelDataField = 2,
	MNSObjectTypeLabelFormula= 3,
	MNSObjectTypeLabelLabelLink = 4,
};

@interface RptqDocumentObject (Extras) <MTProtocolCompare, MTProtocolLog, RptqDocumentObjectFactory>

- (MNSSectionType)getType;
- (CGSize)viewSize;

@end

#endif
