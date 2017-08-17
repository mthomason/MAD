//
//  MADKeyChainKeyValueProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADKeyChainKeyValueProtocol_h
#define MADKeyChainKeyValueProtocol_h

@protocol MADKeyChainKeyValueProtocol <NSObject>

    - (NSString *)valueForKey:(NSString *)key;

@end

#endif /* MADKeyChainKeyValueProtocol_h */
