//
//  RptqDocumentObject+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObject.h"

typedef enum {
	MNSObjectTypeLabel = 1,
	MNSObjectTypeLabelDataField = 2,
	MNSObjectTypeLabelFormula= 3,
	MNSObjectTypeLabelLabelLink = 4,
} MNSSectionType;

@interface RptqDocumentObject (Extras)

- (MNSSectionType)getType;

@end