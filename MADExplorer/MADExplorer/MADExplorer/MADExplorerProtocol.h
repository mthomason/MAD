//
//  MADExplorerProtocol.h
//  MADExplorer
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExplorerProtocol_h
#define MADExplorerProtocol_h

@class  MADMetaData;

@protocol MADExplorerProtocol <NSObject>
  @required

    - (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath;
    - (BOOL)isFileViewEditing;
    - (void)openDocumentAtURL:(NSURL *)url;
    - (void)explorerDidChangeNumberOfItemsSelected:(NSUInteger)numberOfItemsSelected;
    - (void)actionEmail:(id)sender;
    - (void)actionRename:(id)sender;
    - (void)actionDuplicate:(id)sender;
    - (void)actionActivateEditMode:(id)sender;

@end

#endif /* MADExplorerProtocol_h */
