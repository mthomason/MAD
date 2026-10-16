//
//  MADModel.h
//  MAD
//
//  Created by Michael on 1/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
