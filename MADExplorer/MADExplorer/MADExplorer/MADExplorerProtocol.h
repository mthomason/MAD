//
//  MADExplorerProtocol.h
//  MADExplorer
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADExplorerProtocol_h
#define MADExplorerProtocol_h

@class  MADMetaData;

@protocol MADExplorerProtocol <NSObject>
@required
- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath;
- (UICollectionView *)fileExplorerView;
- (BOOL)isFileViewEditing;
- (void)openDocumentAtURL:(NSURL *)url completion:(void (^)(void))completion;
- (void)explorerDidChangeNumberOfItemsSelected:(NSUInteger)numberOfItemsSelected;
- (void)actionEmail:(id)sender;
- (void)actionRename:(id)sender;
- (void)actionDuplicate:(id)sender;
- (void)actionActivateEditMode:(UICollectionViewCell *)sender;
@end

#endif /* MADExplorerProtocol_h */
