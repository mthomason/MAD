//
//  ReportDesignerTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerReportDesigner.h"

@interface MUIViewControllerReportDesigner()

@property (retain) NSMutableArray *scrollViewFrames;
@property (assign) BOOL formualInformationViewIsVisable;
@property (assign) BOOL imageInformationViewIsVisable;
@property (assign) BOOL labelInformationViewIsVisable;

@end

@implementation MUIViewControllerReportDesigner

- (void)dealloc {
    [_scrollViewFrames release];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextObjectsDidChangeNotification
                                                  object: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextObjectsDidChangeNotification
                                                  object: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
    [_svSections release];
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
    [[NSNotificationCenter defaultCenter] addObserver: self 
                                             selector: @selector(objectsDidChange:) 
                                                 name: NSManagedObjectContextObjectsDidChangeNotification 
                                               object: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self 
                                             selector: @selector(objectsDidSave:) 
                                                 name: NSManagedObjectContextDidSaveNotification 
                                               object: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
    
}

- (void)objectsDidSave:(NSNotification *)notification {

}

- (void)objectsDidChange:(NSNotification *)notification {
    if ([notification isKindOfClass:[NSNotification class]]) {
        NSDictionary *userInfo = [[notification userInfo] retain];
        NSLog(@"(contextChanged) Name:           %@", [notification name]);
        NSLog(@"(contextChanged) Object Class:   %@", NSStringFromClass( [[notification object] class] ));
        
        NSSet *inserted = [[userInfo objectForKey:NSInsertedObjectsKey] retain];
        for (id object in inserted) {
            NSLog(@"NSInsertedObjectsKey: %@", object);
            if ([object isKindOfClass:[RptqDocumentObjectLabelDataField class]]) {
                [self insertDocumentElementLabelDataField:object];
            }
        }
        [inserted release];

        NSSet *updated = [[userInfo objectForKey:NSUpdatedObjectsKey] retain];
        for (id object in updated) {
            if ([object isKindOfClass:[RptqDocumentObject class]]) {
                NSLog(@"NSUpdatedObjectsKey: %@", object);
                
            }
        }
        [updated release];
        
        NSSet *deleted = [[userInfo objectForKey:NSDeletedObjectsKey] retain];
        for (id object in deleted) {
            if ([object isKindOfClass:[RptqDocumentObject class]]) {
                NSLog(@"NSDeletedObjectsKey: %@", object);
                
            }
        }
        [deleted release];
        
        NSSet *refreshed = [[userInfo objectForKey:NSRefreshedObjectsKey] retain];
        for (id object in refreshed) {
            if ([object isKindOfClass:[RptqDocumentObject class]]) {
                NSLog(@"NSRefreshedObjectsKey: %@", object);
                
            }
        }
        [refreshed release];
        
        NSSet *invalidated = [[userInfo objectForKey:NSInvalidatedObjectsKey] retain];
        for (id object in invalidated) {
            if ([object isKindOfClass:[RptqDocumentObject class]]) {
                NSLog(@"NSInvalidatedObjectsKey: %@", object);
                
            }
        }
        [invalidated release];
        
        NSSet *invalidatedAll = [[userInfo objectForKey:NSInvalidatedAllObjectsKey] retain];
        for (id object in invalidatedAll) {
            if ([object isKindOfClass:[RptqDocumentObject class]]) {
                NSLog(@"NSInvalidatedAllObjectsKey: %@", object);
                
            }
        }
        [invalidatedAll release];
        
        [userInfo release];
    }
}

- (void)insertDocumentElement:(RptqDocumentObject *)documentObj {
    if (documentObj.isLabel) {
        
    } else if (documentObj.isLabelDataField) {
        [self insertDocumentElementLabelDataField: documentObj.isLabelDataField];        
    } else if (documentObj.isLabelLink) {
        
    } else if (documentObj.isFormula) {
        
    }
}

- (void)insertDocumentElementLabel:(RptqDocumentObjectLabel *)documentObj {

}

- (void)insertDocumentElementFormula:(RptqDocumentObjectFormula *)documentObj {
    
}

- (void)insertDocumentElementLabelDataField:(RptqDocumentObjectLabelDataField *)documentObj {
    if (![[self designScrollView] viewWithTag: [[documentObj objectID] hash]]) {
        CGRect f = CGRectMake([[documentObj.parentObjectLabelDataField originx] floatValue], [[documentObj.parentObjectLabelDataField originy] floatValue], [[documentObj.parentObjectLabelDataField sizewidth] floatValue], [[documentObj.parentObjectLabelDataField sizeheight] floatValue]);
        
        RptqDocumentSection *objSec = [[documentObj.parentObjectLabelDataField inSection] retain];
        if (objSec) {
            UIScrollView *scrollView = [[[self svSections] valueForKey: objSec.objectID.URIRepresentation.absoluteString] retain];
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
                [newView setContainerView: scrollView];
                [newView setTag: [[documentObj objectID] hash]];
                [scrollView addSubview: newView];
                [newView release];
                
            }
            [scrollView release];
        }
        [objSec release];
    }
}

