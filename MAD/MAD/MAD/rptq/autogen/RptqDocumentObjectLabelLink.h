//
//  RptqDocumentObjectLabelLink.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDocumentObjectLabelLink_h
#define MAD_AutoGen_RptqDocumentObjectLabelLink_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectLabelLink : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) RptqDocumentObject *parentObjectLinkLabel;

@end

#endif
