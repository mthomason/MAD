//
//  RptqDocumentObjectGroupKey.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectGroupKey : NSManagedObject

@property (nonatomic, strong) NSNumber * groupNumber;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) RptqDocumentObject *parentObject;

@end