- (void)insertDocumentElementLabelLink:(RptqDocumentObjectLabelLink *)documentObj {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGPoint origin = CGPointMake(5.0000f, 5.0000f);
    CGFloat paperWidth = CGFloatPointsForInches(8.5000f);
    CGRect frame = CGRectMake(origin.x, origin.y, paperWidth, CGSizeZero.height);
    
    CGFloat halfHeight = self.view.frame.size.height / 2;
    
    [self setToolboxOnScreen: CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + self.view.bounds.size.height - halfHeight, self.view.bounds.size.width, halfHeight)];
    [self setToolboxOffScreen: CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + self.view.bounds.size.height, self.view.bounds.size.width, halfHeight)];
    [self setDesignScrollViewNormal: [[self designScrollView] frame]];
    [self setDesignScrollViewWithToolbox: CGRectMake(self.designScrollViewNormal.origin.x, self.designScrollViewNormal.origin.y, self.designScrollViewNormal.size.width, self.designScrollViewNormal.size.height - halfHeight)];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[UIManagedDocumentReport activeDocument]];
    NSInteger ctr = 0;

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[enumerator count]];
    [self setSvSections: dict];
    [dict release];
    
    frame.size.height = 22.0000f;
    
    UIViewRuler *ruler = [[UIViewRuler alloc] initWithFrame: frame];
    [[self designScrollView] addSubview:ruler];
    [ruler release];
    
    frame.origin.y += frame.size.height + 10.0000f;
    
    for (RptqDocumentSection *sec in enumerator) {
        //NSLog(@"Ctr: %d, Type: %d", ctr, [[sec type] integerValue]);
        if (ctr > 0) frame.origin.y += frame.size.height + 10.0000f;
        frame.size.height = [[sec height] floatValue];
        
        [[self scrollViewFrames] addObject:[NSValue valueWithCGRect:frame]];
        
        UIScrollViewSection *scrollView = [[UIScrollViewSection alloc] initWithFrame:frame name:[sec localizedDisplayName] andObjectID:[sec objectID]];
        
        
        [[self designScrollView] addSubview:scrollView];
        [[self svSections] setValue:scrollView forKey:[[[sec objectID] URIRepresentation] absoluteString]];
        
        //NSLog(@"ScrollView %@", [[[sec objectID] URIRepresentation] absoluteString]);
        
        for (RptqDocumentObject *obj in [sec hasObjects]) {
            switch ([obj getType]) {
                case MNSObjectTypeLabel: {
                    if ([obj isLabel] != nil) {
                        
                    }
                    break;
                }
                case MNSObjectTypeLabelDataField: {
                    if ([obj isLabelDataField] != nil) {
                        [self insertDocumentElementLabelDataField:[obj isLabelDataField]];
                    }
                    break;
                }
                case MNSObjectTypeLabelFormula: {
                    if ([obj isFormula] != nil) {
                        
                    }
                    break;
                }
                case MNSObjectTypeLabelLabelLink: {
                    if ([obj isLabelLink] != nil) {
                        
                    }
                    break;
                }
                default: {
                    break;
                }
            }
        }
        
        [scrollView release];
        ctr++;
    }
    
    [enumerator release];

    [[self designScrollView] setScrollEnabled:YES];

    [[self designScrollView] setContentSize:CGSizeMake(paperWidth + 10.0000f, frame.origin.y + frame.size.height + 5.0000f)];
    [[self designScrollView] setBackgroundColor: [UIColor scrollViewTexturedBackgroundColor]];
    
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
    
    RptqDocument *doc = [RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
    if (doc) {
        
        NSEntityDescription *rdoEd = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                 inManagedObjectContext: [[UIManagedDocumentReport activeDocument] managedObjectContext]];

        NSEntityDescription *roldfEd = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabelDataField class])
                                                   inManagedObjectContext: [[UIManagedDocumentReport activeDocument] managedObjectContext]];

        RptqDocumentObject *dataObject = [[RptqDocumentObject alloc] initWithEntity: rdoEd
                                                     insertIntoManagedObjectContext: [[UIManagedDocumentReport activeDocument] managedObjectContext]];

        
        RptqDocumentObjectLabelDataField *reportObject = [[RptqDocumentObjectLabelDataField alloc] initWithEntity: roldfEd
                                                                            insertIntoManagedObjectContext: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
        dataObject.isLabelDataField = reportObject;
        [reportObject release];
        dataObject.isLabelDataField.text = [NSString stringWithFormat:@"%@.%@", [[field inTable] name], [field name]];
        
        dataObject.isLabelDataField.referencesField = field;
        dataObject.originx = [NSNumber numberWithFloat:CGPointZero.x];
        dataObject.originy = [NSNumber numberWithFloat:CGPointZero.y];
        dataObject.sizewidth = [NSNumber numberWithFloat:200.0000f];
        dataObject.sizeheight = [NSNumber numberWithFloat:44.0000f];
        dataObject.type = [NSNumber numberWithInteger: MNSObjectTypeLabelDataField];
        //dataObject.isLabelDataField = dataField;
        
        [[doc hasDetailSection] addHasObjectsObject:dataObject];
        
        [dataObject release];

        NSError *error = nil;
        [[[UIManagedDocumentReport activeDocument] managedObjectContext] save: &error];

        if (!error) {
            [[UIManagedDocumentReport activeDocument] saveToURL: [[UIManagedDocumentReport activeDocument] fileURL]
                                  forSaveOperation: UIDocumentSaveForOverwriting
                                 completionHandler: ^(BOOL success) {
                                     
                                     [dataObject release];
                                 }];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];    
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

- (void)elementDidFinishPan:(ElementView *)view {
    RptqDocumentObjectLabelDataField *datafield = [[RptqDocumentObjectLabelDataField labelDataFieldForManagedObjectContext:[[UIManagedDocumentReport activeDocument] managedObjectContext] withObjectID:[view objectID]] retain];
    if (datafield) {
        datafield.parentObjectLabelDataField.originx = [NSNumber numberWithFloat: view.frame.origin.x];
        datafield.parentObjectLabelDataField.originy = [NSNumber numberWithFloat: view.frame.origin.y];
        datafield.parentObjectLabelDataField.sizewidth = [NSNumber numberWithFloat: view.frame.size.width];
        datafield.parentObjectLabelDataField.sizeheight = [NSNumber numberWithFloat: view.frame.size.height];

        UIScrollViewSection *svSection = (UIScrollViewSection *)[[view containerView] retain];
        if (svSection) {
            RptqDocumentSection *documentSection = [[RptqDocumentSection sectionForManagedObjectContext:[[UIManagedDocumentReport activeDocument] managedObjectContext] withObjectID: [svSection objectID]] retain];
            NSLog(@"Document section: %@", [documentSection localizedDisplayName]);
            datafield.parentObjectLabelDataField.inSection = documentSection;
            [documentSection release];
        }
        [svSection release];
        

        NSError *error = nil;
        [[[UIManagedDocumentReport activeDocument] managedObjectContext] save: &error];
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            [[UIManagedDocumentReport activeDocument] saveToURL: [[UIManagedDocumentReport activeDocument] fileURL]
                                  forSaveOperation: UIDocumentSaveForOverwriting
                                 completionHandler: ^(BOOL success) {
                                     
                                     
                                 }];
        }
    }
    [datafield release];
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