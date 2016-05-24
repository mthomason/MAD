//
//  MADCollectionViewLayoutGroupedDelegateProtocol.h
//  MADExplorer
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADCollectionViewLayoutGroupedDelegateProtocol_h
#define MADCollectionViewLayoutGroupedDelegateProtocol_h

@class  MADMetaData;

@protocol MADCollectionViewLayoutFilesDelegate <NSObject>
  @required

    - (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath;
    - (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath;
    - (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath;
    - (BOOL)isFileViewEditing;

  @optional
    - (void)userSelectedItemAtIndexPath:(NSIndexPath *)indexPath;
    - (void)selectionsUpdated;

@end

#endif /* MADCollectionViewLayoutGroupedDelegateProtocol_h */
