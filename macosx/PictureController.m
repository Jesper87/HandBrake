/* $Id: PictureController.mm,v 1.11 2005/08/01 15:10:44 titer Exp $

 This file is part of the HandBrake source code.
 Homepage: <http://handbrake.fr/>.
 It may be used under the terms of the GNU General Public License. */

#import "Controller.h"
#import "PictureController.h"
#import "HBPreviewController.h"

@interface HBPictureController ()
{
    hb_title_t               * fTitle;

    HBPreviewController        * fPreviewController;

    /* Picture Sizing */
    IBOutlet NSTabView       * fSizeFilterView;
    IBOutlet NSBox           * fPictureSizeBox;
    IBOutlet NSBox           * fPictureCropBox;

    IBOutlet NSTextField     * fWidthField;
    IBOutlet NSStepper       * fWidthStepper;
    IBOutlet NSTextField     * fHeightField;
    IBOutlet NSStepper       * fHeightStepper;
    IBOutlet NSTextField     * fRatioLabel;
    IBOutlet NSButton        * fRatioCheck;
    IBOutlet NSMatrix        * fCropMatrix;
    IBOutlet NSTextField     * fCropTopField;
    IBOutlet NSStepper       * fCropTopStepper;
    IBOutlet NSTextField     * fCropBottomField;
    IBOutlet NSStepper       * fCropBottomStepper;
    IBOutlet NSTextField     * fCropLeftField;
    IBOutlet NSStepper       * fCropLeftStepper;
    IBOutlet NSTextField     * fCropRightField;
    IBOutlet NSStepper       * fCropRightStepper;

    IBOutlet NSTextField     * fModulusLabel;
    IBOutlet NSPopUpButton   * fModulusPopUp;

    IBOutlet NSTextField     * fDisplayWidthField;
    IBOutlet NSTextField     * fDisplayWidthLabel;

    IBOutlet NSTextField     * fParWidthField;
    IBOutlet NSTextField     * fParHeightField;
    IBOutlet NSTextField     * fParWidthLabel;
    IBOutlet NSTextField     * fParHeightLabel;

	IBOutlet NSPopUpButton   * fAnamorphicPopUp;
    IBOutlet NSTextField     * fSizeInfoField;

    /* Video Filters */
    IBOutlet NSBox           * fDetelecineBox;
    IBOutlet NSPopUpButton   * fDetelecinePopUp;

    IBOutlet NSBox           * fDecombDeinterlaceBox;
    IBOutlet NSSlider        * fDecombDeinterlaceSlider;

    IBOutlet NSBox           * fDecombBox;
    IBOutlet NSPopUpButton   * fDecombPopUp;

    IBOutlet NSBox           * fDeinterlaceBox;
    IBOutlet NSPopUpButton   * fDeinterlacePopUp;

    IBOutlet NSBox           * fDenoiseBox;
    IBOutlet NSPopUpButton   * fDenoisePopUp;

    IBOutlet NSBox           * fDeblockBox; // also holds the grayscale box
    IBOutlet NSTextField     * fDeblockField;
    IBOutlet NSSlider        * fDeblockSlider;

    IBOutlet NSButton        * fGrayscaleCheck;
}

- (void) tabView: (NSTabView *) tabView didSelectTabViewItem: (NSTabViewItem *) tabViewItem;

- (void) resizeInspectorForTab: (id) sender;

- (void) adjustSizingDisplay:(id) sender;
- (void) adjustFilterDisplay: (id) sender;

- (void) reloadStillPreview;

/* Internal Actions */
- (IBAction) settingsChanged: (id) sender;
- (IBAction) FilterSettingsChanged: (id) sender;
- (IBAction) modeDecombDeinterlaceSliderChanged: (id) sender;
- (IBAction) deblockSliderChanged: (id) sender;

@end

@implementation HBPictureController

- (id) init
{
	if (self = [super initWithWindowNibName:@"PictureSettings"])
	{
        // NSWindowController likes to lazily load its window. However since
        // this controller tries to set all sorts of outlets before the window
        // is displayed, we need it to load immediately. The correct way to do
        // this, according to the documentation, is simply to invoke the window
        // getter once.
        //
        // If/when we switch a lot of this stuff to bindings, this can probably
        // go away.
        [self window];

        _detelecineCustomString = @"";
        _deinterlaceCustomString = @"";
        _decombCustomString = @"";
        _denoiseCustomString = @"";

        fPreviewController = [[HBPreviewController alloc] init];
    }

	return self;
}

