//
//  LibertyBase.m
//  Liberty
//
//  Created by Christian Fowler on 11/15/11.
//  Copyright 2011 Viovio.com. All rights reserved.
//

#import "LibertyBase.h"
#import "AppDelegateConnector.h"

@implementation LibertyBase

@synthesize uuId;
@synthesize contentId;
@synthesize userId;
@synthesize dateCreated;
@synthesize dateLastModified;
@synthesize title;
@synthesize displayUri;

- (NSDictionary*)getAllPropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"contentId",@"content_id",
                                     @"userId",@"user_id",
                                     @"dateCreated",@"date_created",
                                     @"dateLastModified",@"date_last_modified", 
                                     @"uuId",@"uuid",
                                     @"displayUri",@"display_uri",
                                     nil
                                     ];
    [mappings addEntriesFromDictionary:[self getSendablePropertyMappings]];
    return mappings;
}

- (NSDictionary*)getSendablePropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"title",@"title",
                                     nil];  
    return mappings;
}  

- (void)loadFromRemoteProperties:(NSDictionary *)remoteHash {
    NSDictionary *properties = [self getAllPropertyMappings];
    for (NSString* key in [remoteHash allKeys] ) {
        NSString *propertyName = [properties objectForKey:key];
        if ( [self respondsToSelector:NSSelectorFromString( propertyName )] ) {
            [self setValue:[remoteHash objectForKey:key] forKey:propertyName];
            NSLog(@"loadRemote %@ %@ %@", key, propertyName, [remoteHash objectForKey:key] );
        }
    }
}

- (NSString *) generateId {
    CFUUIDRef newIdRef = CFUUIDCreate(NULL);
    CFStringRef idString = CFUUIDCreateString(NULL, newIdRef);
    CFRelease(newIdRef);
    return (__bridge_transfer NSString *)idString;
}

- (BOOL) createDirectory:(NSString *)directory {
    BOOL ret = YES;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *fileError = nil;
    
    // Create the root bookPath
    if( ![fileManager fileExistsAtPath:directory]) {
        if( ![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&fileError] ) {
            ret = NO;
            NSLog( @"%@", fileError );
        }
    }
    return ret;
}

#pragma mark - REST methods

@end