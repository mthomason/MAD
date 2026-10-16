//
//  MADModel.m
//  MAD
//
//  Created by Michael on 1/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADModel.h"
#import <MAD/RptqStoreContext.h>

#import <Foundation/NSCompoundPredicate.h>
#import "MADModelDocument.h"

NSString * const MADNotificationQueryTableInsert = @"MADNotificationQueryTableInsert";
NSString * const MADNotificationQueryTableDelete = @"MADNotificationQueryTableDelete";

NSString * const MADNotificationQueryLinkInsert = @"MADNotificationQueryLinkInsert";
NSString * const MADNotificationQueryLinkDelete = @"MADNotificationQueryLinkDelete";

NSString * const MADKeyQueryLinkID = @"QLI";
NSString * const MADKeyQueryLinkLeftFieldID = @"LFI";
NSString * const MADKeyQueryLinkRightFieldID = @"RFI";
NSString * const MADKeyQueryLinkLeftTableID = @"LTI";
NSString * const MADKeyQueryLinkRightTableID = @"RTI";

NSString * const MADKeyQuery = @"MADKeyQuery";

#pragma mark -
#pragma mark MAD Object ID

@implementation MADModel
	@dynamic identifier;

+ (instancetype)newModelDocument:(RptqStoreContext *)managedObjectContext {
	return [[MADModelDocument alloc] initWithContext:managedObjectContext];
}

- (instancetype)init {
	self = [self initWithIdentifier:-1];
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier {
	if (self = [super init]) {
		_uid = identifier;
	}
	return self;
}

- (int64_t)identifier { return _uid; }

- (NSUInteger)hash { return 2654435761U * (unsigned long)llabs(_uid)^2; }

- (BOOL)isEqual:(id)object {
	return (self == object || (object != nil &&
			[object isKindOfClass:[self class]] &&
			((typeof(self))object)->_uid == _uid));
	
}

- (NSNumber *)objectID {
	return @(_uid);
}

/*
- (NSString *)debugDescription {
	NSString *debugDescription;
	debugDescription = _objectID.URIRepresentation.pathComponents.count == 3 ?
							[[NSString alloc] initWithFormat:@"%@ <%@::%@> %@, %@, $@, %@",
							 NSStringFromClass([self class]),
							 _objectID.URIRepresentation.pathComponents[1],
							 _objectID.URIRepresentation.pathComponents[2],
							 _objectID.URIRepresentation.absoluteString,
							 _objectID.URIRepresentation.relativeString,
							 _objectID.URIRepresentation.dataRepresentation] :
							self.debugDescription;
	return debugDescription;
}
*/
@end