- (void) awakeFromNib
{
    [[self window] setDelegate:self];

    if( ![[self window] setFrameUsingName:@"PictureSizing"] )
        [[self window] center];

    [self setWindowFrameAutosaveName:@"PictureSizing"];
    [[self window] setExcludedFromWindowsMenu:YES];

    /* Populate the user interface */
    [fWidthStepper  setValueWraps: NO];
    [fWidthStepper  setIncrement: 16];
    [fWidthStepper  setMinValue: 64];
    [fHeightStepper setValueWraps: NO];
    [fHeightStepper setIncrement: 16];
    [fHeightStepper setMinValue: 64];

    [fCropTopStepper    setIncrement: 2];
    [fCropTopStepper    setMinValue:  0];
    [fCropBottomStepper setIncrement: 2];
    [fCropBottomStepper setMinValue:  0];
    [fCropLeftStepper   setIncrement: 2];
    [fCropLeftStepper   setMinValue:  0];
    [fCropRightStepper  setIncrement: 2];
    [fCropRightStepper  setMinValue:  0];

    /* Populate the Anamorphic NSPopUp button here */
    [fAnamorphicPopUp removeAllItems];
    [fAnamorphicPopUp addItemsWithTitles:@[@"None", @"Strict", @"Loose", @"Custom"]];

    /* populate the modulus popup here */
    [fModulusPopUp removeAllItems];
    [fModulusPopUp addItemsWithTitles:@[@"16", @"8", @"4", @"2"]];

    /* we use a popup to show the detelecine settings */
    [fDetelecinePopUp removeAllItems];
    [fDetelecinePopUp addItemsWithTitles:@[@"Off", @"Custom", @"Default"]];
    [fDetelecinePopUp selectItemAtIndex: self.detelecine];

    /* we use a popup to show the decomb settings */
	[fDecombPopUp removeAllItems];
    [fDecombPopUp addItemsWithTitles:@[@"Off", @"Custom", @"Default", @"Fast", @"Bob"]];
    [self modeDecombDeinterlaceSliderChanged:nil];
    [fDecombPopUp selectItemAtIndex: self.decomb];

    /* we use a popup to show the deinterlace settings */
	[fDeinterlacePopUp removeAllItems];
    [fDeinterlacePopUp addItemsWithTitles:@[@"Off", @"Custom", @"Fast", @"Slow", @"Slower", @"Bob"]];
    [fDeinterlacePopUp selectItemAtIndex: self.deinterlace];

    /* we use a popup to show the denoise settings */
	[fDenoisePopUp removeAllItems];
    [fDenoisePopUp addItemsWithTitles:@[@"Off", @"Custom", @"Weak", @"Medium", @"Strong"]];
    [fDenoisePopUp selectItemAtIndex: self.denoise];
}

- (void) setHandle: (hb_handle_t *) handle
{
    [fPreviewController setHandle: handle];
    [fPreviewController setDelegate:(HBController *)self.delegate];
}

