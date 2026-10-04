//
//  MADExplorer.h
//  MADExplorer
//
//  Created by Michael Thomason on 9/10/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

//! Project version number for MADExplorer.
FOUNDATION_EXPORT double MADExplorerVersionNumber;

//! Project version string for MADExplorer.
FOUNDATION_EXPORT const unsigned char MADExplorerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MADExplorer/PublicHeader.h>
#import <MADExplorer/MADCollectionViewCellDocument.h>
#import <MADExplorer/MADOpenDocumentManager.h>
#import <MADExplorer/MADBackgroundViewSelected.h>
#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADExplorerViewDelegate.h>
#import <MADExplorer/MADSaveFileProtocol.h>

// Remaining public headers, so the module umbrella is complete.
// (-Wincomplete-umbrella; keep in sync with the Public headers phase.)
#import <MADExplorer/MADDocumentCellProtocol.h>
#import <MADExplorer/MADDocumentManagerProtocol.h>
#import <MADExplorer/MADExplorerDataSource.h>
#import <MADExplorer/MADExplorerProtocol.h>
#import <MADExplorer/MADExplorerView.h>
#import <MADExplorer/MADLabelFileExplorerDocumentCellTitle.h>
#import <MADExplorer/MADStandard.h>
#import <MADExplorer/MADThumbnailView.h>
