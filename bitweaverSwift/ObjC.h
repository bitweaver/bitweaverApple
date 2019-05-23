/*
 From https://stackoverflow.com/questions/32758811/catching-nsexception-in-swift
 
 Now you can use
 
 do {
     try ObjC.catchException {
         // calls that might throw an NSException
     }
  }
  catch {
    print("An error ocurred: \(error)")
  }
 
 Don't forget to add this to your "*-Bridging-Header.h":
 
 #import "ObjC.h"
*/

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
