//
//  MCOSMTPLoginOperation.m
//  mailcore2
//
//  Created by Hironori Yoshida on 10/29/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "MCOSMTPLoginOperation.h"

#include "MCSMTPLoginOperation.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCOSMTPOperation+Private.h"
#import "MCOSMTPSession.h"

typedef void (^CompletionType)(NSError *error);

@implementation MCOSMTPLoginOperation {
    CompletionType _completionBlock;
}

#define nativeType mailcore::SMTPLoginOperation

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    nativeType * op = (nativeType *) object;
    return [[[self alloc] initWithMCOperation:op] autorelease];
}

- (void) dealloc
{
    [_completionBlock release];
    [super dealloc];
}

- (void) start:(void (^)(NSError *error))completionBlock
{
    _completionBlock = [completionBlock copy];
    [self start];
}

- (void) cancel
{
    [_completionBlock release];
    _completionBlock = nil;
    [super cancel];
}

- (void)operationCompleted
{
    if (_completionBlock == NULL)
        return;
    
    nativeType *op = MCO_NATIVE_INSTANCE;
    if (op->error() == mailcore::ErrorNone) {
        _completionBlock(nil);
    } else {
        NSError * error = [NSError mco_errorWithErrorCode:op->error()];
        MCOSMTPSession *session = [self session];
        if ([session lastSMTPResponse] || [session lastSMTPResponseCode]) {
            NSMutableDictionary * userInfo = [[error userInfo] mutableCopy];
            if ([session lastSMTPResponse]) {
                userInfo[MCOSMTPResponseKey] = [session lastSMTPResponse];
            }
            if ([session lastSMTPResponseCode]) {
                userInfo[MCOSMTPResponseCodeKey] = @([session lastSMTPResponseCode]);
            }
            error = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfo];
        }
        _completionBlock(error);
    }
    [_completionBlock release];
    _completionBlock = NULL;
}


@end
