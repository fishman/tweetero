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

#import "MessageUploader.h"
#import "MGTwitterEngine.h"
#import "TweetterAppDelegate.h"


@implementation MessageUploader

@synthesize _body;
@synthesize _imageData;
@synthesize _connection;
@synthesize _delegate;


- (id)initWithText:(NSString*)text image:(UIImage*)image replayTo:(int)replayTo delegate:(id <MessageUploaderDelegate>)delegate
{
	self = [self initWithText:text imageJPEGData:UIImageJPEGRepresentation(image, 1.0f) replayTo:replayTo delegate:delegate];
	return self;
}

- (id)initWithText:(NSString*)text imageJPEGData:(NSData*)JPEGData replayTo:(int)replayTo delegate:(id <MessageUploaderDelegate>)delegate
{
	self = [super init];
	if(self)
	{
		_twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
		self._body = text;
		self._imageData = JPEGData;	
		_replyTo = replayTo;
		self._delegate = delegate;
	}
	return self;
}

- (void)dealloc 
{
	int connectionsCount = [_twitter numberOfConnections];
	[_twitter closeAllConnections];
	[_twitter removeDelegate];
	[_twitter release];
	while(connectionsCount-- > 0)
		[TweetterAppDelegate decreaseNetworkActivityIndicator];

	self._body = nil;
	self._imageData = nil;	
	self._connection = nil;
	self._delegate = nil;
    [super dealloc];
}


- (void)cancel
{
	wasCanceled = YES;
	if(_connection)
		[_connection cancel];
}

- (BOOL)wasCanceled
{
	return wasCanceled;
}

-(void)postMessage
{
	if(wasCanceled)
	{
		[TweetterAppDelegate decreaseNetworkActivityIndicator];
		if(self._delegate)
			[self._delegate MessageUploadFinished:NO sender:self];
		[self autorelease];
		return;
	}
		
	
	[self retain];
	[TweetterAppDelegate increaseNetworkActivityIndicator];
	NSString* mgTwitterConnectionID = [_twitter sendUpdate:self._body inReplyTo:_replyTo];
	MGConnectionWrap * mgConnectionWrap = [[MGConnectionWrap alloc] initWithTwitter:_twitter connection:mgTwitterConnectionID delegate:self];
	self._connection = mgConnectionWrap;
	[mgConnectionWrap release];
}

- (void) send
{
	if(!self._imageData)
		[self postMessage];
	else
	{
		[self retain];
		ImageUploader * uploader = [[ImageUploader alloc] init];
		self._connection = uploader;
		[uploader postJPEGData:_imageData delegate:self userData:nil];
//		[uploader postImage:self._image delegate:self userData:nil];
		[uploader release];
	}
}

- (void)uploadedImage:(NSString*)yFrogURL sender:(ImageUploader*)sender
{
	self._connection = nil;
	if(!yFrogURL)
	{
		if(self._delegate)
			[self._delegate MessageUploadFinished:NO sender:self];
	}
	else
	{
		self._body = [self._body stringByReplacingOccurrencesOfString:NSLocalizedString(@"YFrog image URL placeholder", @"") withString:yFrogURL];
		[self postMessage];
	}
	[self autorelease];
}

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	self._connection = nil;
	if(self._delegate)
		[self._delegate MessageUploadFinished:YES sender:self];
	[self autorelease];
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
//NSLog([error localizedDescription]);
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	self._connection = nil;
	if(self._delegate)
		[self._delegate MessageUploadFinished:NO sender:self];
	[self autorelease];
}

- (void)MGConnectionCanceled:(NSString *)connectionIdentifier
{
	self._connection = nil;
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	if(self._delegate)
		[self._delegate MessageUploadFinished:NO sender:self];
	[self autorelease];
}


@end
