//
//  RptqDocumentObjectChart.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectChart : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqDocumentObject *parentObject;

@end
