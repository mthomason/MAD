//
//  MADViewControllerDocumentProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/8/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADViewControllerDocumentProtocol_h
#define MAD_MADViewControllerDocumentProtocol_h

@class MADocument;

@protocol MADViewControllerDocumentProtocol <NSObject>

    @property (nonatomic, weak) MADocument *document;

@end

#endif /* MADocumentProtocol_h */
