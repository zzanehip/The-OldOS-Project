package com.libmailcore.androidexample;

import android.content.Intent;
import android.os.Bundle;
import android.app.Activity;
import com.libmailcore.IMAPSession;
import com.libmailcore.MailException;
import com.libmailcore.OperationCallback;
import com.libmailcore.IMAPMessage;

/**
 * An activity representing a list of MessagesViews. This activity
 * has different presentations for handset and tablet-size devices. On
 * handsets, the activity presents a list of items, which when touched,
 * lead to a {@link MessageViewDetailActivity} representing
 * item details. On tablets, the activity presents the list of items and
 * item details side-by-side using two vertical panes.
 * <p/>
 * The activity makes heavy use of fragments. The list of items is a
 * {@link MessageViewListFragment} and the item details
 * (if present) is a {@link MessageViewDetailFragment}.
 * <p/>
 * This activity also implements the required
 * {@link MessageViewListFragment.Callbacks} interface
 * to listen for item selections.
 */
public class MessageViewListActivity extends Activity
        implements MessageViewListFragment.Callbacks {

    /**
     * Whether or not the activity is in two-pane mode, i.e. running on a tablet
     * device.
     */
    private boolean mTwoPane;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_messageview_list);

        if (findViewById(R.id.messageview_detail_container) != null) {
            // The detail container view will be present only in the
            // large-screen layouts (res/values-large and
            // res/values-sw600dp). If this view is present, then the
            // activity should be in two-pane mode.
            mTwoPane = true;

            // In two-pane mode, list items should be given the
            // 'activated' state when touched.
            ((MessageViewListFragment) getFragmentManager()
                    .findFragmentById(R.id.messageview_list))
                    .setActivateOnItemClick(true);
        }
    }

    /**
     * Callback method from {@link MessageViewListFragment.Callbacks}
     * indicating that the item with the given ID was selected.
     */
    @Override
    public void onItemSelected(IMAPMessage msg) {
        if (mTwoPane) {
            // In two-pane mode, show the detail view in this activity by
            // adding or replacing the detail fragment using a
            // fragment transaction.
            MessagesSyncManager.singleton().currentMessage = msg;

            //Bundle arguments = new Bundle();
            //arguments.putString(MessageViewDetailFragment.ARG_ITEM_ID, msg);
            MessageViewDetailFragment fragment = new MessageViewDetailFragment();
            //fragment.setArguments(arguments);
            getFragmentManager().beginTransaction()
                    .replace(R.id.messageview_detail_container, fragment)
                    .commit();

        } else {
            // In single-pane mode, simply start the detail activity
            // for the selected item ID.
            MessagesSyncManager.singleton().currentMessage = msg;
            Intent detailIntent = new Intent(this, MessageViewDetailActivity.class);
            //detailIntent.putExtra(MessageViewDetailFragment.ARG_ITEM_ID, id);
            startActivity(detailIntent);
        }
    }
}
