package com.libmailcore.androidexample;

import android.os.Bundle;
import android.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.util.Log;


import com.libmailcore.MailException;
import com.libmailcore.OperationCallback;
import com.libmailcore.IMAPMessage;
import com.libmailcore.IMAPMessageRenderingOperation;

/**
 * A fragment representing a single MessageView detail screen.
 * This fragment is either contained in a {@link MessageViewListActivity}
 * in two-pane mode (on tablets) or a {@link MessageViewDetailActivity}
 * on handsets.
 */
public class MessageViewDetailFragment extends Fragment implements OperationCallback {
    /**
     * The fragment argument representing the item ID that this fragment
     * represents.
     */
    public static final String ARG_ITEM_ID = "item_id";

    /**
     * The dummy content this fragment is presenting.
     */
    //private DummyContent.DummyItem mItem;
    private IMAPMessage message;

    /**
     * Mandatory empty constructor for the fragment manager to instantiate the
     * fragment (e.g. upon screen orientation changes).
     */
    public MessageViewDetailFragment() {
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        /*
        if (getArguments().containsKey(ARG_ITEM_ID)) {
            // Load the dummy content specified by the fragment
            // arguments. In a real-world scenario, use a Loader
            // to load content from a content provider.
            mItem = DummyContent.ITEM_MAP.get(getArguments().getString(ARG_ITEM_ID));
        }
        */
        message = MessagesSyncManager.singleton().currentMessage;
    }

    private IMAPMessageRenderingOperation renderingOp;
    private WebView webView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_messageview_detail, container, false);
        webView = (WebView) rootView.findViewById(R.id.messageview_detail);

        if (message != null) {
            Log.d("detail", "message: " + message);
            renderingOp = MessagesSyncManager.singleton().session.htmlRenderingOperation(message, "INBOX");
            renderingOp.start(this);
        }

        return rootView;
    }

    public void succeeded() {
        String html = renderingOp.result();
        webView.loadData(html, "text/html", "utf-8");
    }

    public void failed(MailException exception) {

    }
}
