//
//  Fragment.m
//  HotlineSDK
//
//  Created by user on 01/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//


#include "FCMessageFragments.h"
#include "FCFragmentData.h"
#include "FCConstants.h"

@implementation FCMessageFragments

    @dynamic content,contentType,type,index,status,binaryData1,binaryData2,extraJSON;

    +(NSArray *)getAllFragments:(FCMessages *) message {
        if(message) {
            NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY];
            fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"message.messageAlias == %@",message.messageAlias];
            NSSortDescriptor *sortByName    = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO];
            fetchRequest.sortDescriptors    = @[sortByName];
            NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
            NSArray *fragmentsArr  = [context executeFetchRequest:fetchRequest error:nil];
            NSMutableArray *fragmentDataArr = [[NSMutableArray alloc] init];
            for(int i=0;i<fragmentsArr.count;i++) {
                FCMessageFragments *fragment = fragmentsArr[i];
                FragmentData *data = [fragment ReturnFragmentDataFromManagedObject];
                [fragmentDataArr insertObject:data atIndex:0];
            }
            return fragmentDataArr;
        }
        return nil;
    }


    +(FCMessageFragments *) getImageFragment: (FCMessages *)message {
        if(message) {
            NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY];
            fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"message.messageAlias == %@ AND type==2",message.messageAlias];
            NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
            NSArray *fragmentsArr  = [context executeFetchRequest:fetchRequest error:nil];
            return fragmentsArr.firstObject;
        }
        return nil;
    }

    +(NSArray *)getAllFragmentsInDictionary:(FCMessages *) message {
        if(message) {
            NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY];
            fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"message.messageAlias == %@",message.messageAlias];
            NSSortDescriptor *sortByName    = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
            fetchRequest.sortDescriptors    = @[sortByName];
            NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
            NSArray *fragmentsArr  = [context executeFetchRequest:fetchRequest error:nil];
            NSMutableArray *fragmentDictArr = [[NSMutableArray alloc] init];
            for(int i=0;i<fragmentsArr.count;i++) {
                FCMessageFragments *fragment = fragmentsArr[i];
                [fragmentDictArr insertObject:[fragment toDictionary] atIndex:0];
            }
            return fragmentDictArr;
        }
        return nil;
    }



    +(void) createFragments:(NSArray *) dictArr toMessage:(FCMessages *) message {
        for (int i=0; i <dictArr.count; i++) {
            NSDictionary *info = dictArr[i];
            NSMutableDictionary *fragmentInfo = [info mutableCopy];
            if(fragmentInfo) {
                NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
                FCMessageFragments *fragment = (FCMessageFragments *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY inManagedObjectContext:context];

                fragment.content = fragmentInfo[@"content"];
                fragment.contentType = fragmentInfo[@"contentType"];
                fragment.type = [NSString stringWithFormat:@"%@",fragmentInfo[@"fragmentType"]];
                fragment.index = fragmentInfo[@"position"];
                fragment.status = [[NSNumber alloc]initWithInt:ToBeDownloaded];
                
                [fragmentInfo removeObjectForKey:@"content"];
                [fragmentInfo removeObjectForKey:@"contentType"];
                [fragmentInfo removeObjectForKey:@"fragmentType"];
                [fragmentInfo removeObjectForKey:@"position"];
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fragmentInfo
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:nil];
                NSString *jsonString = @"";
                if (jsonData) {
                    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    
                }
                fragment.extraJSON = jsonString;
                [fragment setValue:message forKey:@"message"];
                [[FCDataManager sharedInstance]save];
            }
        }
    }

    +(FCMessageFragments *) createUploadFragment: (NSDictionary *)info toMessage:(FCMessages *) message {
        NSMutableDictionary *fragmentInfo = [info mutableCopy];
        NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
        FCMessageFragments *fragment = (FCMessageFragments *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY inManagedObjectContext:context];
        fragment.content = fragmentInfo[@"content"];
        fragment.contentType = fragmentInfo[@"contentType"];
        fragment.type = [NSString stringWithFormat:@"%@",fragmentInfo[@"fragmentType"]];
        fragment.index = fragmentInfo[@"position"];
        fragment.status = [[NSNumber alloc]initWithInt:UploadDownloadComplete];
        
        if(fragmentInfo[@"binaryData1"]) { //For image
            fragment.binaryData1 = fragmentInfo[@"binaryData1"];
            [fragmentInfo removeObjectForKey:@"binaryData1"];
            fragment.status = [[NSNumber alloc]initWithInt:ToBeUploaded];
        }
        
        if(fragmentInfo[@"binaryData2"]) { //For thumbnail
            fragment.binaryData2 = fragmentInfo[@"binaryData2"];
            [fragmentInfo removeObjectForKey:@"binaryData2"];
            fragment.status = [[NSNumber alloc]initWithInt:ToBeUploaded];
        }
        
        [fragmentInfo removeObjectForKey:@"content"];
        [fragmentInfo removeObjectForKey:@"contentType"];
        [fragmentInfo removeObjectForKey:@"fragmentType"];
        [fragmentInfo removeObjectForKey:@"position"];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fragmentInfo
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        NSString *jsonString = @"";
        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
        }
        fragment.extraJSON = jsonString;
        [fragment setValue:message forKey:@"message"];
        return fragment;
    }

    -(void)updateWithInfo:(NSDictionary *)info {
        NSMutableDictionary *dictionary = [info mutableCopy];
        self.content = dictionary[@"content"];
        self.contentType = dictionary[@"contentType"];
        self.type = [NSString stringWithFormat:@"%@",dictionary[@"fragmentType"]];
        self.status = [[NSNumber alloc]initWithInt:UploadDownloadComplete];
        
        [dictionary removeObjectForKey:@"content"];
        [dictionary removeObjectForKey:@"contentType"];
        [dictionary removeObjectForKey:@"fragmentType"];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        NSString *jsonString = @"";
        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
        }
        self.extraJSON = jsonString;
    }

    -(FragmentData *) ReturnFragmentDataFromManagedObject {
        if (self) {
            FragmentData *fragmentData = [[FragmentData alloc]init];
            fragmentData.content = [self content];
            fragmentData.contentType = [self contentType];
            fragmentData.extraJSON = [self extraJSON];
            fragmentData.type = [self type];
            fragmentData.index = [self index];
            fragmentData.status = [self status];
            fragmentData.binaryData1 = [self binaryData1];
            fragmentData.binaryData2 = [self binaryData2];
            return fragmentData;
        }
        return nil;
    }

    - (NSDictionary *)toDictionary {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"content"] = [self content];
        dict[@"contentType"] = [self contentType];
        dict[@"fragmentType"] = [self type];
        dict[@"position"] = [self index];
        NSString *extraJSONStr = [self extraJSON];
        if (![extraJSONStr isEqualToString:@""]) {
            NSData *data = [extraJSONStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *extraJSONdict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            [dict addEntriesFromDictionary:extraJSONdict];
        }
        return dict;
    }

