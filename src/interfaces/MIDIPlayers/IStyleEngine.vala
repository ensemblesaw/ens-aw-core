using Ensembles.Models;

namespace Ensembles.ArrangerWorkstation.MIDIPlayers {
    public interface IStyleEngine : Object {
        // Properties //////////////////////////////////////////////////////////
        public abstract bool chords_on { get; set; }
        public abstract bool playing { get; }

        // State signals ///////////////////////////////////////////////////////
        internal signal void on_current_part_change (StylePartType part_type);
        internal signal void on_next_part_change (StylePartType part_type);
        internal signal void on_sync_change (bool active);
        internal signal void on_break_change (bool active);

        // Beats
        internal signal void beat (bool measure, uint8 beats_per_bar, uint8 bar_division);
        internal signal void beat_reset ();

        // Functions ///////////////////////////////////////////////////////////
        /**
         * Starts style playback if not already playing.
         */
        public abstract void play ();

        /**
         * Stops the style playback if already playing.
         */
        public abstract void stop ();

        /**
         * Plays the style if not already playing
         * or stops the style if playing.
         */
        public abstract void toggle_play ();

        /**
         * Change the style variation level or trigger a fill-in.
         *
         * @param part The style part to queue
         */
        public abstract void queue_next_part (StylePartType part);

        /**
         * Inserts a minimum voice section during playback. It could be a short
         * build-up or a drop.
         */
        public abstract void break_play ();

        /**
         * Start the style playback with chord input or stop the style
         * playback on the next measure.
         */
        public abstract void sync ();

        /**
         * Ask the style player to stop and wait.
         *
         * **Note:** This is a blocking call, meaning the function will wait until the
         * style player is done playing the current measure.
         *
         * @param current_tempo Variable to store the current tempo
         */
        public abstract bool stop_and_wait (out uint8 current_tempo);

        /**
         * Change the chord of the style.
         *
         * This will stop all voices that are playing the current chord
         * and restart them selectively with the new chord.
         *
         * @param chord The chord to change to
         */
        public abstract void change_chord (Chord chord);
    }
}
