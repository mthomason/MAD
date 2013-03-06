//
//  RptqDocumentObject+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObject.h"
#import "MTProtocolCompare.h"
#import "MTProtocolLog.h"
#import "RptqDocument.h"
#import "RptqDocumentObjectFactory.h"

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
