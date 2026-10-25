//
//  MADQueryActiveQueryFields.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryActiveQueryFields_h
#define Reports_MADQueryActiveQueryFields_h

#import <Foundation/NSObject.h>
#import <MAD/RptqStoreContext.h>

@class RptqQueryField, NSSet <__covariant ObjectType>;

// This class should return all query fields used inside the report and query.  That is to
//      say, this class should get all RptqQueryField objects that are both inside
//      RptqDocumentElement's and the given RptqQuery object.

// FIXME: Right now the software only handles one query object.

@interface MADQueryActiveQueryFields : NSObject

- (instancetype)initWithContext:(RptqStoreContext *)context;

@property (nonatomic, strong) NSSet <RptqQueryField *> *queryFields;

@end

#endif
