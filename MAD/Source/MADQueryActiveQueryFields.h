//
//  MADQueryActiveQueryFields.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQueryActiveQueryFields_h
#define Reports_MADQueryActiveQueryFields_h

#import <Foundation/NSObject.h>

@class NSManagedObjectContext, RptqQueryField, NSSet <__covariant ObjectType>;

// This class should return all query fields used inside the report and query.  That is to
//      say, this class should get all RptqQueryField objects that are both inside
//      RptqDocumentElement's and the given RptqQuery object.

// FIXME: Right now the software only handles one query object.

@interface MADQueryActiveQueryFields : NSObject

- (instancetype)initWithContext:(NSManagedObjectContext *)context;

@property (nonatomic, strong) NSSet <RptqQueryField *> *queryFields;

@end

#endif
