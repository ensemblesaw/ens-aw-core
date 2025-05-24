/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Ensembles.Models;

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
     * ------------------------------------------
     *  ### RENDER SYNTH CHANNEL ROUTE SCHEMATICS
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
    public class SynthEngine : Object, ISynthEngine {
        // Public Instance Fields //////////////////////////////////////////////
        public Driver driver { get; construct; }
        /** Synth used for rendering audio. */
        public Fluid.Synth rendering_synth { get; owned construct; }
        /** Synth used for midi playback and auditing. */
        public Fluid.Synth utility_synth { get; owned construct; }

        private double _buffer_length_multipler;
        public double buffer_length_multiplier {
            get {
                return _buffer_length_multipler;
            }
            set construct {
                _buffer_length_multipler = value;
                if (settings != null) {
                    settings.configure_driver (
                        driver,
                        value
                    );
                }
            }
        }

        private bool _input_enabled = true;
        public bool input_enabled {
            get {
                return _input_enabled;
            }
            set {
                _input_enabled = value;
            }
        }

        public List<unowned Racks.Rack> racks { get; private owned set construct; }
        public string soundfont_path { get; construct; }

        public bool layer { get; set; }
        public bool split { get; set; }
        public uint8 split_point { get; set; }
        public bool chords_on { get; set; }
        public bool fullrange_chords { get; set; }

        // Public Static Fields ////////////////////////////////////////////////
        public static int64 processing_start_time { get; private set; }
        public static uint32 buffer_size { get; private set; }
        public static double sample_rate { get; private set; }
        public uint8[] velocity_buffer { get; private set; }

        // Private Fields
        private SynthModPresets.StyleChannelGain style_channel_gain;
        private SynthModPresets.Modulators modulators;

        private int soundfont_id;

        private SynthSettings settings;

        private Fluid.AudioDriver rendering_driver;
        private Fluid.AudioDriver utility_driver;

        private static float* wet_buffer_l;
        private static float* wet_buffer_r;

        public SynthEngine (Driver driver, string soundfont_path, double buffer_length_multiplier) throws FluidError {
            Console.log ("Initializing Synthesizer…");
            if (!Fluid.is_soundfont (soundfont_path)) {
                throw new FluidError.INVALID_SF (
                    "SoundFont from path: %s is either missing or invalid", soundfont_path
                );
            }

            Object (
                driver: driver,
                soundfont_path: soundfont_path,
                buffer_length_multiplier: buffer_length_multiplier
            );

            initialize_voices ();
            set_synth_defaults ();

            modulators = new SynthModPresets.Modulators ();
            style_channel_gain = new SynthModPresets.StyleChannelGain ();
            velocity_buffer = new uint8[20];
        }

        construct {
            settings = new SynthSettings ();

            settings.configure_driver (
                driver,
                buffer_length_multiplier
            );

            rendering_synth = build_rendering_synth ();
            utility_synth = build_utility_synth ();

            soundfont_id = rendering_synth.sfload (soundfont_path, true);
            utility_synth.sfload (soundfont_path, true);
            racks = new List<unowned Racks.Rack> ();

        }

        ~SynthEngine () {
            Fluid.free (wet_buffer_l);
            Fluid.free (wet_buffer_r);
        }

        private Fluid.Synth build_rendering_synth () {
            var _rendering_synth = new Fluid.Synth (settings.rendering_settings);

            buffer_size = _rendering_synth.get_internal_bufsize ();
            double _sample_rate = 1;
            settings.rendering_settings.getnum ("synth.sample-rate", out _sample_rate);
            sample_rate = _sample_rate;
            Console.log ("Sample Rate: %0.1lf Hz".printf (_sample_rate));

            rendering_driver = new Fluid.AudioDriver.with_audio_callback (
                settings.rendering_settings,
                (synth_engine, len, fx, aout) => {
                // Log current unix time before the synthesizer processes audio
                SynthEngine.processing_start_time = new DateTime.now_utc ().to_unix ();

                if (fx == null) {
                    /* Note that some audio drivers may not provide buffers for effects like
                     * reverb and chorus. In this case it's your decision what to do. If you
                     * had called process() like in the else branch below, no
                     * effects would have been rendered. Instead, you may mix the effects
                     * directly into the out buffers. */
                    if (((SynthEngine)synth_engine).rendering_synth
                        .process (len, aout, aout) != Fluid.OK) {
                        return Fluid.FAILED;
                    }
                } else {
                    // Call the synthesizer to fill the output buffers with its
                    // audio output.
                    if (((SynthEngine)synth_engine).rendering_synth
                        .process (len, fx, aout) != Fluid.OK) {
                        return Fluid.FAILED;
                    }
                }

                // All processing is stereo // Repeat processing if the plugin is mono
                float* dry_buffer_l = aout[0];
                float* dry_buffer_r = aout[1];

                // Apply effects here
                if (wet_buffer_l == null || wet_buffer_r == null) {
                    wet_buffer_l = malloc (len * sizeof (float));
                    wet_buffer_r = malloc (len * sizeof (float));
                }

                for (int k = 0; k < len; k++) {
                    wet_buffer_l[k] = dry_buffer_l[k];
                    wet_buffer_r[k] = dry_buffer_r[k];
                }

                // The audio buffer data is sent to the plugin system
                ((SynthEngine)synth_engine).process_audio (len,
                    dry_buffer_l,
                    dry_buffer_r,
                    &wet_buffer_l,
                    &wet_buffer_r
                );

                for (int k = 0; k < len; k++) {
                    dry_buffer_l[k] = wet_buffer_l[k];
                    dry_buffer_r[k] = wet_buffer_r[k];
                }

                ((SynthEngine) synth_engine).on_render (wet_buffer_l, wet_buffer_r, len);

                return Fluid.OK;
            }, this);

            return _rendering_synth;
        }

        private Fluid.Synth build_utility_synth () {
            var _utility_synth = new Fluid.Synth (settings.utility_settings);
            utility_driver = new Fluid.AudioDriver (settings.utility_settings, _utility_synth);
            return _utility_synth;
        }

        private void initialize_voices () {
            rendering_synth.program_select (17, soundfont_id, 0, 0);
            rendering_synth.program_select (18, soundfont_id, 0, 49);
            rendering_synth.program_select (19, soundfont_id, 0, 33);

            // Initialize chord voices
            rendering_synth.program_select (20, soundfont_id, 0, 5);
            rendering_synth.program_select (21, soundfont_id, 0, 33);
            rendering_synth.program_select (22, soundfont_id, 0, 49);

            // Initialize metronome voice
            rendering_synth.program_select (16, soundfont_id, 128, 0);

            // Initialize intro chime voice
            rendering_synth.program_select (23, soundfont_id, 0, 96);
        }

        protected SynthEngine add_rack (Racks.Rack rack) {
            racks.append (rack);
            return this;
        }

        protected void set_voice (VoiceHandPosition hand_position, uint8 bank, uint8 preset) {
            uint8 channel = 17;
            switch (hand_position) {
                case VoiceHandPosition.LEFT:
                    channel = 19;
                    break;
                case VoiceHandPosition.RIGHT_LAYERED:
                    channel = 18;
                    break;
                default:
                    break;
            }

            rendering_synth.program_select (channel, soundfont_id, bank, preset);
        }

        private void set_synth_defaults () {
            // CutOff for Realtime synth
            rendering_synth.cc (17, MIDIEvent.Control.BRIGHTNESS, 88);
            rendering_synth.cc (18, MIDIEvent.Control.BRIGHTNESS, 108);
            rendering_synth.cc (19, MIDIEvent.Control.BRIGHTNESS, 120);

            // Reverb and Chorus for R1 voice
            rendering_synth.cc (17, MIDIEvent.Control.REVERB, 110);
            rendering_synth.cc (17, MIDIEvent.Control.CHORUS, 10);

            // Reverb and Chorus for intro tone
            rendering_synth.cc (23, MIDIEvent.Control.REVERB, 127);
            rendering_synth.cc (23, MIDIEvent.Control.CHORUS, 100);
            rendering_synth.cc (23, MIDIEvent.Control.BRIGHTNESS, 88);
            rendering_synth.cc (23, MIDIEvent.Control.RESONANCE, 80);

            // Reverb and Chorus for Metronome
            rendering_synth.cc (16, MIDIEvent.Control.REVERB, 0);
            rendering_synth.cc (16, MIDIEvent.Control.CHORUS, 0);

            // Default gain for Realtime synth
            rendering_synth.cc (17, MIDIEvent.Control.GAIN, 100);
            rendering_synth.cc (18, MIDIEvent.Control.GAIN, 90);
            rendering_synth.cc (19, MIDIEvent.Control.GAIN, 80);


            // Default pitch of all synths
            for (int i = 17; i < 64; i++) {
                rendering_synth.cc (i, MIDIEvent.Control.EXPLICIT_PITCH, 64);
            }

            // Default cut-off and resonance for recorder
            for (int i = 24; i < 64; i++) {
                rendering_synth.cc (i, MIDIEvent.Control.BRIGHTNESS, 40);
                rendering_synth.cc (i, MIDIEvent.Control.RESONANCE, 10);
            }

            // Default pitch for styles
            for (int i = 0; i < 16; i++) {
                rendering_synth.cc (i, MIDIEvent.Control.EXPLICIT_PITCH, 64);
            }

            set_master_reverb_active (true);
            edit_master_reverb (8);

            set_master_chorus_active (true);
            edit_master_chorus (2);
        }

        protected void play_intro_sound () {
            Timeout.add (200, () => {
                rendering_synth.noteon (23, 65, 110);
                return false;
            });

            Timeout.add (300, () => {
                rendering_synth.noteon (23, 60, 90);
                return false;
            });

            Timeout.add (400, () => {
                rendering_synth.noteon (23, 72, 127);
                return false;
            });

            Timeout.add (500, () => {
                rendering_synth.noteoff (23, 65);
                rendering_synth.noteoff (23, 60);
                rendering_synth.noteoff (23, 72);
                return false;
            });
        }

        private void process_audio (
            int len,
            float* input_l,
            float* input_r,
            float** output_l,
            float** output_r
        ) {
            foreach (var rack in racks) {
                rack.process_audio (
                    len, input_l, input_r, output_l, output_r
                );

                // Copy back to input for next rack
                for (int i = 0; i < len; i++) {
                    input_l[i] = * (* output_l + i);
                    input_r[i] = * (* output_r + i);
                }
            }
        }

        protected void edit_master_reverb (int level) {
            if (rendering_synth != null) {
                rendering_synth.set_reverb_group_roomsize (-1, SynthModPresets.ReverbPresets.ROOM_SIZE[level]);
                rendering_synth.set_reverb_group_damp (-1, 0.1);
                rendering_synth.set_reverb_group_width (-1, SynthModPresets.ReverbPresets.WIDTH[level]);
                rendering_synth.set_reverb_group_level (-1, SynthModPresets.ReverbPresets.LEVEL[level]);
            }
        }

        protected void set_master_reverb_active (bool active) {
            if (rendering_synth != null) {
                rendering_synth.reverb_on (-1, active);
            }
        }

        protected void edit_master_chorus (int level) {
            if (rendering_synth != null) {
                rendering_synth.set_chorus_group_depth (-1, SynthModPresets.ChorusPresets.DEPTH[level]);
                rendering_synth.set_chorus_group_level (-1, SynthModPresets.ChorusPresets.LEVEL[level]);
                rendering_synth.set_chorus_group_nr (-1, SynthModPresets.ChorusPresets.NR[level]);
            }
        }

        protected void set_master_chorus_active (bool active) {
            if (rendering_synth != null) {
                rendering_synth.chorus_on (-1, active);
            }
        }

        protected int send_midi (MIDIEvent event) {
            bool handled = false;

            if (
                (
                    event.event_type == MIDIEvent.EventType.NOTE_ON ||
                    event.event_type == MIDIEvent.EventType.NOTE_OFF
                )
            ) {
                if (fullrange_chords ||!chords_on || (chords_on && event.key >= split_point)) {
                    var fluid_midi_ev = new Fluid.MIDIEvent ();
                    fluid_midi_ev.set_type (event.event_type);
                    fluid_midi_ev.set_channel (event.channel);
                    fluid_midi_ev.set_control (event.control);
                    fluid_midi_ev.set_value (event.value);
                    fluid_midi_ev.set_key (event.key);
                    fluid_midi_ev.set_velocity (event.velocity);

                    foreach (var rack in racks) {
                        var voice_rack = rack as Racks.VoiceRack;
                        if (voice_rack != null) {
                            if (voice_rack.send_midi_event (fluid_midi_ev) == Fluid.OK) {
                                handled = true;
                            }
                        }
                    }

                    on_midi_receive (event);
                    if (handled) {
                        return Fluid.OK;
                    }

                    return rendering_synth.handle_midi_event (fluid_midi_ev);
                } else {
                    on_midi_receive (event);
                }
            } else if (event.event_type == MIDIEvent.EventType.PITCH_BEND) {
                var fluid_midi_ev = new Fluid.MIDIEvent ();
                fluid_midi_ev.set_type (event.event_type);
                fluid_midi_ev.set_channel (event.channel);
                fluid_midi_ev.set_value (event.value);

                foreach (var rack in racks) {
                    var voice_rack = rack as Racks.VoiceRack;
                    if (voice_rack != null) {
                        if (voice_rack.send_midi_event (fluid_midi_ev) == Fluid.OK) {
                            handled = true;
                        }
                    }
                }

                if (handled) {
                    return Fluid.OK;
                }

                fluid_midi_ev.set_type (MIDIEvent.EventType.CONTROL_CHANGE);
                fluid_midi_ev.set_control (MIDIEvent.Control.EXPLICIT_PITCH);

                return rendering_synth.handle_midi_event (fluid_midi_ev);
            }

            return Fluid.OK;
        }

        protected int send_f_midi (Fluid.MIDIEvent event) {
            int type = event.get_type ();
            int chan = event.get_channel ();
            int cont = event.get_control ();
            int value= event.get_value ();

            if (type == MIDIEvent.EventType.CONTROL_CHANGE) {
                if (
                    cont == MIDIEvent.Control.EXPLICIT_BANK_SELECT &&
                    (value == 1 || value == 8 || value == 16 || value == 126)
                ) {
                    int sf_id, program_id, bank_id;
                    rendering_synth.get_program (chan, out sf_id, out bank_id, out program_id);
                    rendering_synth.program_select (chan, soundfont_id, value, program_id);
                }

                if (cont == MIDIEvent.Control.GAIN) {
                    if (style_channel_gain.gain[chan] >= 0) {
                        event.set_value (style_channel_gain.gain[chan]);
                    }
                }

                if (cont == MIDIEvent.Control.PAN) {
                    if (modulators.get_mod_buffer_value (MIDIEvent.Control.PAN, (uint8)chan) >= -64) {
                        event.set_value (modulators.get_mod_buffer_value (10, (uint8)chan));
                    }
                } else {
                    if (modulators.get_mod_buffer_value ((uint8)cont, (uint8)chan) >= 0) {
                        event.set_value (
                            modulators.get_mod_buffer_value ((uint8)cont, (uint8)chan)
                        );
                    }
                }
            }

            if (type == MIDIEvent.EventType.NOTE_ON) {
                velocity_buffer[chan] = (uint8)event.get_velocity ();
            }

            on_f_midi_receive (event);

            return rendering_synth.handle_midi_event (event);
        }

        protected uint8 get_velocity(uint8 channel) {
            var velocity = velocity_buffer[channel];
            if (velocity_buffer[channel] > 1) {
                velocity_buffer[channel] -= 2;
            } else {
                velocity_buffer[channel] = 0;
            }

            return velocity;
        }

        protected void send_chord_ambiance (MIDIEvent event) {
            if (event.event_type == MIDIEvent.EventType.NOTE_ON) {
                rendering_synth.noteon (20, event.key + 12, event.velocity);
                rendering_synth.noteon (22, event.key + 24, event.velocity);
            } else if (event.event_type == MIDIEvent.EventType.NOTE_OFF) {
                rendering_synth.noteoff (20, event.key + 12);
                rendering_synth.noteoff (22, event.key + 24);
            }
        }

        protected void send_chord_bass (MIDIEvent event, Chord chord) {
            if (event.event_type == MIDIEvent.EventType.NOTE_ON) {
                rendering_synth.noteon (21, chord.root + 36, event.velocity);
            } else if (event.event_type == MIDIEvent.EventType.NOTE_OFF) {
                rendering_synth.all_notes_off (21);
            }
        }

        protected void halt_notes (bool except_drums = true) {
            for (uint8 i = 0; i < 16; i++) {
                if (!except_drums || (i != 9 && i != 10)) {
                    rendering_synth.all_notes_off (i);
                }
            }
        }

        protected void stop_all_sounds () {
            for (uint8 i = 0; i < 16; i++) {
                rendering_synth.all_sounds_off (i);
            }
        }
    }
}
