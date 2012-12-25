//
//  ReportDesignerTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerReportDesigner.h"
#import "MTCollectionViewCellElement.h"
#import "SectionEnumerator.h"
#import "AppDelegate.h"
#import "UIView+StringTag.h"
#import "UICollectionView+Extras.h"
#import "UIView+NSObjectIdTag.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"


@interface MUIViewControllerReportDesigner()

@property (retain) NSMutableArray *scrollViewFrames;
@property (assign) BOOL formualInformationViewIsVisable;
@property (assign) BOOL imageInformationViewIsVisable;
@property (assign) BOOL labelInformationViewIsVisable;

@end

@implementation MUIViewControllerReportDesigner

- (void)dealloc {
    [_scrollViewFrames release];
    [_sections release];
    [_toolbox release];
    [_settingsPopoverController release];
    [_designScrollView release];
    [_informationButton release];
    [_barButtonItemInfo release];
    [_barButtonItemSettings release];
    [_barButtonItemObjects release];
    [_navBar release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)awakeFromNib {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGPoint origin = CGPointMake(5.0000f, 5.0000f);
    CGFloat paperWidth = CGFloatPointsForInches(8.5000f);
    //CGRect frame = CGRectMake(origin.x, origin.y, paperWidth, CGSizeZero.height);
    CGRect frame = CGRectMake(origin.x, origin.y, self.view.frame.size.width - 10.0000f, CGSizeZero.height);
    
    CGFloat halfHeight = self.view.frame.size.height / 2;
    
    [self setToolboxOnScreen: CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + self.view.bounds.size.height - halfHeight, self.view.bounds.size.width, halfHeight)];
    [self setToolboxOffScreen: CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + self.view.bounds.size.height, self.view.bounds.size.width, halfHeight)];
    [self setDesignScrollViewNormal: [[self designScrollView] frame]];
    [self setDesignScrollViewWithToolbox: CGRectMake(self.designScrollViewNormal.origin.x, self.designScrollViewNormal.origin.y, self.designScrollViewNormal.size.width, self.designScrollViewNormal.size.height - halfHeight)];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[[AppDelegate activeDocument] document]];
    NSInteger ctr = 0;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[enumerator count]];
    [self setSections: dict];
    [dict release];
    
    frame.size.height = 22.0000f;
    
    //frame.origin.y += frame.size.height + 10.0000f;
    for (RptqDocumentSection *sec in enumerator) {
        //NSLog(@"Ctr: %d, Type: %d", ctr, [[sec type] integerValue]);


        if (ctr > 0) frame.origin.y += frame.size.height + 10.0000f;
        frame.size.height = [[sec height] floatValue];
        
        [[self scrollViewFrames] addObject:[NSValue valueWithCGRect:frame]];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        [collectionView registerClass:[MTCollectionViewCellElement class] forCellWithReuseIdentifier:@"MTCollectionViewCellElement"];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        [collectionView setBackgroundColor:[UIColor edaBlackTwentyFivePercent]];
        [[collectionView layer] setCornerRadius:5.0000f];
        [collectionView setClipsToBounds:YES];
        [collectionView setObjectIdTag:[sec objectID]];

        UIView *backgroundView = [[UIView alloc] initWithFrame:[collectionView frame]];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, backgroundView.frame.size.width, 22.0000f)];
        [label setText:[sec localizedDisplayName]];
        [label setBackgroundColor:[UIColor clearColor]];

        [backgroundView addSubview:label];

        [collectionView setBackgroundView:backgroundView];
        [[self designScrollView] addSubview:collectionView];
        [self setCollectionView:collectionView forSection:sec];

        [layout release];
        [collectionView release];
        [backgroundView release];
        [label release];

        ctr++;
    }
    

    [enumerator release];
    
    [[self designScrollView] setScrollEnabled:YES];
    
    [[self designScrollView] setContentSize:self.view.frame.size];
    [[self designScrollView] setBackgroundColor: [UIColor scrollViewTexturedBackgroundColor]];
}

- (UICollectionView *)getCollectionViewForRptqSection:(RptqDocumentSection *)documentSection {
    return [[self sections] objectForKey:[[[documentSection objectID] URIRepresentation] absoluteString]];
}

- (void)setCollectionView:(UICollectionView *)collectionView forSection:(RptqDocumentSection *)documentSection {
    [[self sections] setValue:collectionView forKey:[[[documentSection objectID] URIRepresentation] absoluteString]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navController = [[segue destinationViewController] retain];
        if (navController) {
            if ([[navController viewControllers] count] > 0) {
                UITableViewControllerSettings *tvcSettings = [[[navController viewControllers] objectAtIndex: 0] retain];
                [tvcSettings setDelegate:self];
                [tvcSettings release];
            }
        }
        [navController release];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            [self setSettingsPopoverController: popoverController];
            popoverController.delegate = self;
        }
    } else if ([[segue identifier] isEqualToString:@"showObjects"]) {
        MUIViewControllerObjectSelector *viewControllerObjectSelector = [segue destinationViewController];
        [viewControllerObjectSelector setObjectSelectorDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"showReportViewerFromDesign"]) {
        MUIViewControllerReportViewer *viewControllerReportViewer = [segue destinationViewController];
        [viewControllerReportViewer setDelegate:self];
    }
}

