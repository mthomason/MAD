//
//  MTProtocolLog.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MTProtocolLog_h
#define MAD_DataStructures_MTProtocolLog_h

@protocol MTProtocolLog <NSObject>
@required

	- (NSString *)toString;
	- (NSString *)toStringDebug;
	- (NSString *)toStringHumanReadable;

@optional

	- (NSString *)toStringExpressive;
	- (NSString *)toStringSymbolic;
	- (NSString *)toStringName;
	- (NSAttributedString *)toAttributedString;

@end

#endif
