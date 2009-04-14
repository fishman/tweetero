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

#import "yFrogImageDownoader.h"
#import "TweetterAppDelegate.h"

@implementation ImageDownoader

@synthesize connection;
@synthesize contentXMLProperty;
@synthesize fullYFrogImageURL;
@synthesize origURL;

-(id)init
{
	self = [super init];
	if(self)
	{
		result = [[NSMutableData alloc] initWithCapacity:128];
		waitXMLInfo = NO;
		wasCanceled = NO;
	}
	return self;
}

-(void)dealloc
{
	if(delegate)
		[delegate release];
	if(origURL)
		[origURL release];
	self.connection = nil;
	self.contentXMLProperty = nil;
	self.fullYFrogImageURL = nil;
	[result  release];
	[super dealloc];
}


- (void)postRequestForImage:(NSURL*)imageURL
{
	NSURLRequest *req = [NSURLRequest requestWithURL:imageURL];
	self.connection = [[NSURLConnection alloc] initWithRequest:req 
												  delegate:self 
										  startImmediately:YES];
	if (!self.connection) 
	{
		[delegate receivedImage:nil sender:self];
		[self release];
	}
	[TweetterAppDelegate increaseNetworkActivityIndicator];
}


- (void)getImageFromURL:(NSString*)imageURL imageType:(ImageType)imgType delegate:(id <ImageDownoaderDelegate>)dlgt
{
	[self retain];
	delegate = [dlgt retain];
	imageType = imgType;
	origURL = [imageURL retain];
	if(imageType == iPhoneYFrog)
	{
		[self postRequestForImage:[NSURL URLWithString:[imageURL stringByAppendingString:@":iphone"]]];
		return;
	}
	else if(imageType == thumbnailYFrog)
	{
		[self postRequestForImage:[NSURL URLWithString:[imageURL stringByAppendingString:@".th.jpg"]]];
		return;
	}
	else if(imageType == fullYFrog)
	{
		NSString* fileID = [imageURL lastPathComponent];
//		//NSLog([@"http://yfrog.com/api/xmlInfo?path=" stringByAppendingString:fileID]);
		NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[@"http://yfrog.com/api/xmlInfo?path=" stringByAppendingString:fileID]]];
		waitXMLInfo = YES;
		self.connection = [[NSURLConnection alloc] initWithRequest:req 
													  delegate:self 
											  startImmediately:YES];
		if (!connection) 
		{
			//NSLog(@"connection does not created");
			[delegate receivedImage:nil sender:self];
			[self release];
		}
		[TweetterAppDelegate increaseNetworkActivityIndicator];
	}
	else if(imageType == nonYFrog)
	{
		[self postRequestForImage:[NSURL URLWithString:imageURL]];
		return;
	}
	
}

#pragma mark NSURLConnection delegate methods


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
//NSLog(@"connection didFailWithError");
//NSLog([error localizedDescription]);
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[delegate receivedImage:nil sender:self];
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


    if ([elementName isEqualToString:@"image_link"])
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
    
    if ([elementName isEqualToString:@"image_link"])
	{
        self.fullYFrogImageURL = [self.contentXMLProperty stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
//NSLog(@"connectionDidFinishLoading");
//NSLog([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease]);
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	if(waitXMLInfo)
	{
		waitXMLInfo = NO;
		

		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:result];
		[parser setDelegate:self];
		[parser setShouldProcessNamespaces:NO];
 		[parser setShouldReportNamespacePrefixes:NO];
		[parser setShouldResolveExternalEntities:NO];
		
		[parser parse];
		[parser release];

		[result setLength:0];
		
		if(self.fullYFrogImageURL)
			[self postRequestForImage:[NSURL URLWithString:fullYFrogImageURL]];
		else
		{
			[delegate receivedImage:nil sender:self];
			[self release];
		}
	}
	else
	{
		[delegate receivedImage:[UIImage imageWithData:result] sender:self];
		[self release];
	}
}

- (void)cancel
{
	wasCanceled = YES;
	[connection cancel];
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[delegate receivedImage:nil sender:self];
	[self release];
}

- (BOOL)wasCanceled
{
	return wasCanceled;
}

- (ImageType)imageType
{
	return imageType;
}

/*
- (NSXMLNode*)getChildNode:(NSXMLNode*)parent withName:(NSString*)name
{
	NSXMLNode* node = nil;
	for (node = [parent childAtIndex:0]; node; node = [node nextSibling]) 
	{
//		//NSLog([node name]);
		if ([[node name] isEqualToString:name])
			return node;
	}
	return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(waitXMLInfo)
	{
		waitXMLInfo = NO;
		
		NSString* fullYFrogImageURL = nil;
		NSXMLDocument* xmlDoc = [[NSXMLDocument alloc] initWithData:result options:0 error:nil];
//		//NSLog([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease]);

		NSXMLNode* linksNode = nil;
		NSXMLNode* errorNode = nil;
		NSXMLNode* fullImageNode = nil;
		
		linksNode = [self getChildNode:xmlDoc withName:@"links"];
		if(!linksNode)
		{
			NSXMLNode* imginfoNode = [self getChildNode:xmlDoc withName:@"imginfo"];
			if(imginfoNode)
				linksNode = [self getChildNode:imginfoNode withName:@"links"];
		}
		
		if(linksNode)
		{
//			errorNode = [self getChildNode:linksNode withName:@"error"];
			fullImageNode = [self getChildNode:linksNode withName:@"image_link"];
			if(fullImageNode && [fullImageNode kind] == NSXMLElementKind)
				fullYFrogImageURL = [[fullImageNode stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; 
		}

		[xmlDoc release];
		[result setLength:0];
		
		if(fullYFrogImageURL)
			[self postRequestForImage:[NSURL URLWithString:fullYFrogImageURL]];
		else
		{
			[delegate receivedImage:nil fromYFrogURL:origURL imageType:imageType];
			[self release];
		}
	}
	else
	{
		[delegate receivedImage:[UIImage imageWithData:result] fromYFrogURL:origURL imageType:imageType];
		[self release];
	}
}
*/
@end
