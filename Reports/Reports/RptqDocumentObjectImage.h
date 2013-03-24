//
//  RptqDocumentObjectImage.h
//  Reports
//
//  Created by Michael Thomason on 3/19/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectImage : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) RptqDocumentObject *parentObject;

@end
