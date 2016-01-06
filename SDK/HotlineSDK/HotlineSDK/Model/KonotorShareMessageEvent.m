//
//  KonotorShareMessageEvent.m
//  Konotor
//
//  Created by Vignesh G on 08/10/14.
//  Copyright (c) 2014 Vignesh G. All rights reserved.
//

#import "KonotorShareMessageEvent.h"
#import "KonotorDataManager.h"
#import "WebServices.h"

@implementation KonotorShareMessageEvent

@dynamic messageID;
@dynamic shareType;
@dynamic uploadStatus;


+(KonotorShareMessageEvent*) sharedMessageWithID:(NSString *)messageID withShareType:(NSString *)shareType
{
    
    
    
    KonotorShareMessageEvent *newEvent = (KonotorShareMessageEvent *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorShareMessageEvent" inManagedObjectContext:[[KonotorDataManager sharedInstance]mainObjectContext]];
    newEvent.messageID = messageID;
    newEvent.shareType = shareType ;
    [[KonotorDataManager sharedInstance]save];
    
    return newEvent;
    
}




+(void) UploadAllUnuploadedEvents{
    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorShareMessageEvent" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"uploadStatus == 0"];
    
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    
    if(!array || [array count]==0){
        return ;
    }
    else{
        for(int i=0;i<[array count];i++){
            KonotorShareMessageEvent *event = [array objectAtIndex:i];
            if(event)
            {
                [KonotorWebServices sendShareMessageEvent:event];
            }
        }
    }
}

@end
