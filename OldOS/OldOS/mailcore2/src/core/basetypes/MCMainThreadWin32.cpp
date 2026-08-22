//
//  MCMainThreadWin32.cpp
//  mailcore2
//
//  Created by Hoa Dinh on 11/11/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//
#include "MCWin32.h"

#include "MCMainThread.h"

#include <stdlib.h>
#include <pthread.h>
#include <libetpan/libetpan.h>

#include "MCDefines.h"

static HWND threadingWindowHandle;
static UINT threadingFiredMessage;
static const LPCWSTR kThreadingWindowClassName = L"ThreadingWindowClass";
static chash * timers = NULL;

struct call_after_delay_data {
    void (* function)(void *);
    void * context;
    UINT_PTR timer_id;
};

struct main_thread_call_data {
    void (* function)(void *);
    void * context;
    struct mailsem * sem;
};

static void main_thread_wrapper(struct main_thread_call_data * data);
static void main_thread_wait_wrapper(struct main_thread_call_data * data);
static void call_after_delay_wrapper(struct call_after_delay_data * data);

LRESULT CALLBACK ThreadingWindowWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    if (message == threadingFiredMessage) {
        struct main_thread_call_data * data = (struct main_thread_call_data *) wParam;
        if (data->sem != NULL) {
            main_thread_wait_wrapper(data);
        }
        else {
            main_thread_wrapper(data);
        }
        return 0;
    }
    else if (message == WM_TIMER) {
		UINT_PTR timer_id = wParam;
		chashdatum key;
		chashdatum value;
		key.data = &timer_id;
		key.len = sizeof(timer_id);
		chash_get(timers, &key, &value);
		struct call_after_delay_data * data = (struct call_after_delay_data *) value.data;
        call_after_delay_wrapper(data);
        return 0;
    }
    else {
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
}

static void main_thread_wrapper(struct main_thread_call_data * data)
{
    data->function(data->context);
    free(data);
}

void mailcore::callOnMainThread(void (* function)(void *), void * context)
{
    struct main_thread_call_data * data = (struct main_thread_call_data *) malloc(sizeof(* data));
    data->function = function;
    data->context = context;
    data->sem = NULL;
	PostMessage(threadingWindowHandle, threadingFiredMessage, (WPARAM) data, 0);
}

static void main_thread_wait_wrapper(struct main_thread_call_data * data)
{
    data->function(data->context);
    mailsem_up(data->sem);
}

void mailcore::callOnMainThreadAndWait(void (* function)(void *), void * context)
{
    struct main_thread_call_data * data = (struct main_thread_call_data *) malloc(sizeof(* data));
    data->function = function;
    data->context = context;
    data->sem = mailsem_new();
	PostMessage(threadingWindowHandle, threadingFiredMessage, (WPARAM) data, 0);
  
    // Wait.
    mailsem_down(data->sem);
  
    mailsem_free(data->sem);
    free(data);
}

static void call_after_delay_wrapper(struct call_after_delay_data * data)
{
    data->function(data->context);
    KillTimer(threadingWindowHandle, data->timer_id);
	chashdatum key;
	key.data = &data->timer_id;
	key.len = sizeof(data->timer_id);
	chash_delete(timers, &key, NULL);
	free(data);
}

static uint64_t generate_timer_id()
{
	static uint64_t uniqueTimerID = 1;
	return uniqueTimerID++;
}

void * mailcore::callAfterDelay(void (* function)(void *), void * context, double time)
{
    struct call_after_delay_data * data = (struct call_after_delay_data *) malloc(sizeof(* data));
    data->function = function;
    data->context = context;
	UINT_PTR timer_id = (UINT_PTR) generate_timer_id();
	data->timer_id = SetTimer(threadingWindowHandle, timer_id, (int)(time * 1000), NULL);
	chashdatum key;
	chashdatum value;
	key.data = &data->timer_id;
	key.len = sizeof(data->timer_id);
	value.data = data;
	value.len = 0;
	chash_set(timers, &key, &value, NULL);
	return data;
}

void mailcore::cancelDelayedCall(void * delayedCall)
{
    struct call_after_delay_data * data = (struct call_after_delay_data *) delayedCall;
    KillTimer(threadingWindowHandle, data->timer_id);
	chashdatum key;
	key.data = &data->timer_id;
	key.len = sizeof(data->timer_id);
	chash_delete(timers, &key, NULL);
    free(data);
}

INITIALIZE(MainThreadWin32)
{
    WNDCLASSW wcex;
    memset(&wcex, 0, sizeof(wcex));
    wcex.lpfnWndProc    = ThreadingWindowWndProc;
    wcex.lpszClassName  = kThreadingWindowClassName;
    RegisterClassW(&wcex);

    threadingWindowHandle = CreateWindowW(kThreadingWindowClassName, 0, 0,
    CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, HWND_MESSAGE, 0, 0, 0);
    threadingFiredMessage = RegisterWindowMessageW(L"com.libmailcore.mailcore2.MainThreadFired");

	timers = chash_new(CHASH_DEFAULTSIZE, CHASH_COPYKEY);
}
