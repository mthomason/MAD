//
//  RptqDocumentObjectLabel.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectLabel : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) RptqDocumentObject *parentObjectLabel;

@end