- (void) setTitle: (hb_title_t *) title
{
    fTitle = title;

    if (!title) {
        [fPreviewController setTitle:NULL];
        return;
    }

    hb_job_t * job = title->job;

    fTitle = title;

    [fAnamorphicPopUp selectItemAtIndex: job->anamorphic.mode];
    if (job->anamorphic.mode == HB_ANAMORPHIC_STRICT)
    {
        [fWidthStepper  setEnabled: NO];
        [fHeightStepper setEnabled: NO];
    }
    else
    {
        [fWidthStepper  setEnabled: YES];
        [fHeightStepper setEnabled: YES];
    }
    if (job->anamorphic.mode == HB_ANAMORPHIC_STRICT ||
        job->anamorphic.mode == HB_ANAMORPHIC_LOOSE)
    {
        job->anamorphic.keep_display_aspect = 1;
        [fRatioCheck    setState:   NSOnState];
        [fRatioCheck    setEnabled: NO];
    }
    else
    {
        [fRatioCheck    setEnabled: YES];
        [fRatioCheck setState:   job->anamorphic.keep_display_aspect ?
                                                        NSOnState : NSOffState];
    }
    [fParWidthField setEnabled:     !job->anamorphic.keep_display_aspect];
    [fParHeightField setEnabled:    !job->anamorphic.keep_display_aspect];
    [fDisplayWidthField setEnabled: !job->anamorphic.keep_display_aspect];

    if (job->modulus)
    {
        [fModulusPopUp selectItemWithTitle: [NSString stringWithFormat:@"%d",job->modulus]];
        [fWidthStepper  setIncrement: job->modulus];
        [fHeightStepper setIncrement: job->modulus];
    }
    else
    {
        [fModulusPopUp selectItemAtIndex: 0];
        [fWidthStepper  setIncrement: 16];
        [fHeightStepper setIncrement: 16];
    }
    if (!self.autoCrop)
    {
        [fCropMatrix  selectCellAtRow: 1 column:0];
        [fCropTopStepper    setIntValue: job->crop[0]];
        [fCropTopField      setIntValue: job->crop[0]];
        [fCropBottomStepper setIntValue: job->crop[1]];
        [fCropBottomField   setIntValue: job->crop[1]];
        [fCropLeftStepper   setIntValue: job->crop[2]];
        [fCropLeftField     setIntValue: job->crop[2]];
        [fCropRightStepper  setIntValue: job->crop[3]];
        [fCropRightField    setIntValue: job->crop[3]];
    }
    else
    {
        [fCropMatrix  selectCellAtRow: 0 column:0];

        [fCropTopStepper    setEnabled: !self.autoCrop];
        [fCropBottomStepper setEnabled: !self.autoCrop];
        [fCropLeftStepper   setEnabled: !self.autoCrop];
        [fCropRightStepper  setEnabled: !self.autoCrop];

        /* If auto, lets set the crop steppers according to
         * current fTitle->crop values */
        memcpy( job->crop, fTitle->crop, 4 * sizeof( int ) );
        [fCropTopStepper    setIntValue: fTitle->crop[0]];
        [fCropTopField      setIntValue: fTitle->crop[0]];
        [fCropBottomStepper setIntValue: fTitle->crop[1]];
        [fCropBottomField   setIntValue: fTitle->crop[1]];
        [fCropLeftStepper   setIntValue: fTitle->crop[2]];
        [fCropLeftField     setIntValue: fTitle->crop[2]];
        [fCropRightStepper  setIntValue: fTitle->crop[3]];
        [fCropRightField    setIntValue: fTitle->crop[3]];
    }
    [fWidthStepper      setMaxValue: title->width - job->crop[2] - job->crop[3]];
    [fWidthStepper      setIntValue: job->width];
    [fWidthField        setIntValue: job->width];
    [fHeightStepper     setMaxValue: title->height - job->crop[0] - job->crop[1]];
    [fHeightStepper     setIntValue: job->height];
    [fHeightField       setIntValue: job->height];
    [fCropTopStepper    setMaxValue: title->height/2-2];
    [fCropBottomStepper setMaxValue: title->height/2-2];
    [fCropLeftStepper   setMaxValue: title->width/2-2];
    [fCropRightStepper  setMaxValue: title->width/2-2];

    [fParWidthField     setIntValue: job->anamorphic.par_width];
    [fParHeightField    setIntValue: job->anamorphic.par_height];

    int display_width;
    display_width = job->width * job->anamorphic.par_width /
                                 job->anamorphic.par_height;
    [fDisplayWidthField setIntValue: display_width];


    /* Set filters widgets according to the filters struct */
    [fDetelecinePopUp selectItemAtIndex:self.detelecine];
    [fDecombPopUp selectItemAtIndex:self.decomb];
    [fDeinterlacePopUp selectItemAtIndex: self.deinterlace];
    [fDenoisePopUp selectItemAtIndex: self.denoise];
    [fDeblockSlider setFloatValue:self.deblock];
    [fGrayscaleCheck setState:self.grayscale];

    [self deblockSliderChanged: nil];

    [fPreviewController setTitle:title];

    [self FilterSettingsChanged:nil];
    [self settingsChanged:nil];
}

#pragma mark -
#pragma mark Interface Resize

/**
 * resizeInspectorForTab is called at launch, and each time either the
 * Size or Filters tab is clicked. Size gives a horizontally oriented
 * inspector and Filters is a vertically aligned inspector.
 */