@end


@implementation FragmentData

-(void)storeImageDataOfMessage:(FCMessageData *)message withCompletion:(void (^)())completion {
    if(![self.content isEqualToString:@""]) {
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData *extraJSONData = [self.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
            NSData * imageThumbData;
            NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [self content]]];
            
            if(extraJSONDict[@"thumbnail"]) {
                NSDictionary *thumbnailDict = extraJSONDict[@"thumbnail"];
                if(![thumbnailDict[@"content"] isEqualToString:@""]) {
                    imageThumbData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: thumbnailDict[@"content"]]];
                }
            }
            [self setBinaryData1:imageData];
            [self setBinaryData2:imageThumbData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateBinaryDataOfMessage:message];
                if(completion){
                    completion();
                }
            });
        });
    } else {
        if(completion){
            completion();
        }
    }
}

-(void) updateBinaryDataOfMessage:(FCMessageData *)message{
    if(message) {
        NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY];
        fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"message.messageAlias == %@ AND content==%@",message.messageAlias,self.content];
        NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
        NSArray *fragmentsArr  = [context executeFetchRequest:fetchRequest error:nil];
        for(int i=0;i<fragmentsArr.count;i++) {
            FCMessageFragments *fragment = fragmentsArr[i];
            [fragment setBinaryData1:[self binaryData1]];
            [fragment setBinaryData2:[self binaryData2]];
            [[FCDataManager sharedInstance]save];
        }
    }
}

- (NSURL *) getOpenURL {
    NSURL *url;
    NSData *extraJSONData = [self.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData
                                                                  options:0
                                                                    error:&err];
    if(!err && extraJSONDict[@"iosUri"] != nil) {
        url = [[NSURL alloc]initWithString:extraJSONDict[@"iosUri"]];
    }
    if(url == nil) {
        url = [[NSURL alloc] initWithString:self.content];
    }
    return url;
}

- (BOOL)isQuickReplyFragment {
    NSData *extraJSONData = [self.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData
                                                                  options:0
                                                                    error:&err];
    if(!err && extraJSONDict[@"fragments"]) {
        NSArray *fragments = extraJSONDict[@"fragments"];
        for(int i=0; i< fragments.count; i++) {
            NSDictionary *fragmentDictionary = fragments[i];
            if(fragmentDictionary[@"fragmentType"] && [fragmentDictionary[@"fragmentType"] intValue] == FRESHCHAT_REPLY_FRAGMENT) {
                return true;
            }
        }
    }
    
    return false;
}

@end
