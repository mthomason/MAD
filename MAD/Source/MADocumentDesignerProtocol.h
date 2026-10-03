//
//  MADocumentDesignerProtocol.h
//  MAD
//
//  Created by Michael on 8/21/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADocumentDesignerProtocol_h
#define MAD_MADocumentDesignerProtocol_h

@class NSUndoManager, NSManagedObjectContext, RptqStoreContext;
@protocol MADocumentDesignerProtocol <NSObject>

@property (strong, null_resettable) NSUndoManager *undoManager;
@property (nonatomic, strong, readonly, null_resettable) RptqStoreContext *managedObjectContext;

@end

#endif /* MADocumentDesignerProtocol_h */
