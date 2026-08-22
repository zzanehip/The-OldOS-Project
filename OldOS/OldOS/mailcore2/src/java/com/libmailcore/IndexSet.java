package com.libmailcore;

import java.util.List;

/** Unordered set of indexes. */
public class IndexSet extends NativeObject {
    /** Constructor. */
    public IndexSet() {
        setupNative();
    }
    
    /** Returns an empty set of indexes. */
    public static native IndexSet indexSet();
    /** Returns a set of indexes with a range. */
    public static native IndexSet indexSetWithRange(Range range);
    /** Returns a set of indexes with a single value. */
    public static native IndexSet indexSetWithIndex(long idx);
    
    /** Returns the number of indexes. */
    public native int count();
    /** Adds an index. */
    public native void addIndex(long idx);
    /** Removes an index. */
    public native void removeIndex(long idx);
    /** Returns whether the set of indexes holds the given value. */
    public native boolean containsIndex(long idx);
    
    /** Adds a range of values. */
    public native void addRange(Range range);
    /** Remove a range of values. */
    public native void removeRange(Range range);
    /** Intersects with the given range. The set is modified to contains only indexes that
        are part of the given range. */
    public native void intersectsRange(Range range);
    
    /** Adds indexes of the given set of indexes. */
    public native void addIndexSet(IndexSet indexSet);
    /** Removes indexes of the given set. */
    public native void removeIndexSet(IndexSet indexSet);
    /** Intersects with the given set of indexes. */
    public native void intersectsIndexSet(IndexSet indexSet);
    
    /** Returns all the ranges that the set contains. */
    public native List<Range> allRanges();
    /** Returns the number of ranges that the set contains. */
    public native int rangesCount();
    /** Empties the set. */
    public native void removeAllIndexes();
    
    private native void setupNative();

    private static final long serialVersionUID = 1L;
}