- (void) resizeInspectorForTab: (id) sender
{
    NSRect frame = [[self window] frame];
    NSSize screenSize = [[[self window] screen] frame].size;
    NSPoint screenOrigin = [[[self window] screen] frame].origin;

    /* We base our inspector size/layout on which tab is active for fSizeFilterView */
    /* we are 1 which is Filters*/
    if ([fSizeFilterView indexOfTabViewItem: [fSizeFilterView selectedTabViewItem]] == 1)
    {
        frame.size.width = 314;
        /* we glean the height from the size of the boxes plus the extra window space
         * needed for non boxed display
         */
        frame.size.height = 110.0 + [fDetelecineBox frame].size.height + [fDecombDeinterlaceBox frame].size.height + [fDenoiseBox frame].size.height + [fDeblockBox frame].size.height;
        /* Hide the size readout at the bottom as the vertical inspector is not wide enough */
        [fSizeInfoField setHidden:YES];
    }
    else // we are Tab index 0 which is size
    {
        frame.size.width = 30.0 + [fPictureSizeBox frame].size.width + [fPictureCropBox frame].size.width;
        frame.size.height = [fPictureSizeBox frame].size.height + 90;
        /* hide the size summary field at the bottom */
        [fSizeInfoField setHidden:NO];
    }
    /* get delta's for the change in window size */
    CGFloat deltaX = frame.size.width - [[self window] frame].size.width;
    CGFloat deltaY = frame.size.height - [[self window] frame].size.height;

    /* change the inspector origin via the deltaY */
    frame.origin.y -= deltaY;
    /* keep the inspector centered so the tabs stay in place */
    frame.origin.x -= deltaX / 2.0;

    /* we make sure we are not horizontally off of our screen.
     * this would be the case if we are on the vertical filter tab
     * and we hit the size tab and the inspector grows horizontally
     * off the screen to the right
     */
    if ((frame.origin.x + frame.size.width) > (screenOrigin.x + screenSize.width))
    {
        /* the right side of the preview is off the screen, so shift to the left */
        frame.origin.x = (screenOrigin.x + screenSize.width) - frame.size.width;
    }

    [[self window] setFrame:frame display:YES animate:YES];
}

- (void) adjustSizingDisplay: (id) sender
{
    NSSize pictureSizingBoxSize = [fPictureSizeBox frame].size;

    NSPoint fPictureSizeBoxOrigin = [fPictureSizeBox frame].origin;
    NSSize pictureCropBoxSize = [fPictureCropBox frame].size;
    NSPoint fPictureCropBoxOrigin = [fPictureCropBox frame].origin;

    if ([fAnamorphicPopUp indexOfSelectedItem] == HB_ANAMORPHIC_CUSTOM)
    {   // custom / power user jamboree
        pictureSizingBoxSize.width = 350;

        /* Set visibility of capuj widgets */
        [fParWidthField setHidden: NO];
        [fParHeightField setHidden: NO];
        [fParWidthLabel setHidden: NO];
        [fParHeightLabel setHidden: NO];
        [fDisplayWidthField setHidden: NO];
        [fDisplayWidthLabel setHidden: NO];
    }
    else
    {
        pictureSizingBoxSize.width = 200;

        /* Set visibility of capuj widgets */
        [fParWidthField setHidden: YES];
        [fParHeightField setHidden: YES];
        [fParWidthLabel setHidden: YES];
        [fParHeightLabel setHidden: YES];
        [fDisplayWidthField setHidden: YES];
        [fDisplayWidthLabel setHidden: YES];
    }

    /* Check to see if we have changed the size from current */
    if (pictureSizingBoxSize.height != [fPictureSizeBox frame].size.height ||
        pictureSizingBoxSize.width != [fPictureSizeBox frame].size.width)
    {
        /* Get our delta for the change in picture size box height */
        CGFloat deltaYSizeBoxShift = pictureSizingBoxSize.height -
                                     [fPictureSizeBox frame].size.height;
        fPictureSizeBoxOrigin.y -= deltaYSizeBoxShift;
        /* Get our delta for the change in picture size box width */
        CGFloat deltaXSizeBoxShift = pictureSizingBoxSize.width -
                                     [fPictureSizeBox frame].size.width;
        //fPictureSizeBoxOrigin.x += deltaXSizeBoxShift;
        /* set our new Picture size box size */
        [fPictureSizeBox setFrameSize:pictureSizingBoxSize];
        [fPictureSizeBox setFrameOrigin:fPictureSizeBoxOrigin];

        pictureCropBoxSize.height += deltaYSizeBoxShift;
        fPictureCropBoxOrigin.y -= deltaYSizeBoxShift;
        fPictureCropBoxOrigin.x += deltaXSizeBoxShift;

        [fPictureCropBox setFrameSize:pictureCropBoxSize];
        [[fPictureCropBox animator] setFrameOrigin:fPictureCropBoxOrigin];
    }

    /* now we call to resize the entire inspector window */
    [self resizeInspectorForTab:nil];
}

