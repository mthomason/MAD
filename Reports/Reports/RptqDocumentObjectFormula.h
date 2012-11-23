//
//  RptqDocumentObjectFormula.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectFormula : NSManagedObject

@property (nonatomic, retain) NSString * formulaSource;
@property (nonatomic, retain) RptqDocumentObject *parentObjectFormula;

@end
