//
//  RptqDocumentObjectLabel.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDocumentObjectLabel_h
#define MAD_AutoGen_RptqDocumentObjectLabel_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectLabel : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) RptqDocumentObject *parentObjectLabel;

@end

#endif