- (void) adjustFilterDisplay: (id) sender
{
    NSBox *filterBox = nil;
    if (sender == fDetelecinePopUp)
    {
        filterBox = fDetelecineBox;
    }

    if (sender == fDecombDeinterlaceSlider)
    {
        if ([fDecombDeinterlaceSlider floatValue] == 0.0)
        {
            filterBox = fDecombBox;
        }
        else
        {
            filterBox = fDeinterlaceBox;
        }
    }

    if (sender == fDecombPopUp)
    {
        filterBox = fDecombBox;
    }

    if (sender == fDeinterlacePopUp)
    {
        filterBox = fDeinterlaceBox;
    }

    if (sender == fDenoisePopUp)
    {
        filterBox = fDenoiseBox;
    }

    NSSize currentSize = [filterBox frame].size;
    NSRect boxFrame = [filterBox frame];

    if ([[sender titleOfSelectedItem]  isEqualToString: @"Custom"])
    {
        currentSize.height = 60;
    }
    else
    {
        currentSize.height = 36;
    }

    /* Check to see if we have changed the size from current */
    if (currentSize.height != [filterBox frame].size.height)
    {
        /* We are changing the size of the box, so recalc the origin */
        NSPoint boxOrigin = [filterBox frame].origin;
        /* We get the deltaY here for how much we are expanding/contracting the box vertically */
        CGFloat deltaYBoxShift = currentSize.height - [filterBox frame].size.height;
        boxOrigin.y -= deltaYBoxShift;

        boxFrame.size.height = currentSize.height;
        boxFrame.origin.y = boxOrigin.y;
        [filterBox setFrame:boxFrame];

        if (filterBox == fDecombBox || filterBox == fDeinterlaceBox)
        {
            /* fDecombDeinterlaceBox*/
            NSSize decombDeinterlaceBoxSize = [fDecombDeinterlaceBox frame].size;
            NSPoint decombDeinterlaceBoxOrigin = [fDecombDeinterlaceBox frame].origin;

            if ([fDeinterlaceBox isHidden] == YES)
            {
                decombDeinterlaceBoxSize.height = [fDecombBox frame].size.height + 50;
            }
            else
            {
                decombDeinterlaceBoxSize.height = [fDeinterlaceBox frame].size.height + 50;
            }
            /* get delta's for the change in window size */

            CGFloat deltaYdecombDeinterlace = decombDeinterlaceBoxSize.height - [fDecombDeinterlaceBox frame].size.height;

            deltaYBoxShift = deltaYdecombDeinterlace;

            decombDeinterlaceBoxOrigin.y -= deltaYdecombDeinterlace;

            [fDecombDeinterlaceBox setFrameSize:decombDeinterlaceBoxSize];
            [fDecombDeinterlaceBox setFrameOrigin:decombDeinterlaceBoxOrigin];
        }

        /* now we must reset the origin of each box below the adjusted box*/
        NSPoint decombDeintOrigin = [fDecombDeinterlaceBox frame].origin;
        NSPoint denoiseOrigin = [fDenoiseBox frame].origin;
        NSPoint deblockOrigin = [fDeblockBox frame].origin;
        if (sender == fDetelecinePopUp)
        {
            decombDeintOrigin.y -= deltaYBoxShift;
            [fDecombDeinterlaceBox setFrameOrigin:decombDeintOrigin];

            denoiseOrigin.y -= deltaYBoxShift;
            [fDenoiseBox setFrameOrigin:denoiseOrigin];

            deblockOrigin.y -= deltaYBoxShift;
            [fDeblockBox setFrameOrigin:deblockOrigin];
        }
        if (sender == fDecombPopUp || sender == fDeinterlacePopUp)
        {
            denoiseOrigin.y -= deltaYBoxShift;
            [fDenoiseBox setFrameOrigin:denoiseOrigin];

            deblockOrigin.y -= deltaYBoxShift;
            [fDeblockBox setFrameOrigin:deblockOrigin];
        }

        if (sender == fDenoisePopUp)
        {
            deblockOrigin.y -= deltaYBoxShift;
            [fDeblockBox setFrameOrigin:deblockOrigin];
        }

        /* now we call to resize the entire inspector window */
        [self resizeInspectorForTab:nil];
    }
}

