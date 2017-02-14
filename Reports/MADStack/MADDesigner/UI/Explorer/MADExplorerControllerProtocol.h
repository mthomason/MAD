//
//  MADExplorerControllerProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADExplorerControllerProtocol_h
#define MAD_MADExplorerControllerProtocol_h

@protocol MADExplorerControllerProtocol <NSObject>

    - (void)openDocumentAtURL:(NSURL *)url;
    - (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType;
    - (NSArray *)supportedUTIs;

@end

#endif /* MADFileExplorerViewControllerProtocol_h */
