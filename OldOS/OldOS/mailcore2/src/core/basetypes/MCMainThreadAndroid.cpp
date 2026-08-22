//
//  MCMainThreadAndroid.cpp
//  mailcore2
//
//  Created by Hoa Dinh on 11/11/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCMainThread.h"
#include "MCMainThreadAndroid.h"
#include "com_libmailcore_MainThreadUtils.h"

#include <libetpan/libetpan.h>
#include <stdlib.h>
#include <pthread.h>

#include "MCDefines.h"
#include "MCAssert.h"
#include "MCLog.h"
#include "MCAutoreleasePool.h"
#include "TypesUtils.h"

using namespace mailcore;

struct main_thread_call_data {
  void (* function)(void *);
  void * context;
  struct mailsem * sem;
};

static jobject s_mainThreadUtils = NULL;
static jclass s_mainThreadUtilsClass = NULL;
static JavaVM * s_jvm = NULL;
static jint s_version = 0;

void mailcore::androidSetupThread(void)
{
    JNIEnv * env = NULL;
    s_jvm->AttachCurrentThread(&env, NULL);
}

void mailcore::androidUnsetupThread()
{
    s_jvm->DetachCurrentThread();
}

JNIEXPORT void JNICALL Java_com_libmailcore_MainThreadUtils_setupNative(JNIEnv * env, jobject object)
{
    AutoreleasePool * pool = new AutoreleasePool();

    env->GetJavaVM(&s_jvm);
    s_version = env->GetVersion();
    s_mainThreadUtils = reinterpret_cast<jobject>(env->NewGlobalRef(object));
    jclass localClass = env->FindClass("com/libmailcore/MainThreadUtils");
    s_mainThreadUtilsClass = reinterpret_cast<jclass>(env->NewGlobalRef(localClass));
    MCAssert(s_mainThreadUtilsClass != NULL);
    MCTypesUtilsInit();

    pool->release();
}

JNIEXPORT void JNICALL Java_com_libmailcore_MainThreadUtils_runIdentifier(JNIEnv * env, jobject object, jlong identifier)
{
    AutoreleasePool * pool = new AutoreleasePool();
    struct main_thread_call_data * data = (struct main_thread_call_data *) identifier;
    data->function(data->context);
    free(data);
    pool->release();
}

JNIEXPORT void JNICALL Java_com_libmailcore_MainThreadUtils_runIdentifierAndNotify(JNIEnv * env, jobject object, jlong identifier)
{
    AutoreleasePool * pool = new AutoreleasePool();
    struct main_thread_call_data * data = (struct main_thread_call_data *) identifier;
    data->function(data->context);
    mailsem_up(data->sem);
    pool->release();
}

void mailcore::callOnMainThread(void (* function)(void *), void * context)
{
    struct main_thread_call_data * data = (struct main_thread_call_data *) malloc(sizeof(* data));
    data->function = function;
    data->context = context;
    data->sem = NULL;
    
    JNIEnv * env = NULL;
    s_jvm->GetEnv((void **)&env, s_version);
    jmethodID mid = env->GetMethodID(s_mainThreadUtilsClass, "runOnMainThread", "(J)V");
    MCAssert(mid != NULL);
    env->CallVoidMethod(s_mainThreadUtils, mid, (jlong) data);
}

void mailcore::callOnMainThreadAndWait(void (* function)(void *), void * context)
{
    struct main_thread_call_data * data = (struct main_thread_call_data *) malloc(sizeof(* data));
    data->function = function;
    data->context = context;
    data->sem = mailsem_new();
    
    JNIEnv * env = NULL;
    s_jvm->GetEnv((void **)&env, s_version);
    jmethodID mid = env->GetMethodID(s_mainThreadUtilsClass, "runOnMainThreadAndWait", "(J)V");
    MCAssert(mid != NULL);
    env->CallVoidMethod(s_mainThreadUtils, mid, (jlong) data);

    // Wait.
    mailsem_down(data->sem);

    mailsem_free(data->sem);
    free(data);
}

void * mailcore::callAfterDelay(void (* function)(void *), void * context, double time)
{
    struct main_thread_call_data * data = (struct main_thread_call_data *) malloc(sizeof(* data));
    data->function = function;
    data->context = context;
    data->sem = NULL;
    
    JNIEnv * env = NULL;
    s_jvm->GetEnv((void **)&env, s_version);
    jmethodID mid = env->GetMethodID(s_mainThreadUtilsClass, "runAfterDelay", "(JI)V");
    MCAssert(mid != NULL);
    env->CallVoidMethod(s_mainThreadUtils, mid, (jlong) data, (jint) (time * 1000));
    return data;
}

void mailcore::cancelDelayedCall(void * delayedCall)
{
    JNIEnv * env = NULL;
    s_jvm->GetEnv((void **)&env, s_version);
    jmethodID mid = env->GetMethodID(s_mainThreadUtilsClass, "cancelDelayedRun", "(J)V");
    MCAssert(mid != NULL);
    env->CallVoidMethod(s_mainThreadUtils, mid, (jlong) delayedCall);
}
