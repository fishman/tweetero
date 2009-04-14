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

#import "yFrogImageUploader.h"
#import "TweetterAppDelegate.h"
#import "MGTwitterEngine.h"
#import "LocationManager.h"
#include "util.h"

//#define USE_IS

@implementation ImageUploader

@synthesize connection;
@synthesize contentXMLProperty;
@synthesize newURL;
@synthesize userData;
@synthesize delegate;



/*
- (id)retain
{
//NSLog(@"ImageUploader retain------- retainCount        --------- %d -----> %d", [self retainCount], [self retainCount] + 1);
    return [super retain];
}


- (void)release
{
//NSLog(@"ImageUploader release------- retainCount      --------- %d -----> %d", [self retainCount], [self retainCount]-1);
	[super release];
}


- (id)autorelease
{
//NSLog(@"ImageUploader autorelease--- retainCount      --------- %d -----> %d", [self retainCount], [self retainCount]);
    return [super autorelease];
}
*/

-(id)init
{
	self = [super init];
	if(self)
	{
		//NSLog(@"ImageUploader init----------------------- retainCount == %d", [self retainCount]);
		result = [[NSMutableData alloc] initWithCapacity:128];
		wasCanceled = NO;
		scaleIfNeed = NO;
	}
	return self;
}

-(void)dealloc
{
	//NSLog(@"ImageUploader dealloc-------------ImageUploader dealloc");
	self.delegate = nil;
	self.connection = nil;
	self.contentXMLProperty = nil;
	self.newURL = nil;
	self.userData = nil;
	[result  release];
	[super dealloc];
}

