package com.libmailcore;

import java.util.Map;
import java.io.Serializable;
import java.io.IOException;

/** Native C++ Object wrapper. */
public class NativeObject implements Cloneable, Serializable {
    protected void finalize() throws Throwable
    {
        super.finalize();
        unsetupNative();
    }

    protected native void initWithNative(long nativeHandle);
    private native void unsetupNative();
    /** Returns a string representing the object. */
    public native String toString();
    /** Create a copy of the object. */
    public native Object clone() throws CloneNotSupportedException;

    private long nativeHandle;

    private static final long serialVersionUID = 1L;

    protected void writeObject(java.io.ObjectOutputStream out) throws IOException {
        byte[] data = serializableData();
        out.writeInt(data.length);
        out.write(data, 0, data.length);
    }

    protected void readObject(java.io.ObjectInputStream in) throws IOException, ClassNotFoundException {
        int len = in.readInt();
        byte[] data = new byte[len];
        in.read(data, 0, len);
    }

    private native byte[] serializableData();
    private native void importSerializableData(byte[] data);

    static {
        MainThreadUtils.singleton();
    }
}