- (NSString *) pictureSizeInfoString
{
    return [fSizeInfoField stringValue];
}

- (void) reloadStillPreview
{
    [fPreviewController reload];
}

#pragma mark -

/**
 * Displays and brings the picture window to the front
 */
- (IBAction) showPictureWindow: (id) sender
{
    if ([[self window] isVisible])
    {
        [[self window] close];
    }
    else
    {
        [self showWindow:sender];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PictureSizeWindowIsOpen"];
        /* Set the window back to Floating Window mode
         * This will put the window always on top, but
         * since we have Hide on Deactivate set in our
         * xib, if other apps are put in focus we will
         * hide properly to stay out of the way
         */
        [[self window] setLevel:NSFloatingWindowLevel];
    }

    [self adjustFilterDisplay:nil];
    [self adjustSizingDisplay:nil];
}

- (IBAction) showPreviewWindow: (id) sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PreviewWindowIsOpen"];
    [fPreviewController showWindow:sender];
}

- (void) windowWillClose: (NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PictureSizeWindowIsOpen"];
}

- (BOOL) windowShouldClose: (id) sender
{
    return YES;
}

/**
 * This method is used to detect clicking on a tab in fSizeFilterView
 */
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self resizeInspectorForTab:nil];
}

- (void) dealloc
{
    [fPreviewController release];
    [super dealloc];
}

#pragma mark -
#pragma mark Interface Update Logic