- (void) postJPEGData:(NSData*)imageJPEGData 
{
//	//NSLog(@"release in [Uploader postJPEGData]");
// 	[self release];
//	[imageJPEGData release];
	
	if(wasCanceled)
		return;
	
	NSString* login = [MGTwitterEngine username];
	NSString* pass = [MGTwitterEngine password];
	
	NSString *boundary = [NSString stringWithFormat:@"------%ld__%ld__%ld", random(), random(), random()];
	
	NSURL *url = [NSURL URLWithString:@"http://yfrog.com/api/upload"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];

	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-type"];
	
	//adding the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"media\"; filename=\"iPhoneImage\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageJPEGData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[login dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[pass dataUsingEncoding:NSUTF8StringEncoding]];
	
	if([[LocationManager locationManager] locationDefined])
	{
		[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[postBody appendData:[@"Content-Disposition: form-data; name=\"tags\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//		[postBody appendData:[@"Content-Disposition: form-data; name=\"tags\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//		[postBody appendData:[@"Content-Type: text/plain; charset=iso-8859-1\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[NSString stringWithFormat:@"geotagged, geo:lat=%+.6f, geo:lon=%+.6f", [[LocationManager locationManager] latitude], [[LocationManager locationManager] longitude]] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
//	//NSLog([NSString stringWithFormat:@"geotagged, geo:lat=%+.6f, geo:lon=%+.6f", [[LocationManager locationManager] latitude], [[LocationManager locationManager] longitude]]);
//	//NSLog([NSString stringWithFormat:@"geotagged, geo:lat=%+.6f, geo:lon=%+.6f", [[LocationManager locationManager] latitude], [[LocationManager locationManager] longitude]]);
//	//NSLog([NSString stringWithFormat:@"geotagged, geo:lat=%+.6f, geo:lon=%+.6f", [[LocationManager locationManager] latitude], [[LocationManager locationManager] longitude]]);
	
	[req setHTTPBody:postBody];

	[self retain];
	self.connection = [[NSURLConnection alloc] initWithRequest:req 
												  delegate:self 
										  startImmediately:YES];
	if (!self.connection) 
	{
		[delegate uploadedImage:nil sender:self];
		//NSLog(@"release in [Uploader postJPEGData] (!self.connection)");
		[self release];
	}
	[TweetterAppDelegate increaseNetworkActivityIndicator];
	//NSLog(@"must be released in in mainthread destructor method");
}

//#ifndef USE_IS
- (void)postJPEGData:(NSData*)imageJPEGData delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	if(!imageJPEGData)
	{
		[delegate uploadedImage:nil sender:self];
		//NSLog(@"release in [Uploader imageJPEGData:delegate:userData:] (!imageJPEGData)");
		[self release];
	}
		
	self.delegate = dlgt;
	self.userData = data;

//	[[self retain] postJPEGData:[imageJPEGData retain]];
	[self postJPEGData:imageJPEGData];
}
/*#else

- (void)postJPEGImage:(NSData*)imageJPEGData delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	[self retain];
	
	if(!image)
	{
		[delegate uploadedImage:nil sender:self];
		[self release];
		return;
	}
		
	delegate = [dlgt retain];
	self.userData = data;

	NSString* login = [MGTwitterEngine username];
	NSString* pass = [MGTwitterEngine password];
	

	NSString *boundary = [NSString stringWithFormat:@"------%ld__%ld__%ld", random(), random(), random()];
	
	NSURL *url = [NSURL URLWithString:@"http://www.imageshack.us/upload_api.php"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];

	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-type"];
	
	//adding the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"fileupload\"; filename=\"iPhoneImage\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageJPEGData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[login dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[pass dataUsingEncoding:NSUTF8StringEncoding]];
	
	if([[LocationManager locationManager] locationDefined])
	{
		[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[postBody appendData:[@"Content-Disposition: form-data; name=\"tags\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[NSString stringWithFormat:@"geotagged, geo:lat=%+.6f, geo:lon=%+.6f", [[LocationManager locationManager] latitude], [[LocationManager locationManager] longitude]] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPBody:postBody];

	self.connection = [[NSURLConnection alloc] initWithRequest:req 
												  delegate:self 
										  startImmediately:YES];
	if (!self.connection) 
	{
		[delegate uploadedImage:nil sender:self];
		[self release];
	}
	[TweetterAppDelegate increaseNetworkActivityIndicator];
}
#endif*/

/*
CGSize calcDrawSizeForImageSize(CGSize imgSize, CGSize availableSize)
{
							
	CGSize drawSize;
	if(imgSize.height == 0 || imgSize.width == 0)
		drawSize = availableSize;
	else if(imgSize.width <= availableSize.width && imgSize.height <= availableSize.height)
		drawSize = imgSize;
	else
	{
		float kAvailable = availableSize.height / availableSize.width;
		float kImage = imgSize.height / imgSize.width;
		if(kAvailable < kImage)
		{
			drawSize.height = ceil(availableSize.height);
			drawSize.width = ceil(drawSize.height / kImage);
		}
		else
		{
			drawSize.width = ceil(availableSize.width);
			drawSize.height = ceil(drawSize.width * kImage);
		}
	}
	return drawSize;
}
*/


- (void)convertImageThreadAndStartUpload:(UIImage*)image
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//NSLog(@"5");
/*
	BOOL needToResize = [[NSUserDefaults standardUserDefaults] boolForKey:@"ScalePhotosBeforeUploading"] &&
							(image.size.width > IMAGE_SCALING_WIDTH || image.size.height > IMAGE_SCALING_HEIGHT);
	BOOL needToRotate = image.imageOrientation != UIImageOrientationUp;
							
	UIImage* modifiedImage = nil;
	CGSize newSize;
	if(needToResize)
	{
		CGSize maxSize = {IMAGE_SCALING_WIDTH, IMAGE_SCALING_HEIGHT};
		newSize = calcDrawSizeForImageSize(image.size, maxSize);
	}
	else if(needToRotate)
		newSize = image.size;

	if(needToResize || needToRotate)
		modifiedImage = imageScaledToSize(image, newSize);
*/
	NSData* imData = UIImageJPEGRepresentation(image, 1.0f);
	[self performSelectorOnMainThread:@selector(postJPEGData:) withObject:imData waitUntilDone:NO];

//	NSData* deleteme = UIImageJPEGRepresentation(image, 1.0f);
//	NSData* deleteme2 = UIImageJPEGRepresentation(image, 0.3f);
//	image = 
//	NSData* imData = UIImageJPEGRepresentation(modifiedImage ? modifiedImage : image, 1.0f);
//	NSData* imData = UIImageJPEGRepresentation(needToResize ? smallImage : image, .75f);
	//NSLog(@"6");
//	[self performSelectorOnMainThread:@selector(postJPEGData:) withObject:deleteme2 waitUntilDone:NO];
	//NSLog(@"7");
	
	[pool release];
}

- (void)postImage:(UIImage*)image delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	delegate = [dlgt retain];
	self.userData = data;

//	NSLog(@"3");

	UIImage* modifiedImage = nil;
/*	BOOL needToResize = [[NSUserDefaults standardUserDefaults] boolForKey:@"ScalePhotosBeforeUploading"] &&
							(image.size.width > IMAGE_SCALING_WIDTH || image.size.height > IMAGE_SCALING_HEIGHT);
	BOOL needToRotate = image.imageOrientation != UIImageOrientationUp;
							
	CGSize newSize;
	if(needToResize)
	{
		CGSize maxSize = {IMAGE_SCALING_WIDTH, IMAGE_SCALING_HEIGHT};
		newSize = calcDrawSizeForImageSize(image.size, maxSize);
	}
	else if(needToRotate)
		newSize = image.size;

	if(needToResize || needToRotate)
		modifiedImage = imageScaledToSize(image, newSize);
*/
	
	
	BOOL needToResize;
	BOOL needToRotate;
	int newDimension = isImageNeedToConvert(image, &needToResize, &needToRotate);
	if(needToResize || needToRotate)		
		modifiedImage = imageScaledToSize(image, newDimension);
//	NSLog(@"4");


	[NSThread detachNewThreadSelector:@selector(convertImageThreadAndStartUpload:) toTarget:self withObject:modifiedImage ? modifiedImage : image];
//	[NSThread detachNewThreadSelector:@selector(convertImageThreadAndStartUpload:) toTarget:self withObject:image];
//	[NSThread detachNewThreadSelector:@selector(convertImageThreadAndStartUpload:) toTarget:self withObject:[[image copy] autorelease]];
	//NSLog(@"4");
/*
	//NSLog(@"3");
//	NSData* imData = UIImageJPEGRepresentation(image, 1.0f);
	//NSLog(@"4");
	[self postJPEGImage:UIImageJPEGRepresentation(image, 1.0f) delegate:dlgt userData:data];
	//NSLog(@"5");
*/
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
//	NSLog(@"connection didFailWithError");
//	NSLog([error localizedDescription]);
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[delegate uploadedImage:nil sender:self];
	//NSLog(@"release in [Uploader connection:didFailWithError:]");
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

//#ifndef USE_IS
    if ([elementName isEqualToString:@"mediaurl"])
//#else
//    if ([elementName isEqualToString:@"mediaurl"])
//#endif
		self.contentXMLProperty = [NSMutableString string];
	else
		self.contentXMLProperty = nil;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName)
        elementName = qName;
    
//#ifndef USE_IS
    if ([elementName isEqualToString:@"mediaurl"])
//#else
//    if ([elementName isEqualToString:@"mediaurl"])
//#endif
	{
        self.newURL = [self.contentXMLProperty stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[parser abortParsing];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.contentXMLProperty)
		[self.contentXMLProperty appendString:string];
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
//NSLog(@"connectionDidFinishLoading");
//NSLog([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease]);
	[TweetterAppDelegate decreaseNetworkActivityIndicator];

	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:result];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	[parser parse];
	[parser release];

	[result setLength:0];
	
	[delegate uploadedImage:self.newURL sender:self];
	//NSLog(@"release in [Uploader connectionDidFinishLoading]");
	[self release];
}

- (void)cancel
{
	wasCanceled = YES;
	if(connection)
	{
		[connection cancel];
		//NSLog(@"release in [Uploader cancel]");
		[TweetterAppDelegate decreaseNetworkActivityIndicator];
		[self release];
	}
	[delegate uploadedImage:nil sender:self];
}

- (BOOL)wasCanceled
{
	return wasCanceled;
}


@end
