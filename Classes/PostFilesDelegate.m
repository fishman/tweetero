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

#import "PostFilesDelegate.h"
#import "TweetterAppDelegate.h"
#import "PostImageController.h"
#include "util.h"


@implementation PostFilesDelegate

//@synthesize connection;
@synthesize contentXMLProperty;
@synthesize yFrogImageURL;
@synthesize mailAddresses;
//@synthesize actionSheetParent;
@synthesize actionSheet;
@synthesize postImageController;
@synthesize connection;


-(id)initWithRequest:(NSURLRequest*)request mailAddresses:(NSArray*)addresses postImageController:(PostImageController*)postImageContr
{
	self = [super init];
	if(self)
	{
//		self.actionSheetParent = viewForActionSheet;
		result = [[NSMutableData alloc] initWithCapacity:128];
		self.mailAddresses = addresses;
		self.postImageController = postImageContr;
		self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
		
		if(self.connection)
		{
			[TweetterAppDelegate increaseNetworkActivityIndicator];
			self.actionSheet = ShowActionSheet(NSLocalizedString(@"Uploading...", @""), self, NSLocalizedString(@"Cancel", @""), self.postImageController.tabBarController.view);
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed!", @"") message:NSLocalizedString(@"Failed to create connection.", @"")
														   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];	
			[alert release];
			[self release];
			return nil;
		}
	}
	return self;
}

-(void)dealloc
{
	self.connection = nil;
	self.contentXMLProperty = nil;
	self.yFrogImageURL = nil;
	self.mailAddresses = nil;
//	self.actionSheetParent = nil;
	self.actionSheet = nil;
	self.postImageController = nil;
	[result  release];
	[super dealloc];
}





- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [result setLength:0];
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [result appendData:data];
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
//    [connection release];
//	NSLog(@"connection didFailWithError!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed!" message:[error localizedDescription]
												   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];	
	[alert release];
	
//	[postImageController popController];
    [self release];
}


- (NSCachedURLResponse *) connection:(NSURLConnection *)connection 
                   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return cachedResponse;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) 
        elementName = qName;
	
	
    if ([elementName isEqualToString:@"mediaurl"])
		self.contentXMLProperty = [NSMutableString string];
	else if ([elementName isEqualToString:@"error"])
		[parser abortParsing];
	else
		self.contentXMLProperty = nil;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName)
        elementName = qName;
    
    if ([elementName isEqualToString:@"mediaurl"])
	{
        self.yFrogImageURL = [self.contentXMLProperty stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[parser abortParsing];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.contentXMLProperty)
		[self.contentXMLProperty appendString:string];
}

//- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
//{
//}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
//	NSLog([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease]);
//[actionSheet removeFromSuperview];
	[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:result];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	[parser parse];
	[parser release];
	
	[result setLength:0];
	[postImageController popController];
	
//	if(self.yFrogImageURL)
//	{
/*		if(mailAddresses)
		{
			BOOL success = NO;
			unsigned i = 0;
			unsigned count = [mailAddresses count];
			for(i = 0; i < count; i++)
			{
				// When including URL as "mailto" URL "body" paramter, we URL-encode it again.
				// For better URL highlighting in some programs, we enclose it in angle brackets. However,
				// since iPhone mail always treats mailto URL body parameter as HTML, we do entity encoding of
				// brackets, to avoid them treated as HTML tag. (See bug #2872 for details)
				NSString *mailto = [NSString stringWithFormat:@"mailto:%@?&subject=%@&body=%%26lt%%3B%@%%26gt%%3B", 
									[mailAddresses objectAtIndex:i],
									[NSLocalizedString(@"Mail Subject: yFrog Image", @"") stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
									[self.yFrogImageURL stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
									];
				
				// The string passed to URLWithString must be already property formatter per RFC 2396
				success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailto]];
				if(!success)
					NSLog(@"Error opening URL: %@", mailto);
			}
		}*/
		
/*		if([[NSUserDefaults standardUserDefaults] boolForKey:@"PostMail"])
		{
			BOOL success = NO;
			NSString *mailto = [NSString stringWithFormat:@"mailto:?&subject=%@&body=%%26lt%%3B%@%%26gt%%3B", 
								[NSLocalizedString(@"Mail Subject: yFrog Image", @"") stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
								[self.yFrogImageURL stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
								];
			
			success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailto]];
//TODO
//show alert
			if(!success)
				NSLog(@"Error opening URL: %@", mailto);
		}*/
//	}
	[self release];
}
/*
- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
NSLog(@"actionSheetCancel!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	[connection cancel];
//	[postImageController popController];
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
    [self release];
}
*/
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
//NSLog(@"actionSheet clickedButtonAtIndex!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	[self.connection cancel];
//	self.connection = nil;
	//	[postImageController popController];
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
    [self release];
}

@end
