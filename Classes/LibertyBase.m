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

@synthesize bookId=_bookId;
@synthesize uuId;
@synthesize userId;
@synthesize dateCreated;
@synthesize dateLastModified;

- (NSDictionary*)getReceivablePropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"userId",@"user_id",
                                     @"dateCreated",@"date_created",
                                     @"dateLastModified",@"date_last_modified", 
                                     nil
                                     ];
    [mappings addEntriesFromDictionary:[self getSendablePropertyMappings]];
    return mappings;
}

- (NSDictionary*)getSendablePropertyMappings {  
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"uuId",@"uuid",
            @"title",@"title",
            nil
            ];
}

- (void)loadFromRemoteProperties:(NSDictionary *)remoteHash {
    NSDictionary *properties = [self getReceivablePropertyMappings];
    for (NSString* key in [remoteHash allKeys] ) {
        NSString *varName = [properties objectForKey:key];
        if( varName != nil ) {
            [self setValue:[remoteHash objectForKey:key] forKey:varName];
        }
        NSLog(@"%@ %@ %@", key, [properties objectForKey:key], [remoteHash objectForKey:key] );
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