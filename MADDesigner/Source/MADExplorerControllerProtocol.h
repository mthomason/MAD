//
//  MADExplorerControllerProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADExplorerControllerProtocol_h
#define MAD_MADExplorerControllerProtocol_h

#import <Foundation/NSArray.h>

@protocol MADExplorerControllerProtocol <NSObject>

- (void)openDocumentAtURL:(NSURL *)url completion:(void (^)(void))completion;
- (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType;
- (NSArray <NSString *> *)supportedUTIs;

@end

#endif /* MADFileExplorerViewControllerProtocol_h */
