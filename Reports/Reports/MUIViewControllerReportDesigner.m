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
    if (_toolbox) [_toolbox release];
    [_settingsPopoverController release];
    [_designScrollView release];
    [_containerView release];
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

- (void)insertDocumentElementLabel:(RptqDocumentObjectLabel *)documentObj {

}

- (void)insertDocumentElementFormula:(RptqDocumentObjectFormula *)documentObj {
    
}

- (void)insertDocumentElementLabelDataField:(RptqDocumentObjectLabelDataField *)documentObj {

    if (![[self designScrollView] viewWithTag: [[documentObj objectID] hash]]) {
        
        CGRect f = CGRectMake([[documentObj.parentObjectLabelDataField originx] floatValue], [[documentObj.parentObjectLabelDataField originy] floatValue], [[documentObj.parentObjectLabelDataField sizewidth] floatValue], [[documentObj.parentObjectLabelDataField sizeheight] floatValue]);
        
        RptqDocumentSection *documentSectionOld = [[documentObj parentObjectLabelDataField] inSection];

        UICollectionView *scrollView = [self getCollectionViewForRptqSection: documentSectionOld];
        
        if (scrollView) {
            ElementView *newView = [[ElementView alloc] initWithFrame: f
                                                        inSectionView: scrollView
                                                       ofDesignerView:[self designScrollView]];
            [newView setBounds: f];
            [newView setStringElm: documentObj.parentObjectLabelDataField.isLabelDataField.text];
            [newView setMultipleTouchEnabled: YES];
            [newView setExclusiveTouch: YES];
            [newView setObjectID: [documentObj objectID]];
            [newView setDelegate: self];
            [newView setTag: [[documentObj objectID] hash]];
            
            CGPoint center = CGCenterOfRect(f);
            NSIndexPath *ip = [scrollView indexOfAlienViewWithCenterPoint:center];
            
            [scrollView performBatchUpdates:^{
                RptqDocumentSection *sectionNew = [RptqDocumentSection getDocumentSectionForObjectID:[scrollView objectIdTag] fromObjectContext:[[AppDelegate activeDocument] managedObjectContext]];
                [[documentObj parentObjectLabelDataField] setInSection: sectionNew];
                [scrollView insertItemsAtIndexPaths:[NSArray arrayWithObject: ip]];
                
            } completion:^(BOOL finished) {
            }];
            
            [newView release];
        }
    }
}

