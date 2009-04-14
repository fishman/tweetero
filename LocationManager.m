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

#import "LocationManager.h"
#import "TweetterAppDelegate.h"

static LocationManager *globalLocationManager = nil;
static BOOL initialized = NO;

@implementation LocationManager

@synthesize tinyURL;


+ (LocationManager*)locationManager
{
	if(!globalLocationManager) 
		globalLocationManager = [[LocationManager allocWithZone:nil] init];
	return globalLocationManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
	{
		if (globalLocationManager == nil) 
			globalLocationManager = [super allocWithZone:zone];
    }
	
    return globalLocationManager;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)retain
{
    return self;
}


- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}


- (void)release
{
    //do nothing
}


- (id)autorelease
{
    return self;
}

-(void)reset
{
	locationDefined = NO;
	latitude = 0.f;
	longitude = 0.f;
}

- (id)init
{
	if(initialized)
		return globalLocationManager;
	
	self = [super init];
    if (!self)
	{
		if(globalLocationManager)
			[globalLocationManager release];
		return nil;
	}

	
	locationManager = nil;
	initialized = YES;
	locationDenied = NO;
	[self reset];
    return self;
}

-(void)dealloc
{
	if(locationManager)
		[locationManager release];
	[super dealloc];
}

- (void) stopUpdates
{
	if (locationManager)
	{
		//NSLog(@"[locationManager stopUpdatingLocation];");
		[locationManager stopUpdatingLocation];
//		[NSThread sleepForTimeInterval:1];
//		[locationManager stopUpdatingLocation];
	}
	[self reset];
}

- (void) startUpdates
{
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocations"])
	{
		[self stopUpdates];
		return;
	}
		
	if (locationManager)
	{
		//NSLog(@"[locationManager stopUpdatingLocation];");
		[locationManager stopUpdatingLocation];
	}
	else
	{
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		locationManager.distanceFilter = 100; //50; // meters
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; //kCLLocationAccuracyBest;//kCLLocationAccuracyKilometer;
	}
	
	locationDefined = NO;
	
	//NSLog(@"[locationManager start UpdatingLocation];");
	[locationManager startUpdatingLocation];
}

- (NSString*) urlFormat
{
//	return @"http://maps.google.com/maps?q=image+taken+here+%+.6f,%+.6f";
//	return @"http://maps.google.com/maps?q=image+taken+here@%+.6f,%+.6f";
	return @"http://maps.google.com/maps?q=%+.6f,%+.6f";
//	return @"<a href=\"http://maps.google.com/maps?q=%+.6f,%+.6f\">test</a>";
}


- (NSString*) longURLWithLatitude:(float)lat  longitude:(float)lon
{
	return [NSString stringWithFormat:[self urlFormat], lat, lon];
}

- (NSString*) longURL
{
	return locationDefined ? [self longURLWithLatitude:latitude  longitude:longitude] : nil;
}

- (NSString*) mapURL
{
	if(!locationDefined) 
		return nil;

	return tinyURL ? tinyURL : [self longURL];

	
	
//	return locationDefined ? [NSString stringWithFormat:[self urlFormat], latitude, longitude] : 0;
}



- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation  fromLocation:(CLLocation *)oldLocation
{
	//NSLog(@"New location %@", [newLocation description]);

//    NSDate* eventDate = newLocation.timestamp;
//    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow]; //its seconds
//    if( abs(howRecent) < kLocationExpiresInterval )
//	{
		// Disable future updates to save power.
		//do not stop updating location. Do not save battery power and life. Made by explicitly saying "do this" by Vadim Zaliva (somewhere in bugzilla).
	//	[manager stopUpdatingLocation];
		
	//NSLog(@"latitude %+.6f, longitude %+.6f\n",  latitude, longitude);

	locationDenied = NO;
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocations"])
	{
		[self stopUpdates];
		return;
	}


	if(!tinyURL || ![self longURL] || ![[self longURL] isEqualToString:[self longURLWithLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude]])
	{
		latitude = newLocation.coordinate.latitude;
		longitude = newLocation.coordinate.longitude;
		locationDefined = YES;
		tinyURL = nil;
		//NSLog(@"UpdateTunyMapURL");
		[TweetterAppDelegate increaseNetworkActivityIndicator];
		[NSThread  detachNewThreadSelector:@selector(getTinyURLFromServer:) toTarget:self withObject:[self longURL]];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateLocationNotification" object: nil];
	}
/*	}
	else //coordinates expires, iPhone is not able to detect new coordinates
	{
		//NSLog(@"Location expired. %@", eventDate);
		[self reset];
	}*/
}

