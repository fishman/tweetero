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

#import <Foundation/Foundation.h>

@class PostImageController;

@interface PostFilesDelegate : NSObject <UIActionSheetDelegate>
{
	NSMutableData*	result;
	NSURLConnection *connection;
	
	NSMutableString* contentXMLProperty;
	NSString*		yFrogImageURL;
	
	NSArray*		mailAddresses;
//	UIView*			actionSheetParent;
	UIActionSheet*	actionSheet;
	PostImageController* postImageController;
}

- (id)initWithRequest:(NSURLRequest*)request mailAddresses:(NSArray*)addresses postImageController:(PostImageController*)postImageController;
//- (void)actionSheetCancel:(UIActionSheet *)actionSheet;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

//@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableString* contentXMLProperty;
@property (nonatomic, retain) NSString* yFrogImageURL;
@property (nonatomic, retain) NSArray* mailAddresses;
//@property (nonatomic, retain) UIView* actionSheetParent;
@property (nonatomic, retain) UIActionSheet* actionSheet;
@property (nonatomic, retain) PostImageController* postImageController;
@property (nonatomic, retain) NSURLConnection *connection;

@end
