//
//  RptqDocumentObjectLabel.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectLabel : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) RptqDocumentObject *parentObjectLabel;

@end