- (BOOL) locationDenied
{
	return locationDenied;
}

- (BOOL) locationServicesEnabled
{
	CLLocationManager* lm = locationManager;
	if(!lm)
		lm = [[[CLLocationManager alloc] init] autorelease];
	return lm.locationServicesEnabled;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	[self reset];

    if ([error domain] == kCLErrorDomain) 
	{
        switch ([error code]) 
		{
            case kCLErrorDenied:
				locationDenied = YES;
				[self stopUpdates];
                break;
            case kCLErrorLocationUnknown:
                break;
            default:
                break;
        }
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateLocationNotification" object: nil];
	
/*

	if ([error domain] == kCLErrorDomain) 
	{

		// We handle CoreLocation-related errors here

		switch ([error code]) 
		{
			// This error code is usually returned whenever user taps "Don't Allow" in response to
			// being told your app wants to access the current location. Once this happens, you cannot
			// attempt to get the location again until the app has quit and relaunched.
			//
			// "Don't Allow" on two successive app launches is the same as saying "never allow". The user
			// can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
			//
			case kCLErrorDenied:
			// This error code is usually returned whenever the device has no data or WiFi connectivity,
			// or when the location cannot be determined for some other reason.
			//
			// CoreLocation will keep trying, so you can keep waiting, or prompt the user.
			//
			case kCLErrorLocationUnknown:
			// We shouldn't ever get an unknown error code, but just in case...
			//
			default:
				[self reset];
				break;
		}
	} 
	else 
	{
		// We handle all non-CoreLocation errors here
		// (we depend on localizedDescription for localization)
		[errorString appendFormat:@"Error domain: \"%@\"  Error code: %d\n", [error domain], [error code]];
		[errorString appendFormat:@"Description: \"%@\"\n", [error localizedDescription]];
	}*/
}

- (BOOL) locationDefined
{
	return locationDefined;
}

- (float) latitude
{
	return latitude;
}

- (float) longitude
{
	return longitude;
}

/*
- (unsigned) mapURLLen
{
//	return locationDefined ? [[self urlFormat] length] + 11 - 5 + 11 - 5 + 1 : 0; // %+.6f replacement on -123.123456
	return locationDefined ? 24 : 0; // %+.6f replacement on -123.123456p
}
*/

/*
- (NSString*) mapURL
{
	if(!locationDefined) return nil;
	
	NSString *longURL = [NSString stringWithFormat:[self urlFormat], latitude, longitude];
	NSString *alias = [NSString stringWithFormat:@"y%08x", (int)time(NULL)];
	
	NSData *page = [NSData dataWithContentsOfURL:
		[NSURL URLWithString:
			[NSString stringWithFormat:@"http://tinyurl.com/create.php?url=%@&alias=%@", longURL, alias]
		]];
	
	if(!page) return nil;
	
	NSString* mapURL = [NSString stringWithFormat:@"http://tinyurl.com/y%08x", (int)time(NULL)];
//NSLog(mapURL);
//NSLog(alias);
	return mapURL;
	
//	return locationDefined ? [NSString stringWithFormat:[self urlFormat], latitude, longitude] : 0;
}
*/

- (void) setTinyURLOnMainThread:(NSArray*)urls
{
	//NSLog(@"setTinyURL performSelectorOnMainThread");
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	NSString* tiny = [urls objectAtIndex:0] == [NSNull null] ? nil : [urls objectAtIndex:0];
	NSString* full =[urls objectAtIndex:1];
	if([full isEqualToString:[self longURL]] || !self.tinyURL)
		self.tinyURL = tiny;
//	[urls release];
}

- (void)getTinyURLFromServer:(NSString*)longURL
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *alias = [NSString stringWithFormat:@"y%08x", ((int)time(NULL))];
	
	NSData *page = [NSData dataWithContentsOfURL:
		[NSURL URLWithString:[NSString stringWithFormat:@"http://tinyurl.com/create.php?url=%@&alias=%@", longURL, alias]]];

	id tiny = page ? [NSString stringWithFormat:@"http://tinyurl.com/%@", alias] : [NSNull null];
	//NSLog(@"http://tinyurl.com/%@ was %@getted", alias, page ? @"": @"NOT ");
	NSArray* urls =  [[[NSArray alloc] initWithObjects: tiny, [[longURL copy] autorelease], nil] autorelease];
	[self performSelectorOnMainThread:@selector(setTinyURLOnMainThread:) withObject:urls waitUntilDone:NO];

//	[longURL release];
	
	[pool release];
}


@end
