// Copyright (c) 2009 Imageshack Corp.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 

#import "TwitEditorController.h"
#import "LoginController.h"
#import "MGTwitterEngine.h"
#import "TweetterAppDelegate.h"
#import "LocationManager.h"
#include "util.h"
#import "TweetQueue.h"

#define SEND_SEGMENT_CNTRL_WIDTH			130
#define FIRST_SEND_SEGMENT_WIDTH			 66

#define IMAGES_SEGMENT_CONTROLLER_TAG		487
#define SEND_TWIT_SEGMENT_CONTROLLER_TAG	 42

#define PROGRESS_ACTION_SHEET_TAG										214
#define PHOTO_Q_SHEET_TAG												436
#define PROCESSING_PHOTO_SHEET_TAG										3

#define PHOTO_ENABLE_SERVICES_ALERT_TAG									666
#define PHOTO_DO_CANCEL_ALERT_TAG										13

@implementation ImagePickerController

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:NO];
	[twitEditor startUploadingOfPickedImageIfNeed];
//	NSLog(@"viewDidDisappear");
}

@end

@implementation TwitEditorController

@synthesize progressSheet;
@synthesize currentImageYFrogURL;
@synthesize connectionDelegate;
@synthesize _message;

- (void)setCharsCount
{
	charsCount.text = [NSString stringWithFormat:@"%d", MAX_SYMBOLS_COUNT_IN_TEXT_VIEW - [messageText.text length]];

}

