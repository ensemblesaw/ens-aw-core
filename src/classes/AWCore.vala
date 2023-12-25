/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Ensembles.ArrangerWorkstation.AudioEngine;
using Ensembles.ArrangerWorkstation.Drivers;
using Ensembles.ArrangerWorkstation.MIDIPlayers;
using Ensembles.ArrangerWorkstation.Plugins;
using Ensembles.ArrangerWorkstation.Racks;
using Ensembles.Models;

namespace Ensembles.ArrangerWorkstation {
    /**
     * ## Arranger Workstation Core
     *
     * This forms the core of the app. This houses all the behind the scenes
     * stuff that make every beat beat and every sound sound.
     */
    public class AWCore : Object, IAWCore {
        public ISynthEngine.Driver driver { get; construct; }
        public string sf2_dir { get; construct; }
        public string sf2_name { get; construct; }

        private ISynthEngine synth_engine;
        private MIDIHost midi_host;
        private Analysers.ChordAnalyser chord_analyser;
        private StyleEngine style_engine;
        private PluginManager plugin_manager;
        private DSPRack main_dsp_rack;
        private VoiceRack voice_l_rack;
        private VoiceRack voice_r1_rack;
        private VoiceRack voice_r2_rack;

         // Arranger Data
        private Style[] styles;
        private Style next_style;
        private bool next_style_autofill;
        private bool stopping_style;

        private Voice[] voices;

        private string sf_path = "";
        private string sf_schema_path;
        private List<string> style_search_paths;

        construct {
            assert (sf2_dir != null);
            assert (sf2_name != null);

            #if PIPEWIRE_CORE_DRIVER
            Pipewire.init (null, null);
            #endif

            sf_path = sf2_dir + "/" + sf2_name + ".sf2";
            sf_schema_path = sf2_dir + "/" + sf2_name + "Schema.csv";

            try {
                main_dsp_rack = new DSPRack ();
                voice_l_rack = new VoiceRack ();
                voice_r1_rack = new VoiceRack ();
                voice_r2_rack = new VoiceRack ();

                synth_engine = new AudioEngine.SynthEngine (
                    driver,
                    sf_path,
                    0.3
                )
                .add_rack (voice_l_rack)
                .add_rack (voice_r1_rack)
                .add_rack (voice_r2_rack)
                .add_rack (main_dsp_rack);

                chord_analyser = new Analysers.ChordAnalyser ();

                synth_engine.on_midi_receive.connect ((event) => {
                    if (
                        (
                            event.event_type == MIDIEvent.EventType.NOTE_ON ||
                            event.event_type == MIDIEvent.EventType.NOTE_OFF
                        ) &&
                        event.channel == 17
                    ) {
                        if (event.key < synth_engine.split_point) {
                            var chord = chord_analyser.infer (
                                event.key,
                                event.event_type == MIDIEvent.EventType.NOTE_ON
                            );

                            if (event.event_type == MIDIEvent.EventType.NOTE_ON) {
                                chord_changed (chord);
                                if (style_engine != null) {
                                    style_engine.change_chord (chord);

                                    if (!style_engine.playing) {
                                        synth_engine.send_chord_ambiance (event);
                                        synth_engine.send_chord_bass (event, chord);
                                    }
                                }
                            } else {
                                synth_engine.send_chord_ambiance (event);
                                synth_engine.send_chord_bass (event, chord);
                            }
                        }
                    }

                    return on_midi_receive (event) ? Fluid.OK : Fluid.FAILED;
                });

                synth_engine.split_point = 60;
                synth_engine.chords_on = true;

                midi_host = new MIDIHost (synth_engine, true);
                midi_host.on_receive.connect (event => {
                    print(event.key.to_string () + "\n");
                    synth_engine.send_midi (event);
                });

            } catch (FluidError e) {
                Console.log (e.message, Console.LogLevel.ERROR);
            }
        }

        private AWCore () { }

        public AWCore.from_options (string sf2_dir, string? sf2_name = "Ensembles") {
            Object (
                sf2_dir: sf2_dir,
                sf2_name: sf2_name
            );
        }





        /***********************************************************************
         *                        INTERNAL FUNCTIONS                           *
         ***********************************************************************/


