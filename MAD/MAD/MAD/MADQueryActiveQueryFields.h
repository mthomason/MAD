//
//  MADQueryActiveQueryFields.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;
@class RptqQueryField;

// This class should return all query fields used inside the report and query.  That is to
//      say, this class should get all RptqQueryField objects that are both inside
//      RptqDocumentObject's and the given RptqQuery object.

// FIXME: Right now the software only handles one query object.

@interface MADQueryActiveQueryFields : NSObject

    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context;

    @property (nonatomic, strong) NSSet <RptqQueryField *> *queryFields;


@end
