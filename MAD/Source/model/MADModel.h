//
//  MADModel.h
//  MAD
//
//  Created by Michael on 1/22/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The base of the document read-model: identity only.  A model object's
//  `identifier` is the store row's identifier, which is the glue between this layer
//  and the Rptq entities.  The layer is a read-only view the designer's query UI
//  binds to; write through Rptq.  See docs/project/MADModel_Layer.md at the repo root.
//

#ifndef Reports_MADModel_h
#define Reports_MADModel_h

#import <Foundation/NSObject.h>
#import <Foundation/NSValue.h>
#import <MAD/MADModelIDProtocol.h>
#import <MAD/RptqStoreContext.h>


extern NSString * const MADNotificationQueryTableInsert;
extern NSString * const MADNotificationQueryTableDelete;

extern NSString * const MADNotificationQueryLinkInsert;
extern NSString * const MADNotificationQueryLinkDelete;

extern NSString * const MADKeyQuery;

extern NSString * const MADKeyQueryLinkID;
extern NSString * const MADKeyQueryLinkLeftFieldID;
extern NSString * const MADKeyQueryLinkRightFieldID;
extern NSString * const MADKeyQueryLinkLeftTableID;
extern NSString * const MADKeyQueryLinkRightTableID;

@interface MADModel : NSObject
	<MADModelIDProtocol> {
  @protected
	int64_t _uid;
}

	+ (instancetype)newModelDocument:(RptqStoreContext *)managedObjectContext;
	- (instancetype)initWithIdentifier:(int64_t)identifier NS_DESIGNATED_INITIALIZER;

	- (NSNumber *)objectID;

@end

#endif
