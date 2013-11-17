//
//  RptqDocumentObjectGroupKey.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectGroupKey : NSManagedObject

@property (nonatomic, retain) NSNumber * groupNumber;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqDocumentObject *parentObject;

@end