#pragma mark - Gesture Recognizers

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {

    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    switch ([gestureRecognizer state]) {

            // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            case UIGestureRecognizerStateBegan: {
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            [[self designScrollView] bringSubviewToFront: [gestureRecognizer view]];
            newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [self setScrollersEnabled: NO];

            [[gestureRecognizer view] setCenter: newCenter];
            [[self designScrollView] addSubview: [gestureRecognizer view]];

            
            {
                NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                RptqDocumentObjectLabelDataField *datafield = [RptqDocumentObjectLabelDataField getLabelDataFieldForObjectID:[[gestureRecognizer view] objectIdTag]
                                                                                                           fromObjectContext:managedObjectContext];
                NSLog(@"OBJTag %@", [[gestureRecognizer view] objectIdTag]);
                NSLog(@"dataSe %@", [datafield parentObjectLabelDataField]);
                if (datafield) {
                    
                    RptqDocumentSection *section = [[datafield parentObjectLabelDataField] inSection];
                    __block UICollectionView *svSection = [self getCollectionViewForRptqSection:section];
                    
                    
                    
                    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
                    
                    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [documentSection hasObjects]];
                    NSUInteger deleteIndex = 0;
                    
                    BOOL found = NO;
                    for (RptqDocumentObject *object in hasObjects) {
                        if ([[[object isLabelDataField] objectID] isEqual: [[gestureRecognizer view] objectIdTag]]) {
                            found = YES;
                            break;
                        }
                        deleteIndex++;
                    }
                    if (found) {
                        [svSection performBatchUpdates:^{
                            [hasObjects removeObjectAtIndex:deleteIndex];
                            [documentSection setHasObjects:hasObjects];
                            
                            [[AppDelegate activeDocument] saveContext];
                            
                            
                            NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: 0];
                            NSLog(@"Delete %@", deletePath);
                            [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];
                            
                        } completion:^(BOOL finished) {
                            
                        }];
                    }
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [[gestureRecognizer view] setCenter: newCenter];
            break;
        }
        case UIGestureRecognizerStatePossible: {    // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible
            break;
        }
        case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
        case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
        case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded
            
            
            // MARK: Remove the element from one section and place it into the next new section
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            __block UICollectionView *newParent = nil;
            
            // MARK: Try to find the section to place the element view into.
            BOOL addedToNewParent = NO;
            for (UICollectionView *view in [[self designScrollView] subviews]) {
                if (CGRectContainsPoint([view frame], [[gestureRecognizer view] center]) && ![view isEqual:self]) {
                    if ([view isKindOfClass:[UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = [gestureRecognizer locationInView:newParent];
                        [[gestureRecognizer view] setCenter: newCenter];
                        break;
                    }
                }
            }
            if (!addedToNewParent) {
                for (UICollectionView *view in [[self designScrollView] subviews]) {
                    if ([view isKindOfClass: [UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = CGPointMake([gestureRecognizer view].frame.size.width / 2.0000f, [gestureRecognizer view].frame.size.height / 2.0000f);
                        [[gestureRecognizer view] setCenter: newCenter];
                        break;
                    }
                }
            }
            
            
            
            if (addedToNewParent) {
                newCenter = CGPointRoundPointToGrid(newCenter);
                [[gestureRecognizer view] setCenter: newCenter];

                
                NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                
                RptqDocumentObjectLabelDataField *datafield = [RptqDocumentObjectLabelDataField getLabelDataFieldForObjectID:[[gestureRecognizer view] objectIdTag]
                                                                                                           fromObjectContext:managedObjectContext];
                
                if (datafield) {
                    
                    datafield.parentObjectLabelDataField.originx = @([gestureRecognizer view].frame.origin.x);
                    datafield.parentObjectLabelDataField.originy = @([gestureRecognizer view].frame.origin.y);
                    datafield.parentObjectLabelDataField.sizewidth = @([gestureRecognizer view].frame.size.width);
                    datafield.parentObjectLabelDataField.sizeheight = @([gestureRecognizer view].frame.size.height);
                    
                    CGPoint newCenter = [[gestureRecognizer view] center];
                    [[gestureRecognizer view] removeFromSuperview];
                    
                    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[newParent objectIdTag]
                                                                                            fromObjectContext:managedObjectContext];
                    NSIndexPath *indexPath = [newParent indexPathForItemAtPoint:newCenter];
                    if (indexPath == nil) {
                        indexPath = [newParent indexOfAlienViewWithCenterPoint:newCenter];
                        if (indexPath == nil) {
                            indexPath = [NSIndexPath indexPathForItem:[newParent numberOfItemsInSection: 0] inSection:0];
                        }
                    }

                    indexPath = [NSIndexPath indexPathForItem:([indexPath item] + 1) inSection:[indexPath section]];
                    NSArray *indexPaths = [NSArray arrayWithObject: indexPath];

                    // MARK: Add this to the data context and to the container for the sections collection view.
                    [newParent performBatchUpdates:^{
                        NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[documentSection hasObjects]];
                        [hasObjects insertObject:[datafield parentObjectLabelDataField] atIndex:[indexPath item]];
                        [documentSection setHasObjects:hasObjects];
                        [[AppDelegate activeDocument] saveContext];

                        [newParent insertItemsAtIndexPaths:indexPaths];

                    } completion:^(BOOL finished) {
                    }];
                    
                }
                
            }
            [self setScrollersEnabled:YES];
            [[gestureRecognizer view] setNeedsDisplay];
            break;
        }
        default:
            break;
    }
}

