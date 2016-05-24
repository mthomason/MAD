//
//  MADOpenFileViewControllerProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADOpenFileViewControllerProtocol_h
#define MADOpenFileViewControllerProtocol_h

@protocol MADOpenFileViewControllerDelegate <NSObject>

    - (void)openDocumentAtURL:(NSURL *)url;
    - (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType;
    - (NSArray *)supportedUTIs;

@end

#endif /* MADOpenFileViewControllerProtocol_h */
