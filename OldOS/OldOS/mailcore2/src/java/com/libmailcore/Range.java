package com.libmailcore;

/** Range of integer values. */
public class Range {
    /** Location. */
    public long location;
    /** Length of the range. A length of 0 is a range with only one item: the location. */
    public long length;

    /** When using RangeMax as the length of the range, it means that the range is infinite. */
    static public long RangeMax = 1 >> 63 - 1;

    /** Constructor for a range starting at 0 and of length 0. */
    public Range() {}
    /** Constructor */
    public Range(long aLocation, long aLength)
    {
        location = aLocation;
        length = aLength;
    }
    
    /** Subtract otherRange from this range and returns the resulting set of indexes. */
    public native IndexSet removeRange(Range otherRange);
    /** Union of otherRange and this range and returns the resulting set of indexes. */
    public native IndexSet union(Range otherRange);
    /** Returns the range resulting from the intersection. */
    public native Range intersection(Range otherRange);
    /** Returns whether the intersection is non-empty. */
    public native boolean hasIntersection(Range otherRange);
    /** Returns the included left bound of the range. */
    public native long leftBound();
    /** Returns the included right bound of the range. */
    public native long rightBound();
    /** Returns a string representation of range. */
    public native String toString();
    
    /** Create a range using a string representation. */
    public static native Range rangeWithString(String rangeString);

    static {
        MainThreadUtils.singleton();
    }
}