- (void)setScrollersEnabled:(BOOL)enabled {
    @synchronized([self designScrollView]) {
        if ([[self designScrollView] respondsToSelector:@selector(setScrollEnabled:)]) {
            [[self designScrollView] setScrollEnabled:enabled];
            [[self designScrollView] flashScrollIndicators];
            for (UICollectionView *collectionView in [[self designScrollView] subviews]) {
                if ([collectionView isKindOfClass: [UICollectionView class]]) {
                    [collectionView setScrollEnabled:enabled];
                    [collectionView flashScrollIndicators];
                }
            }
        }
    }
}

#pragma mark - Collection View Flow Layout Delegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 5.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 5.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];
    
    CGSize result;
    
    if ([objects count] > row) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        result = CGSizeMake([[documentObject sizewidth] floatValue], [[documentObject sizeheight] floatValue]);
    } else {
        result = CGSizeZero;
    }
    NSLog(@"Size for item at %@: %@", indexPath, NSStringFromCGSize(result));
    return result;
}

#pragma mark - Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger row = [indexPath row];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    static NSString *tileReuseIdentifier = @"MTCollectionViewCellElement";
    UICollectionViewCell *cell = [[collectionView dequeueReusableCellWithReuseIdentifier:tileReuseIdentifier
                                                                            forIndexPath:indexPath] retain];
    
    //[[[collectionView] tag]
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];
    
    if ([objects count] > row) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        switch ([documentObject getType]) {
            case MNSObjectTypeLabel: {
                
                break;
            }
            case MNSObjectTypeLabelDataField: {
                
                RptqDocumentObjectLabelDataField *documentObjectCast = documentObject.isLabelDataField;
                CGRect f = CGRectMake(CGPointZero.x, CGPointZero.y, [[documentObjectCast.parentObjectLabelDataField sizewidth] floatValue],
                                      [[documentObjectCast.parentObjectLabelDataField sizeheight] floatValue]);
                
                UIView *newView1 = [[UIView alloc] initWithFrame: f];
                UILabel *label = [[UILabel alloc] initWithFrame: f];
                NSLog(@"%@", [[documentObjectCast parentObjectLabelDataField] isLabelDataField]);
                [label setText: [[[documentObjectCast parentObjectLabelDataField] isLabelDataField] text]];
                [label setBackgroundColor:[UIColor clearColor]];
                [newView1 setBackgroundColor:[UIColor whiteColor]];
                [newView1 addSubview: label];
                [newView1 setBounds: f];
                [newView1 setMultipleTouchEnabled: YES];
                [newView1 setExclusiveTouch: YES];
                [newView1 setObjectIdTag: [documentObjectCast objectID]];
                [newView1 setOpaque: YES];
                [[newView1 layer] setCornerRadius: 5.0000f];
                
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
                [panGesture setMaximumNumberOfTouches:1];
                [panGesture setDelegate:self];
                [newView1 addGestureRecognizer:panGesture];
                [panGesture release];
                
                [cell setTag:[[[documentObjectCast parentObjectLabelDataField] identifier] integerValue] + 3838];
                [cell setBounds: CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                [[cell contentView]  setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                
                [[cell contentView] addSubview:newView1];
                [newView1 setNeedsDisplay];
                [newView1 release];
                
                break;
            }
            case MNSObjectTypeLabelFormula: {
                break;
            }
            case MNSObjectTypeLabelLabelLink: {
                break;
            }
            default: {
                break;
            }
        }
    }
    
    return [cell autorelease];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[[AppDelegate activeDocument] managedObjectContext]];
    NSOrderedSet *objects = [documentSection hasObjects];
    //NSLog(@"Objects in section: %d", [objects count]);
    return [objects count];
}