- (IBAction) settingsChanged: (id) sender
{
    if (!fTitle)
        return;

    hb_job_t * job = fTitle->job;
    int keep = 0, dar_updated = 0;

    if (sender == fAnamorphicPopUp)
    {
        job->anamorphic.mode = (int)[fAnamorphicPopUp indexOfSelectedItem];
        if (job->anamorphic.mode == HB_ANAMORPHIC_STRICT)
        {
            [fModulusLabel  setHidden:  YES];
            [fModulusPopUp  setHidden:  YES];
            [fWidthStepper  setEnabled: NO];
            [fHeightStepper setEnabled: NO];
        }
        else
        {
            [fModulusLabel  setHidden:  NO];
            [fModulusPopUp  setHidden:  NO];
            [fWidthStepper  setEnabled: YES];
            [fHeightStepper setEnabled: YES];
        }
        if (job->anamorphic.mode == HB_ANAMORPHIC_STRICT ||
            job->anamorphic.mode == HB_ANAMORPHIC_LOOSE)
        {
            job->anamorphic.keep_display_aspect = 1;
            [fRatioCheck setState: NSOnState];
            [fRatioCheck setEnabled: NO];
        }
        else
        {
            [fRatioCheck setEnabled: YES];
            [fRatioCheck setState:   job->anamorphic.keep_display_aspect ?
                                                        NSOnState : NSOffState];
        }
    }
    else if (sender == fModulusPopUp)
    {
        job->modulus = [[fModulusPopUp titleOfSelectedItem] intValue];
        [fWidthStepper  setIncrement: job->modulus];
        [fHeightStepper setIncrement: job->modulus];
    }

    if (sender == fRatioCheck)
    {
        job->anamorphic.keep_display_aspect = [fRatioCheck  state] == NSOnState;
        [fParWidthField setEnabled:     !job->anamorphic.keep_display_aspect];
        [fParHeightField setEnabled:    !job->anamorphic.keep_display_aspect];
        [fDisplayWidthField setEnabled: !job->anamorphic.keep_display_aspect];
    }

    if (sender == fHeightStepper)
    {
        keep |= HB_KEEP_HEIGHT;
        job->height = [fHeightStepper intValue];
    }

    if (sender == fWidthStepper)
    {
        keep |= HB_KEEP_WIDTH;
        job->width = [fWidthStepper intValue];
    }

    if (sender == fParWidthField || sender == fParHeightField)
    {
        job->anamorphic.par_width = [fParWidthField intValue];
        job->anamorphic.par_height = [fParHeightField intValue];
    }

    if (sender == fDisplayWidthField)
    {
        dar_updated = 1;
        job->anamorphic.dar_width = [fDisplayWidthField intValue];
        job->anamorphic.dar_height = [fHeightStepper intValue];
    }

    if (sender == fCropMatrix)
    {
        if (self.autoCrop != ( [fCropMatrix selectedRow] == 0 ))
        {
            self.autoCrop = !self.autoCrop;
            if (self.autoCrop)
            {
                /* If auto, lets set the crop steppers according to
                 * current fTitle->crop values */
                memcpy( job->crop, fTitle->crop, 4 * sizeof( int ) );
                [fCropTopStepper    setIntValue: fTitle->crop[0]];
                [fCropTopField      setIntValue: fTitle->crop[0]];
                [fCropBottomStepper setIntValue: fTitle->crop[1]];
                [fCropBottomField   setIntValue: fTitle->crop[1]];
                [fCropLeftStepper   setIntValue: fTitle->crop[2]];
                [fCropLeftField     setIntValue: fTitle->crop[2]];
                [fCropRightStepper  setIntValue: fTitle->crop[3]];
                [fCropRightField    setIntValue: fTitle->crop[3]];
            }
            [fCropTopStepper    setEnabled: !self.autoCrop];
            [fCropBottomStepper setEnabled: !self.autoCrop];
            [fCropLeftStepper   setEnabled: !self.autoCrop];
            [fCropRightStepper  setEnabled: !self.autoCrop];
        }
    }
    if (sender == fCropTopStepper)
    {
        job->crop[0] = [fCropTopStepper    intValue];
        [fCropTopField setIntValue: job->crop[0]];
        [fHeightStepper setMaxValue: fTitle->height - job->crop[0] - job->crop[1]];
    }
    if (sender == fCropBottomStepper)
    {
        job->crop[1] = [fCropBottomStepper intValue];
        [fCropBottomField setIntValue: job->crop[1]];
        [fHeightStepper setMaxValue: fTitle->height - job->crop[0] - job->crop[1]];
    }
    if (sender == fCropLeftStepper)
    {
        job->crop[2] = [fCropLeftStepper   intValue];
        [fCropLeftField setIntValue: job->crop[2]];
        [fWidthStepper setMaxValue: fTitle->width - job->crop[2] - job->crop[3]];
    }
    if (sender == fCropRightStepper)
    {
        job->crop[3] = [fCropRightStepper  intValue];
        [fCropRightField setIntValue: job->crop[3]];
        [fWidthStepper setMaxValue: fTitle->width - job->crop[2] - job->crop[3]];
    }

    keep |= !!job->anamorphic.keep_display_aspect * HB_KEEP_DISPLAY_ASPECT;

    hb_geometry_t srcGeo, resultGeo;
    hb_ui_geometry_t uiGeo;

    srcGeo.width = fTitle->width;
    srcGeo.height = fTitle->height;
    srcGeo.par.num = fTitle->pixel_aspect_width;
    srcGeo.par.den = fTitle->pixel_aspect_height;

    uiGeo.mode = job->anamorphic.mode;
    uiGeo.keep = keep;
    uiGeo.itu_par = 0;
    uiGeo.modulus = job->modulus;
    memcpy(uiGeo.crop, job->crop, sizeof(int[4]));
    uiGeo.width = job->width;
    uiGeo.height =  job->height;
    uiGeo.maxWidth = fTitle->width - job->crop[2] - job->crop[3];
    uiGeo.maxHeight = fTitle->height - job->crop[0] - job->crop[1];
    uiGeo.par.num = job->anamorphic.par_width;
    uiGeo.par.den = job->anamorphic.par_height;
    uiGeo.dar.num = 0;
    uiGeo.dar.den = 0;
    if (job->anamorphic.mode == HB_ANAMORPHIC_CUSTOM && dar_updated)
    {
        uiGeo.dar.num = job->anamorphic.dar_width;
        uiGeo.dar.den = job->anamorphic.dar_height;
    }
    hb_set_anamorphic_size2(&srcGeo, &uiGeo, &resultGeo);

    job->width = resultGeo.width;
    job->height = resultGeo.height;
    job->anamorphic.par_width = resultGeo.par.num;
    job->anamorphic.par_height = resultGeo.par.den;

    int display_width;
    display_width = resultGeo.width * resultGeo.par.num / resultGeo.par.den;

    [fWidthStepper      setIntValue: resultGeo.width];
    [fWidthField        setIntValue: resultGeo.width];
    [fHeightStepper     setIntValue: resultGeo.height];
    [fHeightField       setIntValue: resultGeo.height];
    [fParWidthField     setIntValue: resultGeo.par.num];
    [fParHeightField    setIntValue: resultGeo.par.den];
    [fDisplayWidthField setIntValue: display_width];

    /*
     * Sanity-check here for previews < 16 pixels to avoid crashing
     * hb_get_preview(). In fact, let's get previews at least 64 pixels in both
     * dimensions; no human can see any meaningful detail below that.
     */
    if (job->width >= 64 && job->height >= 64)
    {
        [self reloadStillPreview];
    }

    /* we get the sizing info to display from fPreviewController */
    [fSizeInfoField setStringValue: [fPreviewController pictureSizeInfoString]];

    if (sender != nil)
    {
        [self.delegate pictureSettingsDidChange];
    }

    if ([[self window] isVisible])
    {
        [self adjustSizingDisplay:nil];
    }
}

