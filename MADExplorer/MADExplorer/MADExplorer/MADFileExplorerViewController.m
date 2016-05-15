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
    @property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;

@end

@implementation MADFileExplorerViewController

- (void)dealloc {
    _subtitleNumberFormatter = nil;
}

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

        dispatch_queue_t queueCell = dispatch_queue_create("com.everydayapps.mad.cell.image",
                                                           DISPATCH_QUEUE_SERIAL);
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

    NSArray <NSIndexPath *> *selectedIndexs = self.collectionView.indexPathsForSelectedItems.copy;
    typeof (self.collectionView) __weak wCollectionView = self.collectionView;
    [selectedIndexs enumerateObjectsWithOptions: NSEnumerationConcurrent
                                     usingBlock: ^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
    
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UICollectionView *collectionView = wCollectionView;
            if (collectionView) {
                id cell = [collectionView cellForItemAtIndexPath:indexPath];
                [cell performDeselectionAnimations];
            }
        }];
    }];
}

#pragma mark - MADCollectionViewLayoutFilesDelegate

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
    return metadata.URL.lastPathComponent.stringByDeletingPathExtension;
}

- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
    return [self copySubtitleForMetadata:metadata];
}

- (NSString *)copySubtitleForMetadata:(MADMetaData *)metadata {
    NSString *result;
    NSString *downloadingStatus = metadata.ubiquitousItemDownloadingStatus.copy;
    if ([downloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]) {
        result = NSLocalizedString(NotDownloaded, NotDownloaded);;
    } else {
        NSNumber *systemFileSizeMB = [[NSNumber alloc] initWithDouble:madSystemFileSizeToMB(metadata.fileSystemFileSize)];
        NSString *systemFileSizeString = [self.subtitleNumberFormatter stringFromNumber:systemFileSizeMB];
        result = [[NSString alloc] initWithFormat:@"%@ MB", systemFileSizeString];
    }
    return result;
}

- (BOOL)isFileViewEditing { return self.editing; }

- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView { return 1; }

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filesCoordnator.filesController ? (NSInteger)self.filesCoordnator.filesController.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const MTCollectionViewCellDocumentIdentifier  = @"MTCollectionViewCellDocumentIdentifier";
    MTCollectionViewCellDocument *cell = [collectionView dequeueReusableCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier
                                                                                   forIndexPath: indexPath];
    
    if (cell.delegate == nil) {
        ((MTCollectionViewCellDocument *)cell).delegate = self;
    }
    
    MADMetaData *metadata = [self metadataForItemAtIndexPath:indexPath];

    NSString *filename = metadata.name.copy;
    cell.labelTitle.text = filename;
    
    bool notDownloaded = [metadata.ubiquitousItemDownloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded];
    bool downloading = metadata.ubiquitousItemIsDownloading;
    bool uploading = metadata.ubiquitousItemIsUploading;

    if (downloading) {
        cell.labelTitleSub.text = NSLocalizedString(Downloading, Downloading);
    } else if (uploading) {
        cell.labelTitleSub.text = NSLocalizedString(Syncing, Syncing);
    } else {
        NSString *subtitle = [self copySubtitleForMetadata:metadata];
        cell.labelTitleSub.text = subtitle.copy;
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
        [cell.progressViewDownload setProgress:0.0 animated:YES];
    }
    
    if (metadata.ubiquitousItemIsDownloading || metadata.ubiquitousItemIsUploading) {
        [cell.activityIndicator startAnimating];
    } else {
        [cell.activityIndicator stopAnimating];
    }
    
    cell.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ? [UIImage imageNamed:MADImageToolbarCloudDownload] : nil;
    
    [cell.labelTitle layoutIfNeeded];
    [cell.labelTitleSub layoutIfNeeded];


    @autoreleasepool {
        NSURL *thumbnailUrl = [self.fileExplorerDelegate newUrlThumbnailForUrl:metadata.URL];
        NSString *path = thumbnailUrl.path;
        if (!path) goto END_ReadThumbnail;
        {
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
            UIImage *image = [[UIImage alloc] initWithData:imageData scale:6.0];
        
            if (image != nil) {
                cell.imagePreview.image = image;
            } else {
                image = [MTCollectionViewCellDocument newDefaultThumbnail];
                cell.imagePreview.image = image;
            }
            image = nil;
            imageData = nil;
        }
        END_ReadThumbnail:;
    }
    
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
        _subtitleNumberFormatter = [NSNumberFormatter newNumberFormatterTwoDecimalPlaces];
    }
    return _subtitleNumberFormatter;
}

@end
