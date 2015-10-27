//
//  Konotor_cpp.h
//  samples
//
//  Created by Vignesh G on 23/09/13.
//
//

#ifndef __samples__Konotor_cpp__
#define __samples__Konotor_cpp__

#include <iostream>
class KonotorCocos2dx {
public:
    static void showFeedbackWidget();
    static void setEmail(char *email);
    static void setUsername(char *userName);
    static void setUserIdentifier(char *userIdentifier);
    static void setUserMeta(char *key, char *value);
    static void update();
    static int getUnreadCount();
    static void subscribeToUnreadCountChange(void (*callbackFunction) (void));
    static void unSubscribeToUnreadCountChange();

};


#endif /* defined(__samples__Konotor_cpp__) */
