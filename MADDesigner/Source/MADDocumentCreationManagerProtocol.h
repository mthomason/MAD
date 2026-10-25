//
//  MADDocumentCreationManagerProtocol.h
//  MAD Designer
//
//  Created by Michael on 9/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDocumentCreationManagerProtocol_h
#define MADDocumentCreationManagerProtocol_h

@class MADDocumentCreationManager;

@protocol MADDocumentCreationManagerProtocol <NSObject>
	- (void)documentCreationManager:(MADDocumentCreationManager *)manager
						  didFinish:(BOOL)success;
@end

#endif /* MADDocumentCreationManagerProtocol_h */
