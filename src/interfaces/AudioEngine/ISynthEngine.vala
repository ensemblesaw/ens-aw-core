namespace Ensembles.ArrangerWorkstation.AudioEngine {
    /**
     * ## Synthesizer Engine
     *
     * The FluidSynth SoundFont™ Synthesizer forms the base audio engine for the
     * app.
     *
     * All midi events either from the midi players or from the plugins will be
     * to and from here.
     *
     * All sound from the plugins and samplers are also channel through this
     * synthesizer.
     *
     * ----------------------------------------------
     *  ### RENDER SYNTH CHANNEL UTILIZATION SCHEMATICS
     *
     *  #### STYLE, SONG:
     *  - 0 - 15
     *
     *  #### METRONOME:
     *  - 16
     *
     *  #### MIDI INPUT:
     *  - Voice R1      ~ 17
     *  - Voice R2      ~ 18
     *  - Voice L       ~ 19
     *  - CHORD-EP      ~ 20
     *  - CHORD-Strings ~ 21
     *  - CHORD-Bass    ~ 22
     *
     *  #### CHIMES:
     *  - 23
     *
     *  #### RECORDER:
     *  - Voice R2    ~ 24
     *  - Voice L     ~ 25
     *  - All tracks  ~ 26 - 63
     */
    public interface ISynthEngine : Object {
        /**
         * Audio driver to use for synth engine.
         */
        public enum Driver {
            ALSA,
            PULSEAUDIO,
            JACK,
            PIPEWIRE_PULSE,
            PIPEWIRE
        }

        /**
         * Synth used for rendering audio.
         */
        public abstract Fluid.Synth rendering_synth { get; owned construct; }
        /**
         * Synth used for midi playback and auditing.
         */
        public abstract Fluid.Synth utility_synth { get; owned construct; }
        /**
         */
        public abstract double buffer_length_multiplier { get; set construct; }
        /**
         * Whether the rendering synthesizer receiving MIDI events.
         */
        public abstract bool input_enabled { get; set; }
        /**
         * Whether the Voice R2 is active (and layered with Voice R1).
         */
        public abstract bool layer { get; set; }
        /**
         * Whether the Voice L is active.
         */
        public abstract bool split { get; set; }
        public abstract uint8 split_point { get; set; }
        public abstract bool chords_on { get; set; }


        // Signals /////////////////////////////////////////////////////////////
        // MIDI Output
        public signal int on_midi_receive (Models.MIDIEvent event);
        internal signal int on_f_midi_receive (Fluid.MIDIEvent event);

        // Functions ///////////////////////////////////////////////////////////
        /**
         * Adds an audio plugin rack to the synthesizer.
         * @param rack the rack to add
         */
        public abstract SynthEngine add_rack (Racks.Rack rack);

        // MIDI Input
        public abstract int send_midi (Models.MIDIEvent event);
        internal abstract int send_f_midi (Fluid.MIDIEvent event);
        internal abstract void send_chord_ambiance (Models.MIDIEvent event);
        internal abstract void send_chord_bass (Models.MIDIEvent event, Models.Chord chord);

        // Controls
        public abstract void set_voice (VoiceHandPosition hand_position, uint8 bank, uint8 preset);
        public abstract void halt_notes (bool except_drums = true);
        public abstract void stop_all_sounds ();

        // Settings
        public abstract void edit_master_reverb (int level);
        public abstract void set_master_reverb_active (bool active);
        public abstract void edit_master_chorus (int level);
        public abstract void set_master_chorus_active (bool active);

        // Misccellaneuous
        public abstract void play_intro_sound ();
        public abstract uint8 get_velocity(uint8 channel);
    }
}
