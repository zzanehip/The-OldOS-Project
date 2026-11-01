package com.libmailcore;

/** Listener of the queue of operations. */
public interface OperationQueueListener {
    /** Called when an operation has just been added and operations start running. */
    void queueStartRunning();
    /** Called when all operations have ben run. */
    void queueStoppedRunning();
}

