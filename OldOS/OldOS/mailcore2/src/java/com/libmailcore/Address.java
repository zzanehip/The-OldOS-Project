package com.libmailcore;

import java.util.List;

/** RFC 822 address. */
public class Address extends NativeObject {
    /** Creates an address with the given display name and mailbox. */
    public native static Address addressWithDisplayName(String displayName, String mailbox);
    /** Creates an address with only a mailbox. */
    public native static Address addressWithMailbox(String mailbox);
    /**
        Parses a string that contains an address encoded following RFC 822 rules and create a
        corresponding address.
    */
    public native static Address addressWithRFC822String(String rfc822String);
    /**
        Parses a string that contains an address encoded following RFC 822 rules and create a
        corresponding address. It assumes that the address is not MIME-encoded.
    */
    public native static Address addressWithNonEncodedRFC822String(String nonEncodedRFC822String);
    /**
        Parses a string that contains an addresses encoded following RFC 822 rules and create a
        corresponding list of addresses.
    */
    public native static List<Address> addressesWithRFC822String(String rfc822String);
    /**
        Parses a string that contains an addresses encoded following RFC 822 rules and create a
        corresponding list of addresses. It assumes that the addresses are not MIME-encoded.
    */
    public native static List<Address> addressesWithNonEncodedRFC822String(String nonEncodedRFC822String);
    
    /**
        Returns the given list of addresses encoded using RFC 822.
    */
    public native static String RFC822StringForAddresses(List<Address> addresses);
    /**
        Returns the given list of addresses encoded using RFC 822. MIME encoding won't be applied.
    */
    public native static String nonEncodedRFC822StringForAddresses(List<Address> addresses);

    public Address()
    {
        setupNative();
    }
    
    /** Returns the display name. */
    public native String displayName();
    /** Sets the display name. */
    public native void setDisplayName(String displayName);
    
    /** Returns the mailbox. */
    public native String mailbox();
    /** Sets the mailbox. */
    public native void setMailbox(String address);
    
    /** Returns the address encoded using RFC 822. */
    public native String RFC822String();
    /** Returns the address encoded using RFC 822. MIME encoding won't be applied. */
    public native String nonEncodedRFC822String();
    
    private native void setupNative();

    private static final long serialVersionUID = 1L;
}
