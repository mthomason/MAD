//
//  RptqDocumentObjectImage.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectImage : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) id image;
@property (nonatomic, strong) RptqDocumentObject *parentObject;

@end