        /**
         * Add instrument plugins to voice racks.
         */
        private void add_plugins_to_voice_racks () {
            unowned List<AudioPlugins.AudioPlugin> plugins =
            plugin_manager.audio_plugins;
            for (uint32 i = 0; i < plugins.length (); i++) {
                if (plugins.nth_data (i).category ==
                AudioPlugins.AudioPlugin.Category.VOICE) {
                    try {
                        voice_l_rack.append (plugins.nth_data (i).duplicate ());
                        voice_r1_rack.append (plugins.nth_data (i).duplicate ());
                        voice_r2_rack.append (plugins.nth_data (i).duplicate ());
                    } catch (PluginError e) {

                    }
                }
            }

            voice_l_rack.active = true;
            voice_r1_rack.active = true;
            voice_r2_rack.active = true;
        }





        /***********************************************************************
         *                        EXTERNAL FUNCTIONS                           *
         ***********************************************************************/


        // WORKSTATION /////////////////////////////////////////////////////////

        /**
         * Add directory path where styles are present.
         *
         * Must be called before calling `load_data_async ()`.
         * @param enstl_dir_path path to the directory containing
         * `.enstl` files
         */
        public void add_style_search_path (string? enstl_dir_path) {
            if (style_search_paths == null) {
                style_search_paths = new List<string> ();
            }

            this.style_search_paths.append (enstl_dir_path + "");
        }

        public unowned List<string> get_style_search_paths () {
            return style_search_paths;
        }

        public async void load_data_async () throws ThreadError {
            SourceFunc callback = load_data_async.callback;
            ThreadFunc<void> run = () => {
                load_data ();
                Idle.add((owned) callback);
            };
            new Thread<void> ("ensembles-data-discovery", (owned) run);

            yield;
        }

        public void load_data () {
            Thread.usleep (500000);
            // Load Styles
            if (style_search_paths.length () > 0) {
                Console.log ("Searching for styles…");
                var style_loader = new FileLoaders.StyleFileLoader (this);
                styles = style_loader.get_styles ();
                Console.log (
                    "Found %u styles".printf (styles.length),
                    Console.LogLevel.SUCCESS
                );
            } else {
                Console.log ("No style search path specified. Skipping…", Console.LogLevel.WARNING);
            }

            // Load Voices
            var voice_loader = new Analysers.VoiceAnalyser (
                this,
                synth_engine.utility_synth,
                sf_path,
                sf_schema_path
            );
            Console.log ("Loading voices…");
            voice_loader.analyse_all ();
            Console.log (
                "Voices loaded successfully!",
                Console.LogLevel.SUCCESS
            );
            voices = voice_loader.get_voices ();

            // Load Plugins
            Console.log ("Loading Audio Plugins…");
            plugin_manager = new PluginManager (this);
            plugin_manager.load_all ();
            Console.log (
                "%u Audio Plugins Loaded Successfully!"
                .printf (plugin_manager.audio_plugins.length ()),
                Console.LogLevel.SUCCESS
            );

            add_plugins_to_voice_racks ();

            send_loading_status ("");

            // Send ready signal
            Idle.add (() => {
                ready ();
                Timeout.add (1000, () => {
                    synth_engine.play_intro_sound ();
                    return false;
                });
                return false;
            });
        }

        public unowned Style[] get_styles () {
            return styles;
        }

        public unowned Voice[] get_voices () {
            return voices;
        }

        public void set_chords_on (bool on) {
            synth_engine.chords_on = on;
            if (style_engine != null) {
                style_engine.chords_on = on;
            }
        }

        public void set_chord_detection_mode (Analysers.ChordAnalyser.ChordDetectionMode mode) {

        }

        public void set_split_point (uint8 split_point) {
            synth_engine.split_point = split_point;
        }

        // MIDI DEVICES ////////////////////////////////////////////////////////
        public unowned MIDIDevice[] refresh_midi_devices () {
            return midi_host.refresh ();
        }

        public void connect_midi_device (MIDIDevice device) {
            midi_host.connect_dev (device);
        }

        public void disconnect_midi_device (MIDIDevice device) {
            midi_host.disconnect_dev (device);
        }

