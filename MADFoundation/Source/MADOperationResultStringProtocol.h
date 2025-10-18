//
//  MADOperationResultStringProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADOperationResultStringProtocol_h
#define MADOperationResultStringProtocol_h

typedef NS_ENUM(short, MADKeyChainReadOperationTypes) {
	MADKeyChainReadOperationTypeUsername,
	MADKeyChainReadOperationTypePassword,
};

@protocol MADOperationResultStringProtocol <NSObject>

	- (NSString *)key;
	- (NSString *)value;
	- (BOOL)success;
	- (MADKeyChainReadOperationTypes)readOperationType;

@end

#endif /* MADOperationResultStringProtocol_h */
