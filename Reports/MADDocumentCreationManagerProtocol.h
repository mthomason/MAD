//
//  MADDocumentCreationManagerProtocol.h
//  MAD Designer
//
//  Created by Michael on 9/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDocumentCreationManagerProtocol_h
#define MADDocumentCreationManagerProtocol_h

@protocol MADDocumentCreationManagerProtocol <NSObject>
    - (void)documentCreationManager:(MADDocumentCreationManager *)manager
                          didFinish:(BOOL)success;
@end

#endif /* MADDocumentCreationManagerProtocol_h */
