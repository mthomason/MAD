//
//  MADDocumentProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentProtocol_h
#define MAD_MADDocumentProtocol_h

@class MADCredential, NSString;

@protocol MADocumentDelegate
  @required
  @optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
@end

#endif /* MADDocumentProtocol_h */