/*
 - (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
 viewForSupplementaryElementOfKind:(NSString *)kind
 atIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - Collection View Delegate
/*
 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
 
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }*/

#pragma mark - Actions

- (void)openReport:(NSURL *)url {
    UIManagedDocumentPreferencesUser *trvFile = [[UIManagedDocumentPreferencesUser alloc] initWithFileURL:url];
    
    [trvFile release];
}

- (void)openTemplate:(NSURL *)url {
    
    NSString *origionalFileName = [[url lastPathComponent] retain];
    
    NSURL *urlLibraryTemplate = [[NSFileManager applicationLibraryTemplatesDirectoryUrl] retain];
    NSURL *urlFilenameWithoutExtention = [[[urlLibraryTemplate URLByAppendingPathComponent:origionalFileName] URLByDeletingPathExtension] retain];
    
    NSURL *templateDestination = [[urlFilenameWithoutExtention URLByAppendingPathExtension:TRVDATA_PATH_EXTENSION] retain];
    NSString *templateDestinationName = [[templateDestination lastPathComponent] retain];
    
    BOOL fileWritten = NO;
    
    NSInteger ctr = 0;
    while (!fileWritten) {
        NSError *error;
        fileWritten = [[NSFileManager defaultManager] copyItemAtURL:url toURL:templateDestination error:&error];
        if (!fileWritten) {
            [templateDestination release];
            NSString *p = [[[urlFilenameWithoutExtention path] stringByAppendingFormat:@" %d", (ctr + 1)] retain];
            templateDestination = [[urlFilenameWithoutExtention URLByAppendingPathExtension:TRVDATA_PATH_EXTENSION] retain];
            [p release];
        }
    }
    [urlFilenameWithoutExtention release];
    [urlLibraryTemplate release];
    [templateDestinationName release];
    [origionalFileName release];
    
    
    //Now that we copied the file, we open it.  Yay!
    [self openReport:templateDestination];
    
    [templateDestination release];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

- (IBAction)showObjects:(id)sender {
    [self performSegueWithIdentifier:@"showObjects" sender:sender];
}

- (IBAction)showSettings:(id)sender {
    [self performSegueWithIdentifier:@"showSettings" sender:sender];
}

- (IBAction)info:(id)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //Make sure there are no information views open
        [[self informationButton] setEnabled: NO];
        
        UIStoryboard *sbLblControl = [[UIStoryboard storyboardWithName:STORYBOARD_NAME() bundle:nil] retain];
        UIViewControllerToolbox *lblControl = [[sbLblControl instantiateViewControllerWithIdentifier:@"LabelViewController"] retain];
        [self setToolbox:lblControl];
        [lblControl release];
        [sbLblControl release];
                
        [[self toolbox] setDelegate: self];
        [[[self toolbox] view] setFrame:[self toolboxOffScreen]];
        [[self view] addSubview:[[self toolbox] view]];
        
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                         animations: ^{
                             [[[self toolbox] view] setFrame: [self toolboxOnScreen]];
                             [[self designScrollView] setFrame:[self designScrollViewWithToolbox]];
                         } completion:^(BOOL finished) {

                         }];
    }
}

#pragma mark - Delegates

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    if ([sender isKindOfClass:[UITableViewControllerSettings class]]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        } else {
            [[self settingsPopoverController] dismissPopoverAnimated:YES];
            [self setSettingsPopoverController: nil];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)didSelectDataField:(RptqField *)field {

    [self dismissViewControllerAnimated:YES completion:^{
        
    }];

    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];

    if (document) {
        
        
        UICollectionView *detailSection = [self getCollectionViewForRptqSection:[document hasDetailSection]];
        
        [detailSection performBatchUpdates:^{
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            
            RptqDocumentObject *dobject = [RptqDocumentObjectLabelDataField addNewLabelDataFeildForField:field
                                                 toDetailSectionOfDocument:document
                                                  withManagedObjectContext:managedObjectContext];

            NSArray *indexPaths = [NSArray arrayWithObject: [NSIndexPath indexPathForItem:0 inSection:0]];
            [[AppDelegate activeDocument] saveContext];

            
            [detailSection insertItemsAtIndexPaths:indexPaths];
         
        } completion:^(BOOL finished) {

        }];
    }
}


- (void)labelInformationViewControllerDidFinish:(UIViewControllerToolbox *)controller {
    
    [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                     animations: ^{
                         [[self designScrollView] setFrame:[self designScrollViewNormal]];
                         [[[self toolbox] view] setFrame: [self toolboxOffScreen]];
                     } completion:^(BOOL finished) {
                         [[[self toolbox] view] removeFromSuperview];
                         [[self informationButton] setEnabled: YES];
                     }];
}


@end