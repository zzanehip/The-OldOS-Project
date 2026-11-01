//
//  MCMainThreadGTK.cpp
//  mailcore2
//
//  Created by Hoa Dinh on 11/11/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCMainThread.h"

#include <glib.h>
#include <stdlib.h>
#include <libetpan/libetpan.h>

struct main_thread_call_data {
  void (* function)(void *);
  void * context;
  struct mailsem * sem;
};

static gboolean main_thread_wrapper(struct main_thread_call_data * data)
{
  data->function(data->context);
  free(data);
  return G_SOURCE_REMOVE;
}

void mailcore::callOnMainThread(void (* function)(void *), void * context)
{
  struct main_thread_call_data * data = (struct main_thread_call_data *) malloc(sizeof(* data));
  data->function = function;
  data->context = context;
  data->sem = NULL;
  g_idle_add((GSourceFunc) main_thread_wrapper, (gpointer) data);
}

static gboolean main_thread_wait_wrapper(struct main_thread_call_data * data)
{
  data->function(data->context);
  mailsem_up(data->sem);
  return G_SOURCE_REMOVE;
}

void mailcore::callOnMainThreadAndWait(void (* function)(void *), void * context)
{
  struct main_thread_call_data * data = (struct main_thread_call_data *) malloc(sizeof(* data));
  data->function = function;
  data->context = context;
  data->sem = mailsem_new();
  g_idle_add((GSourceFunc) main_thread_wait_wrapper, (gpointer) data);
  
  // Wait.
  mailsem_down(data->sem);
  
  mailsem_free(data->sem);
  free(data);
}

struct call_after_delay_data {
  void (* function)(void *);
  void * context;
  guint source_id;
};

static gboolean call_after_delay_wrapper(struct main_thread_call_data * data)
{
  data->function(data->context);
  free(data);
  return G_SOURCE_REMOVE;
}

static void call_after_delay_destroy_notify(struct main_thread_call_data * data)
{
  // Do nothing.
}

void * mailcore::callAfterDelay(void (* function)(void *), void * context, double time)
{
  struct call_after_delay_data * data = (struct call_after_delay_data *) malloc(sizeof(* data));
  data->function = function;
  data->context = context;
  data->source_id = g_timeout_add_full(G_PRIORITY_DEFAULT, (guint) (time * 1000),
                      (GSourceFunc) call_after_delay_wrapper, data,
                      (GDestroyNotify) call_after_delay_destroy_notify);
  return data;
}

void mailcore::cancelDelayedCall(void * delayedCall)
{
  struct call_after_delay_data * data = (struct call_after_delay_data *) delayedCall;
  g_source_remove(data->source_id);
  free(data);
}