        public void map_device_channel (uint8 device_channel, uint8 destination_channel) {
            midi_host.map_channel (device_channel, destination_channel);
        }


        // SYNTHESIZER /////////////////////////////////////////////////////////
        public bool send_midi (MIDIEvent event) {
            return synth_engine.send_midi (event) == Fluid.OK;
        }

        public void set_voice (Ensembles.VoiceHandPosition hand_position, uint8 bank, uint8 preset) {
            synth_engine.set_voice (hand_position, bank, preset);
        }

        public uint8 get_velocity (uint8 channel) {
            return synth_engine.get_velocity (channel);
        }


        // STYLE ENGINE ////////////////////////////////////////////////////////
        public void style_engine_queue_style (Models.Style style, bool autofill = false) {
            Console.log ("Changing style to ");
            Console.log (style);
            next_style = style;
            next_style_autofill = autofill;
            if (!stopping_style) {
                stopping_style = true;
                new Thread<void> ("queue-load-style", () => {
                    uint8 current_tempo = 0;
                    bool was_playing = false;
                    StylePartType current_part = StylePartType.VARIATION_A;
                    if (style_engine != null) {
                        current_part = style_engine.current_part;
                        was_playing = style_engine.stop_and_wait (out current_tempo);
                    }

                    style_engine = new StyleEngine (
                        synth_engine,
                        next_style,
                        current_tempo
                    );
                    style_engine.autofill = next_style_autofill;
                    style_engine.chords_on = true;
                    style_engine.beat.connect_after ((measure, beats_per_bar, bar_length) => {
                        beat (measure, beats_per_bar, bar_length);
                    });
                    style_engine.beat_reset.connect_after (() => {
                        beat_reset ();
                    });
                    style_engine.on_current_part_change.connect_after ((part_type) => {
                        on_current_part_change (part_type);
                    });
                    style_engine.on_next_part_change.connect_after ((part_type) => {
                        on_next_part_change (part_type);
                    });
                    style_engine.on_sync_change.connect_after ((active) => {
                        on_sync_change (active);
                    });
                    style_engine.on_break_change.connect_after ((active) => {
                        on_break_change (active);
                    });
                    stopping_style = false;
                    on_tempo_change (style_engine.tempo);

                    style_engine.queue_next_part (current_part);

                    if (was_playing) {
                        style_engine.play ();
                    }
                });
            }
        }

        public void style_engine_queue_part (Ensembles.Models.StylePartType part) {
            if (style_engine != null) {
                style_engine.queue_next_part (part);
            }
        }

        public void style_engine_toggle_playback () {
            if (style_engine != null) {
                style_engine.toggle_play ();
            }
        }

        public void style_engine_sync () {
            if (style_engine != null) {
                style_engine.sync ();
            }
        }

        public void style_engine_break () {
            if (style_engine != null) {
                style_engine.break_play ();
            }
        }

        public bool style_engine_is_playing () {
            if(style_engine != null) {
                return style_engine.playing;
            }

            return false;
        }

        public void style_engine_set_auto_fill (bool autofill) {
            if (style_engine != null) {
                style_engine.autofill = autofill;
            }
        }

        public uint8 style_engine_get_tempo () {
            if (style_engine != null) {
                return style_engine.tempo;
            }

            return 120;
        }

        public void style_engine_set_tempo (uint8 tempo) {
            if (style_engine != null) {
                style_engine.tempo = tempo;
                on_tempo_change (tempo);
            }
        }


        // PLUGINS /////////////////////////////////////////////////////////////
        public unowned List<AudioPlugins.AudioPlugin> get_audio_plugins () {
            return plugin_manager.audio_plugins;
        }

        public unowned Racks.DSPRack get_main_dsp_rack () {
            return main_dsp_rack;
        }

        public unowned Racks.VoiceRack get_voice_rack (
            VoiceHandPosition position
        ) {
            switch (position) {
                case VoiceHandPosition.LEFT:
                return voice_l_rack;
                case VoiceHandPosition.RIGHT_LAYERED:
                return voice_r2_rack;
                default:
                return voice_r1_rack;
            }
        }
    }
}