- (IBAction) modeDecombDeinterlaceSliderChanged: (id) sender
{
    /* since its a tickless slider, we have to  make sure we are on or off */
    if ([fDecombDeinterlaceSlider floatValue] < 0.50)
    {
        [fDecombDeinterlaceSlider setFloatValue:0.0];
    }
    else
    {
        [fDecombDeinterlaceSlider setFloatValue:1.0];
    }

    /* Decomb selected*/
    if ([fDecombDeinterlaceSlider floatValue] == 0.0)
    {
        [fDecombBox setHidden:NO];
        [fDeinterlaceBox setHidden:YES];
        self.decomb = [fDecombPopUp indexOfSelectedItem];
        _useDecomb = 1;
        self.deinterlace = 0;
        [fDecombPopUp selectItemAtIndex:self.decomb];
        [self adjustFilterDisplay:fDecombPopUp];
    }
    else
    {
        [fDecombBox setHidden:YES];
        [fDeinterlaceBox setHidden:NO];
        _useDecomb = 0;
        self.decomb = 0;
        [fDeinterlacePopUp selectItemAtIndex: self.deinterlace];
        [self adjustFilterDisplay:fDeinterlacePopUp];
    }

    [self FilterSettingsChanged: fDecombDeinterlaceSlider];
}


- (IBAction) FilterSettingsChanged: (id) sender
{
    if (!fTitle)
        return;

    self.detelecine  = [fDetelecinePopUp indexOfSelectedItem];
    [self adjustFilterDisplay:fDetelecinePopUp];

    self.decomb = [fDecombPopUp indexOfSelectedItem];
    [self adjustFilterDisplay:fDecombPopUp];

    self.deinterlace = [fDeinterlacePopUp indexOfSelectedItem];
    [self adjustFilterDisplay:fDeinterlacePopUp];

    self.denoise = [fDenoisePopUp indexOfSelectedItem];
    [self adjustFilterDisplay:fDenoisePopUp];

    if ([[fDeblockField stringValue] isEqualToString:@"Off"])
    {
        self.deblock  = 0;
    }
    else
    {
        self.deblock  = [fDeblockField intValue];
    }

    // Tell PreviewController whether it should deinterlace
    // the previews or not
    if ((self.deinterlace && !self.useDecomb) ||
        (self.decomb && self.useDecomb))
    {
        fPreviewController.deinterlacePreview = YES;
    }
    else
    {
        fPreviewController.deinterlacePreview = NO;
    }

    self.grayscale = [fGrayscaleCheck state];

    if (sender != nil)
    {
        [self.delegate pictureSettingsDidChange];
        [self reloadStillPreview];
    }
}

- (IBAction) deblockSliderChanged: (id) sender
{
    if ([fDeblockSlider floatValue] == 4.0)
    {
        [fDeblockField setStringValue: @"Off"];
    }
    else
    {
        [fDeblockField setStringValue: [NSString stringWithFormat: @"%.0f", [fDeblockSlider floatValue]]];
    }
	[self FilterSettingsChanged: sender];
}

#pragma mark -

- (void) setUseDecomb: (NSInteger) setting
{
    _useDecomb = setting;
    if (self.useDecomb == 1)
    {
        [fDecombDeinterlaceSlider setFloatValue:0.0];
    }
    else
    {
        [fDecombDeinterlaceSlider setFloatValue:1.0];
    }
    
    [self modeDecombDeinterlaceSliderChanged:nil];
}

@end
