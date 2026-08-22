//
//  MCIMAPMultiDisconnectOperation.cc
//  mailcore2
//
//  Created by Hoa V. DINH on 11/7/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPMultiDisconnectOperation.h"

using namespace mailcore;

IMAPMultiDisconnectOperation::IMAPMultiDisconnectOperation()
{
    _count = 0;
    _operations = new Array();
}

IMAPMultiDisconnectOperation::~IMAPMultiDisconnectOperation()
{
    MC_SAFE_RELEASE(_operations);
}

void IMAPMultiDisconnectOperation::addOperation(IMAPOperation * op)
{
    _operations->addObject(op);
}

void IMAPMultiDisconnectOperation::start()
{
    if (_operations->count() == 0) {
        if (callback() != NULL) {
            callback()->operationFinished(this);
        }
        return;
    }
    
    retain();
    mc_foreacharray(IMAPOperation, op, _operations) {
#if __APPLE__
        op->setCallbackDispatchQueue(this->callbackDispatchQueue());
#endif
        op->setCallback(this);
        op->start();
    }
}

void IMAPMultiDisconnectOperation::operationFinished(Operation * op)
{
    _count ++;
    if (_count == _operations->count()) {
        if (callback() != NULL) {
            callback()->operationFinished(this);
        }
        release();
    }
}

