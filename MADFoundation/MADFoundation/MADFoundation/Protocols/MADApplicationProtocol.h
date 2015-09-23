//
//  MADApplicationProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/22/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADApplicationProtocol_h
#define MADApplicationProtocol_h

@protocol MADApplicationProtocol <NSObject>

- (NSString *)ubiquityIdentifier;
- (NSString *)groupIdentifier;
- (NSString *)name;

@end

#endif /* MADApplicationProtocol_h */