- (void)insertDocumentElementLabelLink:(RptqDocumentObjectLabelLink *)documentObj {
    
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
    
    frame.origin.y += frame.size.height + 10.0000f;
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
                CGRect f = CGRectMake(0, 0, [[documentObjectCast.parentObjectLabelDataField sizewidth] floatValue], [[documentObjectCast.parentObjectLabelDataField sizeheight] floatValue]);
                ElementView *newView = [[ElementView alloc] initWithFrame: f
                                                            inSectionView: collectionView
                                                           ofDesignerView:[self designScrollView]];
                [newView setBounds: f];
                [newView setStringElm: documentObjectCast.parentObjectLabelDataField.isLabelDataField.text];
                [newView setMultipleTouchEnabled: YES];
                [newView setExclusiveTouch: YES];
                [newView setObjectID: [documentObjectCast objectID]];
                [newView setDelegate: self];
                [newView setTag: [[documentObjectCast objectID] hash]];
                [cell setBounds: CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                [[cell contentView]  setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                
                [[cell contentView] addSubview:newView];
                
                [cell setBackgroundColor:[UIColor redColor]];
                [[cell contentView] setBackgroundColor:[UIColor blueColor]];
                
                [newView release];
                
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
    NSLog(@"Objects in section: %d", [objects count]);
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
            NSInteger numberOfExistingObjects = [[[document hasDetailSection] hasObjects] count];
            [RptqDocumentObjectLabelDataField addNewLabelDataFeildForField:field toDetailSectionOfDocument:document];
            NSArray *indexPaths = [NSArray arrayWithObject: [NSIndexPath indexPathForItem:numberOfExistingObjects inSection:0]];
            [detailSection insertItemsAtIndexPaths:indexPaths];
            NSError *error = nil;
            [managedObjectContext save: &error];
            if (error) {
                [error presentErrorToUser];
            }

            [[AppDelegate activeDocument] saveContext];
         
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

#pragma mark Element View Delegate
#import "RptqDocumentObjectLabelDataField+Extras.h"

- (void)elementDidBeginPan:(ElementView *)view {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocumentObjectLabelDataField *datafield = [RptqDocumentObjectLabelDataField getLabelDataFieldForObjectID:[view objectID] fromObjectContext:managedObjectContext];
    
    if (datafield) {

        __block UICollectionView *svSection = [view containerView];

        [svSection performBatchUpdates:^{
            
            RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
            //[documentSection removeHasObjectsObject:[datafield parentObjectLabelDataField]];
            [documentSection removeHasObjectsObjectFixed:[datafield parentObjectLabelDataField]];
            NSIndexPath *deletePath = [NSIndexPath indexPathForItem:[[[datafield parentObjectLabelDataField] sectionIndexItem] integerValue]
                                                          inSection:[[[datafield parentObjectLabelDataField] sectionIndexRow] integerValue]];
            
            [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];

            // MARK: Add this to the data context and to the container for the sections collection view.
            [[datafield parentObjectLabelDataField] setInSection: nil];
            [[datafield parentObjectLabelDataField] setSectionIndexRow:@(0)];
            [[datafield parentObjectLabelDataField] setSectionIndexItem:@(0)];
            
        } completion:^(BOOL finished) {
            
            [[AppDelegate activeDocument] saveContext];
            
        }];

    }
}

- (void)elementDidFinishPan:(ElementView *)view {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    RptqDocumentObjectLabelDataField *datafield = [RptqDocumentObjectLabelDataField getLabelDataFieldForObjectID:[view objectID] fromObjectContext:managedObjectContext];
    
    if (datafield) {

        datafield.parentObjectLabelDataField.originx = @(view.frame.origin.x);
        datafield.parentObjectLabelDataField.originy = @(view.frame.origin.y);
        datafield.parentObjectLabelDataField.sizewidth = @(view.frame.size.width);
        datafield.parentObjectLabelDataField.sizeheight = @(view.frame.size.height);

        __block UICollectionView *svSection = [view containerView];
        
        [svSection performBatchUpdates:^{
            
            // MARK: Add this to the data context and to the container for the sections collection view.
            
            RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
            datafield.parentObjectLabelDataField.inSection = documentSection;
            
            NSIndexPath *indexPath = [svSection indexPathForItemAtPoint:[view center]];
            if (indexPath == nil) {
                indexPath = [svSection indexOfAlienViewWithCenterPoint:[view center]];
                if (indexPath == nil) {
                    indexPath = [NSIndexPath indexPathForItem:[svSection numberOfItemsInSection: 0] inSection:0];
                }
            }
            NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
            [svSection insertItemsAtIndexPaths:indexPaths];
            
            
            [[datafield parentObjectLabelDataField] setSectionIndexItem:@([indexPath item])];
            [[datafield parentObjectLabelDataField] setSectionIndexRow:@([indexPath section])];

            [view removeFromSuperview];
            
        } completion:^(BOOL finished) {
            
            [[AppDelegate activeDocument] saveContext];
            
        }];

    }
}

- (BOOL)elementDidRequestRemoval:(ElementView *)view {
    return NO;
}

#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 
 }
 */

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    UITableViewCell *result = nil;
    static NSString *MyIdentifier = @"UITableViewCell";
    result = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (result == nil) {
        result = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:MyIdentifier] autorelease];
        result.textLabel.text = @"What up!?!";
    }
    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows;
    switch (section) {
        case 0: {
            numberOfRows = 5;
            break;
        }            
        default:
            numberOfRows = 0;
            break;
    }
	return numberOfRows;
}

/*
 - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 NSString *result;
 switch (section) {
 case 0:
 result = @"";
 break;
 case 1:
 result = @"";
 break;
 default:
 result = @"";
 break;
 }
 return result;
 }
 */

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = 27.0000f;
    return result;
}

/*
 - (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { }
 */

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { }
 */

/*
 
 - (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 
 }
 */


/*
 - (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

@end