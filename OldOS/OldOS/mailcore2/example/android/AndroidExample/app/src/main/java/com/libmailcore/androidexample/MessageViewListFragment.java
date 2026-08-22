package com.libmailcore.androidexample;

import android.app.Activity;
import android.os.Bundle;
import android.app.ListFragment;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.util.Log;

import java.util.ArrayList;

import com.libmailcore.IMAPFetchMessagesOperation;
import com.libmailcore.IMAPMessage;
import com.libmailcore.MailException;
import com.libmailcore.OperationCallback;
import com.libmailcore.IndexSet;
import com.libmailcore.IMAPMessagesRequestKind;
import com.libmailcore.Range;

/**
 * A list fragment representing a list of MessagesViews. This fragment
 * also supports tablet devices by allowing list items to be given an
 * 'activated' state upon selection. This helps indicate which item is
 * currently being viewed in a {@link MessageViewDetailFragment}.
 * <p/>
 * Activities containing this fragment MUST implement the {@link Callbacks}
 * interface.
 */
public class MessageViewListFragment extends ListFragment implements OperationCallback {

    /**
     * The serialization (saved instance state) Bundle key representing the
     * activated item position. Only used on tablets.
     */
    private static final String STATE_ACTIVATED_POSITION = "activated_position";

    /**
     * The fragment's current callback object, which is notified of list item
     * clicks.
     */
    private Callbacks mCallbacks = sDummyCallbacks;

    /**
     * The current activated item position. Only used on tablets.
     */
    private int mActivatedPosition = ListView.INVALID_POSITION;

    /**
     * A callback interface that all activities containing this fragment must
     * implement. This mechanism allows activities to be notified of item
     * selections.
     */
    public interface Callbacks {
        /**
         * Callback for when an item has been selected.
         */
        public void onItemSelected(IMAPMessage msg);
    }

    /**
     * A dummy implementation of the {@link Callbacks} interface that does
     * nothing. Used only when this fragment is not attached to an activity.
     */
    private static Callbacks sDummyCallbacks = new Callbacks() {
        @Override
        public void onItemSelected(IMAPMessage msg) {
        }
    };

    /**
     * Mandatory empty constructor for the fragment manager to instantiate the
     * fragment (e.g. upon screen orientation changes).
     */
    public MessageViewListFragment() {
    }

    private IMAPFetchMessagesOperation fetchMessagesOp;
    private ArrayAdapter<MessageAdapter> adapter;
    private java.util.List<IMAPMessage> messages;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        fetchMessagesOp = MessagesSyncManager.singleton().session.fetchMessagesByNumberOperation("INBOX", IMAPMessagesRequestKind.IMAPMessagesRequestKindHeaders | IMAPMessagesRequestKind.IMAPMessagesRequestKindStructure, IndexSet.indexSetWithRange(new Range(1, Range.RangeMax)));
        fetchMessagesOp.start(this);
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Restore the previously serialized activated item position.
        if (savedInstanceState != null
                && savedInstanceState.containsKey(STATE_ACTIVATED_POSITION)) {
            setActivatedPosition(savedInstanceState.getInt(STATE_ACTIVATED_POSITION));
        }
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);

        // Activities containing this fragment must implement its callbacks.
        if (!(activity instanceof Callbacks)) {
            throw new IllegalStateException("Activity must implement fragment's callbacks.");
        }

        mCallbacks = (Callbacks) activity;
    }

    @Override
    public void onDetach() {
        super.onDetach();

        // Reset the active callbacks interface to the dummy implementation.
        mCallbacks = sDummyCallbacks;
    }

    @Override
    public void onListItemClick(ListView listView, View view, int position, long id) {
        super.onListItemClick(listView, view, position, id);

        // Notify the active callbacks interface (the activity, if the
        // fragment is attached to one) that an item has been selected.
//        mCallbacks.onItemSelected(DummyContent.ITEMS.get(position).id);
        Log.d("msglist", "row clicked: " + id);
        mCallbacks.onItemSelected(messages.get((int) id));
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        if (mActivatedPosition != ListView.INVALID_POSITION) {
            // Serialize and persist the activated item position.
            outState.putInt(STATE_ACTIVATED_POSITION, mActivatedPosition);
        }
    }

    /**
     * Turns on activate-on-click mode. When this mode is on, list items will be
     * given the 'activated' state when touched.
     */
    public void setActivateOnItemClick(boolean activateOnItemClick) {
        // When setting CHOICE_MODE_SINGLE, ListView will automatically
        // give items the 'activated' state when touched.
        getListView().setChoiceMode(activateOnItemClick
                ? ListView.CHOICE_MODE_SINGLE
                : ListView.CHOICE_MODE_NONE);
    }

    private void setActivatedPosition(int position) {
        if (position == ListView.INVALID_POSITION) {
            getListView().setItemChecked(mActivatedPosition, false);
        } else {
            getListView().setItemChecked(position, true);
        }

        mActivatedPosition = position;
    }

    public void succeeded() {
        messages = fetchMessagesOp.messages();
        updateResult();
    }

    public void failed(MailException exception) {

    }

    private void updateResult() {

        Log.d("msglist", "update result");
        ArrayList<MessageAdapter> array = new ArrayList();
        for(IMAPMessage msg : messages) {
            MessageAdapter msgAdapter = new MessageAdapter(msg);
            array.add(msgAdapter);
        }
        adapter = new ArrayAdapter<MessageAdapter>(
                getActivity(),
                android.R.layout.simple_list_item_activated_1,
                android.R.id.text1,
                array);

        setListAdapter(adapter);

    }
}
