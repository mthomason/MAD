//
//  MADModelDocument.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The root of the read-model: one per open document, built lazily by
//  -MADocument.documentModel over the store context.  Owns the databases and
//  queries, and observes the store's change notifications so query-graph changes
//  arrive as the MADNotification... postings the designer subscribes to.
//  See docs/project/MADModel_Layer.md at the repo root.
//

#ifndef MADModelDocument_h
#define MADModelDocument_h

#import <MAD/MADModel.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADModelDataProtocol.h>

@class MADModelDatabase, MADModelQuery, NSOrderedSet<__covariant ObjectType>;

@interface MADModelDocument : MADModel <MADModelIDProtocol, MADModelDataProtocol>

- (instancetype)initWithContext:(RptqStoreContext *)managedObjectContext;

@property (nonatomic, readonly, strong) NSOrderedSet <MADModelDatabase *> *databases;
@property (nonatomic, readonly, weak) MADModelDatabase *firstDatabase;
@property (nonatomic, readonly, weak) MADModelQuery *firstQuery;

@end

#endif /* MADModelDocument_h */
