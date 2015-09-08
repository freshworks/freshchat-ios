//
//  Konotor_cpp.cpp
//  samples
//
//  Created by Vignesh G on 23/09/13.
//
//

#include "Konotor_cpp.h"
#import "Konotor.h"
#import "KonotorUI.h"

id  unreadCountObserver = nil;
static int prevUnreadCount = -1;

void KonotorCocos2dx::showFeedbackWidget()
{
    [KonotorFeedbackScreen showFeedbackScreen];
    
}

void KonotorCocos2dx::setEmail(char *email)
{
    NSString *nsemail = [NSString stringWithUTF8String:email];
    [Konotor setUserEmail:nsemail];
}
void KonotorCocos2dx::setUsername(char *username)
{
    NSString *nsusername = [NSString stringWithUTF8String:username];
    [Konotor setUserName:nsusername];
    
}

void KonotorCocos2dx::setUserIdentifier(char *userid)
{
    NSString *nsuserid = [NSString stringWithUTF8String:userid];
    [Konotor setUserIdentifier:nsuserid];
    
}



void KonotorCocos2dx::setUserMeta(char *key,char *value)
{
    NSString *nsValue = [NSString stringWithUTF8String:value];
    NSString *nsKey = [NSString stringWithUTF8String:key];
    [Konotor setCustomUserProperty:nsValue forKey:nsKey];
}

void KonotorCocos2dx::update()
{
    return;
}

void KonotorCocos2dx::subscribeToUnreadCountChange(void (*callbackFunction) (void))
{
    if(unreadCountObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:unreadCountObserver];
    
    
    unreadCountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"KonotorUnreadMessagesCount" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
                           {
                               int unreadCount = getUnreadCount();
                               
                               if(unreadCount != prevUnreadCount)
                               {
                                   prevUnreadCount = unreadCount;
                                   callbackFunction();
                               }
                           }];
    
    
}

int KonotorCocos2dx::getUnreadCount()
{
    return [Konotor getUnreadMessagesCount];
}


void KonotorCocos2dx::unSubscribeToUnreadCountChange()
{
    if(unreadCountObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:unreadCountObserver];
    
}


