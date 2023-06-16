namespace Ensembles.ArrangerWorkstation.AudioEngine {
    public interface ISynthEngine : Object {
        // MIDI Output
        public signal int on_midi_event (Fluid.MIDIEvent event);
        public signal int on_midi_event_from_player (Fluid.MIDIEvent event);

        // MIDI Input
        public abstract int send_midi_event_for_player (Fluid.MIDIEvent event);
        public abstract int send_midi_event (Fluid.MIDIEvent event);

        // Controls
        public abstract void set_voice (VoiceHandPosition hand_position, uint8 bank, uint8 preset);
        public abstract void halt_notes (bool except_drums);
        public abstract void stop_all_sounds ();

        // Misccellaneuous
        public abstract void play_intro_sound ();
    }
}