- (void) setNavigatorButtons
{
//	if(self.navigationItem.backBarButtonItem != cancelButton)
//			self.navigationItem.backBarButtonItem = cancelButton;
	if(self.navigationItem.leftBarButtonItem != cancelButton)
	{
		[[self navigationItem] setLeftBarButtonItem:cancelButton animated:YES];
		if([self.navigationController.viewControllers count] == 1)
			cancelButton.title = NSLocalizedString(@"Clear", @"");
		else
			cancelButton.title = NSLocalizedString(@"Cancel", @"");
	}	
		
/*	if(inTextEditingMode)
	{
		if(self.navigationItem.rightBarButtonItem != doneEditButton)
			[[self navigationItem] setRightBarButtonItem:doneEditButton animated:YES];
	}
	else*/
	if(image.image || [[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
	{
		if(self.navigationItem.rightBarButtonItem != segmentBarItem)
			self.navigationItem.rightBarButtonItem = segmentBarItem;
		
	}
	else
	{
		if(self.navigationItem.rightBarButtonItem)
			[[self navigationItem] setRightBarButtonItem:nil animated:YES];
	}



/*	if(self.navigationItem.leftBarButtonItem != pickImageButton)
	{
		[[self navigationItem] setLeftBarButtonItem:pickImageButton animated:YES];
	}*/

//	self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"Back", @"");
//	self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Back", @"");

/*	NSString* secondSegTitle = nil;
	if(inTextEditingMode)
	{
		secondSegTitle = NSLocalizedString(@"Done", "");
		if([postImageSegmentedControl numberOfSegments] == 1)
			[postImageSegmentedControl insertSegmentWithTitle:secondSegTitle atIndex:1 animated:YES];
		else if (![[postImageSegmentedControl titleForSegmentAtIndex:1] isEqualToString:secondSegTitle])
			[postImageSegmentedControl setTitle:secondSegTitle forSegmentAtIndex:1];
	}
	else if(image.image)
	{
		secondSegTitle = NSLocalizedString(@"Send", "");
		if([postImageSegmentedControl numberOfSegments] == 1)
			[postImageSegmentedControl insertSegmentWithTitle:secondSegTitle atIndex:1 animated:YES];
		else if (![[postImageSegmentedControl titleForSegmentAtIndex:1] isEqualToString:secondSegTitle])
			[postImageSegmentedControl setTitle:secondSegTitle forSegmentAtIndex:1];
	}
	else
	{
		while([postImageSegmentedControl numberOfSegments] > 1)
			[postImageSegmentedControl removeSegmentAtIndex:[postImageSegmentedControl numberOfSegments] - 1 animated:YES];
	}

	if([postImageSegmentedControl numberOfSegments] == 1)
		[postImageSegmentedControl setWidth:SEGMENT_CNTRL_WIDTH forSegmentAtIndex:0];
	else
		[postImageSegmentedControl setWidth:FIRST_SEGMENT_WIDTH forSegmentAtIndex:0];*/

//return;	
/*	if(inTextEditingMode)
	{
		if(self.navigationItem.rightBarButtonItem != doneEditButton)
			[[self navigationItem] setRightBarButtonItem:doneEditButton animated:YES];
	}
	else if(image.image)
	{
		if(self.navigationItem.rightBarButtonItem != sendButton)
			[[self navigationItem] setRightBarButtonItem:sendButton animated:YES];
	}
	else
	{
		if(self.navigationItem.rightBarButtonItem)
			[[self navigationItem] setRightBarButtonItem:nil animated:YES];
	}*/
	
//	[UIView beginAnimations:nil context:nil];
//	[UIView setAnimationDuration:0.2];  
//	[UIView commitAnimations];

}

- (void)setMessageTextText:(NSString*)newText
{
	messageText.text = newText;
	[self setCharsCount];
	[self setNavigatorButtons];
}


- (void) setURLPlaceholder
{
	NSRange urlPlaceHolderRange = [messageText.text rangeOfString:urlPlaceholderMask];
	if(image.image)
	{
		if(urlPlaceHolderRange.location == NSNotFound)
		{
			NSString *newText = messageText.text;
			if(![newText hasSuffix:@"\n"])
				newText = [newText stringByAppendingString:@"\n"];
			[self setMessageTextText:[newText stringByAppendingString:urlPlaceholderMask]];
//			messageText.text = [newText stringByAppendingString:urlPlaceholderMask];
		}
	}
	else
	{
		if(urlPlaceHolderRange.location != NSNotFound)
			[self setMessageTextText:[messageText.text stringByReplacingCharactersInRange:urlPlaceHolderRange withString:@""]];
//			messageText.text = [messageText.text stringByReplacingCharactersInRange:urlPlaceHolderRange withString:@""];
	}
}

/*
-(id)init
{
	self = [super init];
	if(self)
	{
		inTextEditingMode = NO;
		suspendedOperation = noOperations;
		urlPlaceholderMask = [NSLocalizedString(@"YFrog image URL placeholder", @"") retain];
	}
	return self;
}
*/

- (void)initData
{
	_twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
	inTextEditingMode = NO;
	suspendedOperation = noTEOperations;
	urlPlaceholderMask = [NSLocalizedString(@"YFrog image URL placeholder", @"") retain];
	messageTextWillIgnoreNextViewAppearing = NO;
	twitWasChangedManually = NO;
	_queueIndex = -1;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setQueueTitle) name:@"QueueChanged" object:nil];
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
	self = [super initWithNibName:nibName bundle:nibBundle];
	if(self)
		[self initData];

	return self;
}

- (id)init
{
	return [self initWithNibName:@"PostImage" bundle:nil];
}

-(void)dismissProgressSheetIfExist
{
	if(self.progressSheet)
	{
//		if(self.progressSheet.visible)
		[self.progressSheet dismissWithClickedButtonIndex:0 animated:YES];
		self.progressSheet = nil;
	}
}

- (void)dealloc 
{
	//	[imgPicker release];
	//	[[NSNotificationCenter defaultCenter] removeObserver:self];
	while (_indicatorCount) 
	{
		[self releaseActivityIndicator];
	}

//	int connectionsCount = [_twitter numberOfConnections];
	[_twitter closeAllConnections];
	[_twitter removeDelegate];
	[_twitter release];
//	while(connectionsCount-- > 0)
//		[TweetterAppDelegate decreaseNetworkActivityIndicator];

	[_indicator release];

	[defaultTintColor release];
	[segmentBarItem release];
	[urlPlaceholderMask release];
	self.currentImageYFrogURL = nil;
	self.connectionDelegate = nil;
	self._message = nil;
//	self.mgTwitterConnectionID = nil;
	[self dismissProgressSheetIfExist];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
}
*/

- (void)setQueueTitle
{
	int count = [[TweetQueue sharedQueue] count];
	NSString *title = nil;
	if(count)
		title = [NSString stringWithFormat:NSLocalizedString(@"QueueButtonTitleFormat", @""), count];
	else
		title = NSLocalizedString(@"EmptyQueueButtonTitleFormat", @"");
	if(![[postImageSegmentedControl titleForSegmentAtIndex:0] isEqualToString:title])
		[postImageSegmentedControl setTitle:title forSegmentAtIndex:0];
}

- (void)setImageImage:(UIImage*)newImage
{
	image.image = newImage;
	[self setURLPlaceholder];
	[self setNavigatorButtons];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	messageTextWillIgnoreNextViewAppearing = YES;
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	[messageText becomeFirstResponder];
	[self setNavigatorButtons];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editInfo 
{
//	long dataLen = [UIImageJPEGRepresentation(img, 1.0f)	length];
//	return;
	
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	twitWasChangedManually = YES;
	messageTextWillIgnoreNextViewAppearing = YES;
//	[picker.visibleViewController.view addSubview:_imagePickerIndicator];
//	[_imagePickerIndicator startAnimating];
	BOOL startNewUpload = img != image.image;
	if(img != image.image)
		[self setImageImage:img];	
	[self setNavigatorButtons];
/*	
//NSLog(@"before first conversation");
NSData* imData = UIImageJPEGRepresentation(img, 1.0f);
//NSLog(@"after first conversation len == %ld", [imData length]);
//NSLog(@"before image scaling");
CGSize newSize = {1024, 1024};
UIImage* image2 = imageScaledToSize(img, newSize);
//NSLog(@"after image scaling");
//NSLog(@"before second conversation");
imData = UIImageJPEGRepresentation(image2, 1.0f);
//NSLog(@"after second conversation len == %ld", [imData length]);
[self setImageImage:image2];	
*/	
	
	//NSLog(@"1");
	if(startNewUpload)
	{
		if(self.connectionDelegate)
			[self.connectionDelegate cancel];
		self.connectionDelegate = nil;
		self.currentImageYFrogURL = nil;
/*		ImageUploader * uploader = [[ImageUploader alloc] init];
		self.connectionDelegate = uploader;
		//NSLog(@"2");

		[self retainActivityIndicator];
		[uploader postImage:img delegate:self userData:img];
		//NSLog(@"8");
		//NSLog(@"release in [TwitEditorController imagePickerController:didFinishPickingImage:]");
		[uploader release];*/
	}
//	[_imagePickerIndicator stopAnimating];
//	[_imagePickerIndicator removeFromSuperview];

	[messageText becomeFirstResponder];
	
//	NSLog(@"imagePickerController");
	BOOL needToResize;
	BOOL needToRotate;
	isImageNeedToConvert(img, &needToResize, &needToRotate);
	if(needToResize || needToRotate)
	{
		self.progressSheet = ShowActionSheet(NSLocalizedString(@"Processing image...", @""), self, nil, self.tabBarController.view);
		self.progressSheet.tag = PROCESSING_PHOTO_SHEET_TAG;
	}
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
//	messageText.autocorrectionType = UITextAutocorrectionTypeNo;
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = NSLocalizedString(@"Back", @"");
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
	[temporaryBarButtonItem release];
	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLocationChanged)
//												 name:@"UpdateLocationNotification" object:nil];


//	self.imgPicker = [[UIImagePickerController alloc] init];
//	self.imgPicker.allowsImageEditing = YES;
//id test = self.navigationItem;
	self.navigationItem.title = NSLocalizedString(@"New Tweet", @"");
//	self.navigationItem.prompt = NSLocalizedString(@"New Tweettttt", @"");
//	self.navigationItem = navItem;
//	self.navigationItem.backBarButtonItem = backButton;
//	self.navigationItem.leftBarButtonItem = backButton;
//	self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"Back", @"");;
//	self.navigationItem.backButtonTitle = NSLocalizedString(@"Back", @"");;
//	self.title = NSLocalizedString(@"Post Image", @"");
	imgPicker.delegate = self;	
//	imgPicker.editing = NO;
//	imgPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;	
//	imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;	
//	imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;	

//	UINavigationController *theNavigationController;
//	theNavigationController = [[UINavigationController alloc] initWithRootViewController:self];

	messageText.delegate = self;
	
	postImageSegmentedControl.frame = CGRectMake(0, 0, SEND_SEGMENT_CNTRL_WIDTH, 30);
//	postImageSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//	postImageSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:postImageSegmentedControl];
	[postImageSegmentedControl setWidth:FIRST_SEND_SEGMENT_WIDTH forSegmentAtIndex:0];
	defaultTintColor = [postImageSegmentedControl.tintColor retain];	// keep track of this for later
	
//	if([[LocationManager locationManager] locationDefined])
//		messageText.text = [NSString stringWithFormat:@"\n\n%@", [[LocationManager locationManager] mapURL]];

	[self setURLPlaceholder];
	
//	[self textViewDidChange:messageText];
//	imagesSegmentedControl.tag = IMAGES_SEGMENT_CONTROLLER_TAG;

	BOOL cameraEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	BOOL libraryEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	if(!cameraEnabled && !libraryEnabled)
		[pickImage setHidden:YES];
//		[imagesSegmentedControl setHidden:YES];
/*	else if(!cameraEnabled)
		[imagesSegmentedControl setEnabled:NO forSegmentAtIndex:0];
	else if(!libraryEnabled)
		[imagesSegmentedControl setEnabled:NO forSegmentAtIndex:1]; */

	image.actualNavigationController = self.navigationController;
	[messageText becomeFirstResponder];
	inTextEditingMode = YES;
	
	
	
	_indicatorCount = 0;
	_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	CGRect frame = image.frame;
	CGRect indFrame = _indicator.frame;
//	indFrame.size.width *= 2;
//	indFrame.size.height *= 2;
	frame.origin.x = (int)((image.frame.size.width - indFrame.size.width) * 0.5f) + 1;
	frame.origin.y = (int)((image.frame.size.height - indFrame.size.height) * 0.5f) + 1;
	frame.size = indFrame.size;
	_indicator.frame = frame;
	
	
/*	_imagePickerIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	frame = self.view.frame;
	indFrame = _indicator.frame;
	frame.origin.x += (frame.size.width - indFrame.size.width) * 0.5f;
	frame.origin.y += (frame.size.height - indFrame.size.height) * 0.3f;
	frame.size = indFrame.size;
	_indicator.frame = frame;*/
	
	
	
	[self setQueueTitle];
	[self setNavigatorButtons];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	NSRange urlPlaceHolderRange = [textView.text rangeOfString:urlPlaceholderMask];
	if(urlPlaceHolderRange.location == NSNotFound && image.image)
		return NO;
	
	if((urlPlaceHolderRange.location < range.location) && (urlPlaceHolderRange.location + urlPlaceHolderRange.length > range.location))
		return NO;		
	
	if(NSIntersectionRange(urlPlaceHolderRange, range).length > 0)
		return NO;		
	
//	return MAX_SYMBOLS_COUNT_IN_TEXT_VIEW >= [textView.text length] - range.length + [text length];
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
/*	BOOL test = [textView isFirstResponder];
	if(test)
	{
		int r = 8;
		r++;
		
	}*/
//	[textView setNeedsDisplay]; //because of wrong clipping in UITextView
//	[textView setNeedsDisplay]; //because of wrong clipping in UITextView
//	CGSize contentSize = textView.contentSize;
//	textView.contentSize.height = 100;
	twitWasChangedManually = YES;
	[self setCharsCount];
	[self setNavigatorButtons];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	inTextEditingMode = NO;
	[self setNavigatorButtons];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	inTextEditingMode = YES;
	[self setNavigatorButtons];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	int i = 8;
	i++;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	int i = 8;
	i++;
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (IBAction)finishEditAction
//- (void)finishEditAction
{
	[messageText resignFirstResponder];
}

//- (IBAction)grabImage 
- (void)grabImage 
{
/*	if([messageText.text rangeOfString:urlPlaceholderMask].location == NSNotFound && [messageText.text length] + 1 + [urlPlaceholderMask length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You can not add image", @"") 
														message:[NSString stringWithFormat:NSLocalizedString(@"Remove some chars", @""), 1 + [urlPlaceholderMask length]]
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
		return;
	} */
	
//	[self presentModalViewController:imgPicker animated:YES];


//	[self finishEditAction];
/*	BOOL cameraEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	BOOL libraryEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	NSString* firstButton = nil;
	NSString* secondButton = nil;
	int tag = 0;
	if(cameraEnabled && libraryEnabled)
	{
		tag = PHOTO_SOURCE_CAMERA_AND_LIBRARY_ACTION_SHEET_TAG;
		firstButton = NSLocalizedString(@"Use camera", @"");
		secondButton = NSLocalizedString(@"Use library", @"");
	}
	else if(cameraEnabled)
	{
		tag = PHOTO_SOURCE_CAMERA_ACTION_SHEET_TAG;
		firstButton = NSLocalizedString(@"Use camera", @"");
	}
	else
	{
		tag = PHOTO_SOURCE_LIBRARY_ACTION_SHEET_TAG;
		firstButton = NSLocalizedString(@"Use library", @"");
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil //NSLocalizedString(@"Library or camera", @"")
									delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil
									otherButtonTitles:firstButton, secondButton, nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	actionSheet.tag = tag;
	[actionSheet showInView:self.tabBarController.view];
	[actionSheet release];*/
	
	BOOL cameraEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	BOOL libraryEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	BOOL imageAlreadyExists = image.image != nil;
	NSString* firstButton = nil;
	NSString* secondButton = nil;
	NSString* thirdButton = nil;
	if(cameraEnabled && libraryEnabled)
	{
		firstButton = NSLocalizedString(@"Use camera", @"");
		secondButton = NSLocalizedString(@"Use library", @"");
		if(imageAlreadyExists)
			thirdButton = NSLocalizedString(@"RemoveImageTitle" , @"");
	}
	else if(cameraEnabled)
	{
		firstButton = NSLocalizedString(@"Use camera", @"");
		if(imageAlreadyExists)
			secondButton = NSLocalizedString(@"RemoveImageTitle" , @"");
	}
	else
	{
		firstButton = NSLocalizedString(@"Use library", @"");
		if(imageAlreadyExists)
			secondButton = NSLocalizedString(@"RemoveImageTitle" , @"");
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil //NSLocalizedString(@"Library or camera", @"")
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil
													otherButtonTitles:firstButton, secondButton, thirdButton, nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	actionSheet.tag = PHOTO_Q_SHEET_TAG;
	[actionSheet showInView:self.tabBarController.view];
	[actionSheet release];
	
}

- (IBAction)attachImagesActions:(id)sender
{
	[self grabImage];
}

/*
//- (IBAction)postImageAction 
- (void)postImageAction 
{
//	imageDownoader * downloader = [[imageDownoader alloc] init];
//	[downloader getImageFromURL:@"http://yfrog.com/0412mj" imageType:full delegate:self];
//	[downloader getImageFromURL:@"http://yfrog.com/0412mj" imageType:iPhone delegate:self];
//	[downloader getImageFromURL:@"http://yfrog.com/0412mj" imageType:thumbnail delegate:self];
//	[downloader release];
//	return;
	//For testing only!!!


	if(!image.image)
		return;

	NSString* login = [MGTwitterEngine username];
	NSString* pass = [MGTwitterEngine password];
	
	if(!login || !pass)
	{
		[LoginController showModal:self.navigationController];
		return;
	}

//	NSString *imageFileName = @"TestImage.jpg";
//	NSString *pathToImage = [@"~/Desktop/chizhik.gif" stringByExpandingTildeInPath];
	NSString *boundary = [NSString stringWithFormat:@"------%ld__%ld__%ld", random(), random(), random()];
	
	NSURL *url = [NSURL URLWithString:@"http://yfrog.com/api/uploadAndPost"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];

	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-type"];
	
//	NSData *imageData = [NSData dataWithContentsOfFile:pathToImage options:0 error:nil];
	
	//adding the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"media\"; filename=\"iPhoneImage\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:UIImageJPEGRepresentation(image.image, 1.0f)];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[login dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[pass dataUsingEncoding:NSUTF8StringEncoding]];

	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"message\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[messageText.text dataUsingEncoding:NSUTF8StringEncoding]];
//	if([[LocationManager locationManager] locationDefined])
//	{
//		[postBody appendData:[@" " dataUsingEncoding:NSUTF8StringEncoding]];
//		[postBody appendData:[[[LocationManager locationManager] mapURL] dataUsingEncoding:NSUTF8StringEncoding]];
//	}
//
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPBody:postBody];

	NSArray* addresses = nil;
//	if([[NSUserDefaults standardUserDefaults] boolForKey:@"PostMail"])
//		addresses = [[NSUserDefaults standardUserDefaults] arrayForKey:@"PostMailAddresses"];
	[[PostFilesDelegate alloc] initWithRequest:req mailAddresses:addresses TwitEditorController:self];
//	NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:req delegate:conDelegate startImmediately:NO] autorelease];
	
	
//	NSError* err = nil;
//	NSURLResponse* response = nil;
//	NSData* returnedData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&err];
//	NSString* postedStr = [[[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding] autorelease];
//	//NSLog(postedStr);
//	NSString* returnedStr = [[[NSString alloc] initWithData:returnedData encoding:NSUTF8StringEncoding] autorelease];
//	//NSLog(returnedStr);
	
	
//	imageDownoader * downloader = [[imageDownoader alloc] init];
//	[downloader getImageFromURL:@"http://yfrog.com/0412mj" imageType:full delegate:self];
//	[downloader release];
}
*/

- (void)startUploadingOfPickedImageIfNeed
{
	if(!self.currentImageYFrogURL && image.image && !connectionDelegate)
	{
		ImageUploader * uploader = [[ImageUploader alloc] init];
		self.connectionDelegate = uploader;
		[self retainActivityIndicator];
		[uploader postImage:image.image delegate:self userData:image.image];
		[uploader release];
	}
	
	if(self.progressSheet.tag == PROCESSING_PHOTO_SHEET_TAG)
	{
		[self.progressSheet dismissWithClickedButtonIndex:-1 animated:YES];
		self.progressSheet = nil;
	}

		
}

//- (IBAction)postImageAction 
- (void)postImageAction 
{
	if(!image.image && ![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return;


	if([messageText.text length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You can not send message", @"") 
														message:[NSString stringWithFormat:NSLocalizedString(@"Cant to send too long message", @""), 1 + [urlPlaceholderMask length]]
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
		return;
	}

	
	if(!self.currentImageYFrogURL && image.image && !self.progressSheet)
	{
		suspendedOperation = send;
		if(!connectionDelegate)
		{
			ImageUploader * uploader = [[ImageUploader alloc] init];
			self.connectionDelegate = uploader;
			[self retainActivityIndicator];
			[uploader postImage:image.image delegate:self userData:image.image];
			[uploader release];
		}
		self.progressSheet = ShowActionSheet(NSLocalizedString(@"Upload Image to yFrog", @""), self, NSLocalizedString(@"Cancel", @""), self.tabBarController.view);
		return;
	}
	
	suspendedOperation = noTEOperations;
	NSString* login = [MGTwitterEngine username];
	NSString* pass = [MGTwitterEngine password];
	
	if(!login || !pass)
	{
		[LoginController showModal:self.navigationController];
		return;
	}
	
	NSString *messageBody = messageText.text;
	if(image.image && currentImageYFrogURL)
		messageBody = [messageBody stringByReplacingOccurrencesOfString:urlPlaceholderMask withString:currentImageYFrogURL];
	
	[TweetterAppDelegate increaseNetworkActivityIndicator];
	if(!self.progressSheet)
		self.progressSheet = ShowActionSheet(NSLocalizedString(@"Send twit on Twitter", @""), self, NSLocalizedString(@"Cancel", @""), self.tabBarController.view);
		
	postImageSegmentedControl.enabled = NO;

	NSString* mgTwitterConnectionID = nil;
	if(_message)
		mgTwitterConnectionID = [_twitter sendUpdate:messageBody inReplyTo:[[_message objectForKey:@"id"] intValue]];
	else if(_queueIndex >= 0)
		mgTwitterConnectionID = [_twitter sendUpdate:messageBody inReplyTo:_queuedReplyId];
	else
		mgTwitterConnectionID = [_twitter sendUpdate:messageBody];
		
	MGConnectionWrap * mgConnectionWrap = [[MGConnectionWrap alloc] initWithTwitter:_twitter connection:mgTwitterConnectionID delegate:self];
	self.connectionDelegate = mgConnectionWrap;
	[mgConnectionWrap release];
	
	if(_queueIndex >= 0)
		[[TweetQueue sharedQueue] deleteMessage:_queueIndex];

	return;
	
/*	
	NSString* login = [MGTwitterEngine username];
	NSString* pass = [MGTwitterEngine password];
	
	if(!login || !pass)
	{
		[LoginController showModal:self.navigationController];
		return;
	}
	
	//	NSString *imageFileName = @"TestImage.jpg";
	//	NSString *pathToImage = [@"~/Desktop/chizhik.gif" stringByExpandingTildeInPath];
	NSString *boundary = [NSString stringWithFormat:@"------%ld__%ld__%ld", random(), random(), random()];
	
	NSURL *url = [NSURL URLWithString:@"http://yfrog.com/api/uploadAndPost"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-type"];
	
	//	NSData *imageData = [NSData dataWithContentsOfFile:pathToImage options:0 error:nil];
	
	//adding the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"media\"; filename=\"iPhoneImage\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:UIImageJPEGRepresentation(image.image, 1.0f)];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[login dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[pass dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"message\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[messageText.text dataUsingEncoding:NSUTF8StringEncoding]];
//	if([[LocationManager locationManager] locationDefined])
//	{
//		 [postBody appendData:[@" " dataUsingEncoding:NSUTF8StringEncoding]];
//		 [postBody appendData:[[[LocationManager locationManager] mapURL] dataUsingEncoding:NSUTF8StringEncoding]];
//	}
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPBody:postBody];
	
	NSArray* addresses = nil;
	//	if([[NSUserDefaults standardUserDefaults] boolForKey:@"PostMail"])
	//		addresses = [[NSUserDefaults standardUserDefaults] arrayForKey:@"PostMailAddresses"];
	[[PostFilesDelegate alloc] initWithRequest:req mailAddresses:addresses TwitEditorController:self];
	//	NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:req delegate:conDelegate startImmediately:NO] autorelease];
	
	
	//	NSError* err = nil;
	//	NSURLResponse* response = nil;
	//	NSData* returnedData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&err];
	//	NSString* postedStr = [[[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding] autorelease];
	//	//NSLog(postedStr);
	//	NSString* returnedStr = [[[NSString alloc] initWithData:returnedData encoding:NSUTF8StringEncoding] autorelease];
	//	//NSLog(returnedStr);
	
	
	//	imageDownoader * downloader = [[imageDownoader alloc] init];
	//	[downloader getImageFromURL:@"http://yfrog.com/0412mj" imageType:full delegate:self];
	//	[downloader release];*/
}

- (void)postImageLaterAction
{
	if(!image.image && ![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return;

	if([messageText.text length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You can not send message", @"") 
														message:[NSString stringWithFormat:NSLocalizedString(@"Cant to send too long message", @""), 1 + [urlPlaceholderMask length]]
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
		return;
	}

	NSString *messageBody = messageText.text;
	if(image.image && currentImageYFrogURL)
		messageBody = [messageBody stringByReplacingOccurrencesOfString:urlPlaceholderMask withString:currentImageYFrogURL];

	BOOL added;
	if(_queueIndex >= 0)
	{
		added = [[TweetQueue sharedQueue] replaceMessage: messageBody 
											withImage: currentImageYFrogURL ? nil : image.image 
											inReplyTo: _queuedReplyId
											atIndex:_queueIndex];
	}
	else
	{
		added = [[TweetQueue sharedQueue] addMessage: messageBody 
											withImage: currentImageYFrogURL ? nil : image.image 
											inReplyTo: _message ? [[_message objectForKey:@"id"] intValue] : 0];
	}
	if(added)
	{
		if(connectionDelegate)
			[connectionDelegate cancel];
//		self.connectionDelegate = nil;
		[self setImageImage:nil];	
		[self setMessageTextText:@""];
		[messageText becomeFirstResponder];
		inTextEditingMode = YES;
		[self setNavigatorButtons];
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed!", @"") 
														message:NSLocalizedString(@"Cant to send too long message", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
	}
}

- (IBAction)insertLocationAction
{
	if(![[LocationManager locationManager] locationServicesEnabled])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location service is not available on the device", @"") 
														message:NSLocalizedString(@"You can to enable Location Services on the device", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
		return;
	}
	
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocations"])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location service was turn off in settings", @"") 
														message:NSLocalizedString(@"You can to enable Location Services in the application settings", @"")
													   delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		alert.tag = PHOTO_ENABLE_SERVICES_ALERT_TAG;
		[alert show];
		[alert release];
		return;
	}
	
	if([[LocationManager locationManager] locationDenied])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Locations for this application was denied", @"") 
														message:NSLocalizedString(@"You can to enable Location Services by throw down settings", @"")
													   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	
	
	
	if(![[LocationManager locationManager] locationDefined])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location undefined", @"") 
														message:NSLocalizedString(@"Location is still undefined", @"")
													   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	
	NSString* mapURL = [NSString stringWithFormat:NSLocalizedString(@"LocationLinkFormat", @""), [[LocationManager locationManager] mapURL]];
/*	if([messageText.text length] + 1 + [mapURL length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You can not add location", @"") 
														message:[NSString stringWithFormat:NSLocalizedString(@"Remove some chars", @""), 1 + [mapURL length]]
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
		return;
	} */

	NSRange selectedRange = messageText.selectedRange;
	[self setMessageTextText:[NSString stringWithFormat:@"%@\n%@", messageText.text, mapURL]];
//	messageText.text = [NSString stringWithFormat:@"%@\n%@", messageText.text, mapURL];
	messageText.selectedRange = selectedRange;
}

/*
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == actionSheet.cancelButtonIndex)
		return;
	
	imgPicker.sourceType = (buttonIndex == 0) ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeCamera;
	[self presentModalViewController:imgPicker animated:YES];
}
*/

/*
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(actionSheet.tag == PHOTO_SOURCE_CAMERA_AND_LIBRARY_ACTION_SHEET_TAG ||
		actionSheet.tag == PHOTO_SOURCE_LIBRARY_ACTION_SHEET_TAG ||
		actionSheet.tag == PHOTO_SOURCE_CAMERA_ACTION_SHEET_TAG)
	{
		if(buttonIndex == actionSheet.cancelButtonIndex)
			return;
		
		switch(actionSheet.tag)
		{
			case PHOTO_SOURCE_CAMERA_AND_LIBRARY_ACTION_SHEET_TAG:
				imgPicker.sourceType = (buttonIndex == 0) ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
				break;
			case PHOTO_SOURCE_CAMERA_ACTION_SHEET_TAG:
				imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
				break;
			case PHOTO_SOURCE_LIBRARY_ACTION_SHEET_TAG:
			default:
				imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
				break;

		}

		[self presentModalViewController:imgPicker animated:YES];
	}
	else
	{
		suspendedOperation = noTEOperations;
		[self dismissProgressSheetIfExist];
		if(connectionDelegate)
			[connectionDelegate cancel];
	}
}
 */
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(actionSheet.tag == PHOTO_Q_SHEET_TAG)
	{
		if(buttonIndex == actionSheet.cancelButtonIndex)
			return;
		
		if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"RemoveImageTitle", @"")])
		{
			twitWasChangedManually = YES;
			[self setImageImage:nil];
			if(connectionDelegate)
				[connectionDelegate cancel];
			self.currentImageYFrogURL = nil;
			return;
		}
		else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Use camera", @"")])
		{
			imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
			[self presentModalViewController:imgPicker animated:YES];
			return;
		}
		else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Use library", @"")])
		{
			imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
			[self presentModalViewController:imgPicker animated:YES];
			return;
		}
		
	}
	else
	{
		suspendedOperation = noTEOperations;
		[self dismissProgressSheetIfExist];
		if(connectionDelegate)
			[connectionDelegate cancel];
	}
}

- (void)setRetwit:(NSString*)body whose:(NSString*)username
{
	if(username)
		[self setMessageTextText:[NSString stringWithFormat:NSLocalizedString(@"ReTwitFormat", @""), username, body]];
	else
		[self setMessageTextText:body];
//	messageText.text = body;
//	_textModified = NO;
//	[self textViewDidChange:messageText];
}

- (void)setReplyToMessage:(NSDictionary*)message
{
	self._message = message;
	NSString *replyToUser = [[message objectForKey:@"user"] objectForKey:@"screen_name"];
	[self setMessageTextText:[NSString stringWithFormat:@"@%@ ", replyToUser]];
//	messageText.text = [NSString stringWithFormat:@"@%@ ", replyToUser];
//	[self textViewDidChange:messageText];
}



/*
#pragma mark NSURLConnection delegate methods


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    [result setLength:0];
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//    [result appendData:data];
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [connection release];
}


- (NSCachedURLResponse *) connection:(NSURLConnection *)connection 
                   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
     return cachedResponse;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];
}
*/
//For testing only!!!
/*
- (void)receivedImage:(UIImage*)yfrogImage fromYFrogURL:(NSString*)imageURL imageType:(ImageType)imageType
{
	image.image = yfrogImage;	
}
*/
/*
-(void) onLocationChanged
{
	[self setCharsCount];
}
*/
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (self.navigationController.navigationBar.barStyle == UIBarStyleBlackTranslucent || self.navigationController.navigationBar.barStyle == UIBarStyleBlackOpaque) 
		postImageSegmentedControl.tintColor = [UIColor darkGrayColor];
	else
		postImageSegmentedControl.tintColor = defaultTintColor;
	if(!messageTextWillIgnoreNextViewAppearing)
	{
		[messageText becomeFirstResponder];
		inTextEditingMode = YES;
	}
	messageTextWillIgnoreNextViewAppearing = NO;
	[self setCharsCount];
	[self setNavigatorButtons];
}

- (void)popController
{
	[self setImageImage:nil];
	[self setMessageTextText:@""];
//	messageText.text = @"";
	[self.navigationController popToRootViewControllerAnimated:YES];
}


- (IBAction)imagesSegmentedActions:(id)sender
{
	switch([sender selectedSegmentIndex])
	{
		case 0:
/*			if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
			{
				imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
				[self grabImage];
			}*/
			[self grabImage];
			break;
/*		case 1:
			if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
			{
				imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
				[self grabImage];
			}
			break;*/
		case 1:
			[self setImageImage:nil];
			if(connectionDelegate)
				[connectionDelegate cancel];
//			self.connectionDelegate = nil;
			self.currentImageYFrogURL = nil;
			break;
		default:
			break;
	}
}

- (IBAction)postMessageSegmentedActions:(id)sender
{
	switch([sender selectedSegmentIndex])
	{
		case 0:
			[self postImageLaterAction];
			break;
		case 1:
			[self postImageAction];
			break;
		default:
			break;
	}
}

/*
//For Navigation Bar
- (IBAction)segmentedActions:(id)sender
{
	switch([sender selectedSegmentIndex])
	{
		case 0:
			[self grabImage];
			break;
		case 1:
			if([[postImageSegmentedControl titleForSegmentAtIndex:1] isEqualToString:NSLocalizedString(@"Done", @"")])
				[self finishEditAction];
			else if([[postImageSegmentedControl titleForSegmentAtIndex:1] isEqualToString:NSLocalizedString(@"Send", @"")])
				[self postImageAction]; 
			break;
		default:
			break;
	}
}
*/

- (void)uploadedImage:(NSString*)yFrogURL sender:(ImageUploader*)sender
{
//	self.connectionDelegate = nil;
	[self releaseActivityIndicator];
	if(sender.userData == image.image) // don't kill later connection
	{
		//NSLog(@"release in [TwitEditorController uploadedImage] (sender.userData == image.image)");
		self.connectionDelegate = nil;
		self.currentImageYFrogURL = yFrogURL;
	}
	else if(!image.image)
	{
		//NSLog(@"release in [TwitEditorController uploadedImage] (!image.image)");
		self.connectionDelegate = nil;
		self.currentImageYFrogURL = nil;
	}
	else
		return;
	
	if(suspendedOperation == send)
	{
		suspendedOperation == noTEOperations;
		if(yFrogURL)
			[self postImageAction];
		else
		{
			[self dismissProgressSheetIfExist];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed!", @"") message:NSLocalizedString(@"Error occure during uploading of image", @"")
														   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
			[alert show];	
			[alert release];
		}
	}
}
/*
- (BOOL)uploadingImageWasScaled:(NSDictionary*)images
{
	UIImage* largeImage = [images objectForKey:@"large"];
	UIImage* smallerImage = [images objectForKey:@"small"];
	BOOL imageIsStillActual = largeImage == image.image;
	if(imageIsStillActual)
		[self setImageImage:smallerImage];

	return imageIsStillActual;
}
*/

#pragma mark MGTwitterEngineDelegate methods

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"TwittsUpdated" object: nil];
	self.connectionDelegate = nil;
    //NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
	image.image = nil;
	[self setMessageTextText:@""];
	[messageText becomeFirstResponder];
	inTextEditingMode = YES;
	[self setNavigatorButtons];
	[self.navigationController popViewControllerAnimated:YES];
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
	self.connectionDelegate = nil;
	postImageSegmentedControl.enabled = YES;
	/*NSLog(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
          connectionIdentifier, 
          [error localizedDescription], 
          [error userInfo]);*/
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed!", @"") message:[error localizedDescription]
												   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
	[alert show];	
	[alert release];
}

- (void)MGConnectionCanceled:(NSString *)connectionIdentifier
{
	postImageSegmentedControl.enabled = YES;
	self.connectionDelegate = nil;
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
}

- (void)doCancel
{
	
	[self.navigationController popViewControllerAnimated:YES];
	if(connectionDelegate)
		[connectionDelegate cancel];
//	self.connectionDelegate = nil;
	[self setImageImage:nil];	
	[self setMessageTextText:@""];
	[messageText resignFirstResponder];
	[self setNavigatorButtons];
}

- (IBAction)cancel
{
	if(!twitWasChangedManually || ([[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0 && !image.image))
	{
		[self doCancel];
		return;
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"The message is not sent" message:@"Your changes will be lost"
												   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	alert.tag = PHOTO_DO_CANCEL_ALERT_TAG;
	[alert show];
	[alert release];
		
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(alertView.tag == PHOTO_DO_CANCEL_ALERT_TAG)
	{
		if(buttonIndex > 0)
			[self doCancel];
	}
	else if(alertView.tag == PHOTO_ENABLE_SERVICES_ALERT_TAG)
	{
		if(buttonIndex > 0)
		{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UseLocations"];
			[[LocationManager locationManager] startUpdates];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateLocationDefaultsChanged" object: nil];
		}
	}
}


- (void)editUnsentMessage:(int)index
{
	
	NSString* text;
	NSData* imageData;
	if([[TweetQueue sharedQueue] getMessage:&text andImageData:&imageData inReplyTo:&_queuedReplyId atIndex:index])
	{
		_queueIndex = index;
		[self setMessageTextText:text];
		if(imageData)
			[self setImageImage:[UIImage imageWithData:imageData]];
		[postImageSegmentedControl setTitle:@"Save" forSegmentAtIndex:0];
		[postImageSegmentedControl setWidth:postImageSegmentedControl.frame.size.width*0.5f
			forSegmentAtIndex:0];
	}
}

- (void)retainActivityIndicator
{
	if(++_indicatorCount == 1)
	{
		[image addSubview:_indicator];
		[_indicator startAnimating];
	}
}

- (void)releaseActivityIndicator
{
	if(_indicatorCount > 0)
	{
		[_indicator stopAnimating];
		[_indicator removeFromSuperview];
		--_indicatorCount;
	}
}



@end
