//
//  MADFileExplorerViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileExplorerViewController.h"
#import "MTDocumentCellProtocol.h"
#import "MADCollectionViewLayoutGroupedDelegate.h"
#import "MTCollectionViewCellDocument.h"
#import "MADFileLocationManager.h"
#import "MADOpenDocumentManager.h"

static NSString * const NotDownloaded                           = @"Not Downloaded";
static NSString * const Syncing                                 = @"Syncing";
static NSString * const Downloading                             = @"Downloading";

@interface MADFileExplorerViewController ()
    <MTDocumentCellProtocol, UIGestureRecognizerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) MADCollectionViewLayoutGroupedDelegate *collectionViewDelegate;
@property (nonatomic, strong) dispatch_queue_t queueCell;

@end

@implementation MADFileExplorerViewController

- (NSURL *)documentDirectory {
    return self.filesCoordnator.filesController.documentDirectory;
}

- (UIManagedDocument *)openDocument {
    return self.reportState == MTReportStateOpen ? self.fileManager.openDocument : nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        MADFileLocationManager *filesCoordnator = [[MADFileLocationManager alloc] init];
        filesCoordnator.filesController.delegate = self;
        self.filesCoordnator = filesCoordnator;

        dispatch_queue_t queueCell = dispatch_queue_create("com.everydayapps.mad.cell.image", DISPATCH_QUEUE_SERIAL);
        self.queueCell = queueCell;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADCollectionViewLayoutGroupedDelegate *delegate = [[MADCollectionViewLayoutGroupedDelegate alloc] init];
    delegate.delegate = self;
    self.collectionViewDelegate = delegate;
    
    self.collectionView.delegate = self.collectionViewDelegate;
    self.collectionView.dataSource = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell performDeselectionAnimations];
    }
    for (NSIndexPath *path in self.collectionView.indexPathsForVisibleItems) {
        [self.collectionView deselectItemAtIndexPath: path animated: animated];
    }
    
}

#pragma mark - MADCollectionViewLayoutFilesDelegate

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
    return metadata.URL.lastPathComponent.stringByDeletingPathExtension;
}

- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
    return [self subtitleForMetadata:metadata];
}

- (NSString *)subtitleForMetadata:(MADMetaData *)metadata {
    NSString *result;
    if ([metadata.ubiquitousItemDownloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]) {
        result = NSLocalizedString(NotDownloaded, NotDownloaded);;
    } else {
        NSNumber *systemFileSizeMB =  [MTMath systemFileSizeToMB: metadata.fileSystemFileSize];
        NSString *systemFileSizeString = [self.subtitleNumberFormatter stringFromNumber:systemFileSizeMB];
        result = [NSString stringWithFormat:@"%@ MB", systemFileSizeString];
    }
    return result;
}

- (BOOL)isFileViewEditing { return self.editing; }

- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"\t%s\tItem:\t%ld", __PRETTY_FUNCTION__, (long)indexPath.item);
    return [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return self.filesCoordnator.filesController ? (NSInteger)self.filesCoordnator.filesController.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"\t%s\tItem:\t%ld", __PRETTY_FUNCTION__, (long)indexPath.item);
    
    static NSString * MTCollectionViewCellDocumentIdentifier  = @"MTCollectionViewCellDocumentIdentifier";
    MTCollectionViewCellDocument *cell = [collectionView dequeueReusableCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier forIndexPath: indexPath];
    
    if (cell.delegate == nil) {
        ((MTCollectionViewCellDocument *)cell).delegate = self;
    }
    MADMetaData *metadata = [self metadataForItemAtIndexPath:indexPath];
    NSString *filename = metadata.name;
    cell.labelTitle.text = filename;
    
    bool notDownloaded = [metadata.ubiquitousItemDownloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded];
    bool downloading = metadata.ubiquitousItemIsDownloading;
    bool uploading = metadata.ubiquitousItemIsUploading;
    bool uploaded = metadata.ubiquitousItemIsUploaded;
    CGFloat p = metadata.ubiquitousItemPercentUploaded;
    
    if (downloading) {
        cell.labelTitleSub.text = NSLocalizedString(Downloading, Downloading);
    } else if (uploading) {
        cell.labelTitleSub.text = NSLocalizedString(Syncing, Syncing);
    } else {
        cell.labelTitleSub.text = [self subtitleForMetadata:metadata];
    }
    
    if (uploading) {
        cell.progressViewUpload.hidden = NO;
        if (cell.progressViewUpload.progress < metadata.ubiquitousItemPercentUploaded / 100.0000f) {
            [cell.progressViewUpload setProgress:(float) (metadata.ubiquitousItemPercentUploaded / 100.0000f) animated:YES];
        }
    } else {
        cell.progressViewUpload.hidden = YES;
        [cell.progressViewUpload setProgress:0.0000f animated:YES];
    }
    
    if (downloading) {
        cell.progressViewDownload.hidden = NO;
        if (cell.progressViewUpload.progress < metadata.ubiquitousItemPercentDownloaded / 100.0000f) {
            [cell.progressViewDownload setProgress:(float) (metadata.ubiquitousItemPercentDownloaded / 100.0000f) animated:YES];
        }
    } else {
        cell.progressViewDownload.hidden = YES;
        [cell.progressViewDownload setProgress:0.0000f animated:YES];
    }
    
    if (metadata.ubiquitousItemIsDownloading || metadata.ubiquitousItemIsUploading) {
        [cell.activityIndicator startAnimating];
    } else {
        [cell.activityIndicator stopAnimating];
    }
    
    cell.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ? [UIImage imageNamed:MADImageToolbarCloudDownload] : nil;
    
    [cell.labelTitle layoutIfNeeded];
    [cell.labelTitleSub layoutIfNeeded];

    //dispatch_async(self.queueCell, ^{
        NSURL *thumbnailUrl = [UIDocument thumbnailUrlForMadUrl:metadata.URL];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:thumbnailUrl.path];
    //    dispatch_sync(dispatch_get_main_queue(), ^(void) {
            cell.imagePreview.image = image ?: [MTCollectionViewCellDocument defaultThumbnail];
    //    });
    //});

    
    [cell normalizeTint];
    
    if ([self isFileViewEditing]) {
        [cell startWobble];
    } else {
        [cell stopWobble];
    }
    
    return cell;
}

#pragma mark - UISearchBarDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField { }

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar { }

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope { }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { }

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar { }

#pragma mark - MTDocumentCellProtocol

- (void)activateEditMode:(UILongPressGestureRecognizer *)sender {
    [self.fileExplorerDelegate editFile:sender];
}

- (void)actionDuplicate:(id)sender {
    [self.fileExplorerDelegate duplicateFile:sender];
}

- (void)rename:(id)sender {
    [self.fileExplorerDelegate renameFile:sender];
}

- (void)email:(MTCollectionViewCellDocument *)cell {
    [self.fileExplorerDelegate emailFile:cell];
}

#pragma mark - Property Overrides

- (NSNumberFormatter *)subtitleNumberFormatter {
    if (!_subtitleNumberFormatter) {
        _subtitleNumberFormatter = [NSNumberFormatter twoDecimalPlaces];
    }
    return _subtitleNumberFormatter;
}

@end
