/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Ensembles.ArrangerWorkstation.AudioEngine;
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
        private StyleEngine style_engine;
        private PluginManager plugin_manager;
        private DSPRack main_dsp_rack;
        private VoiceRack voice_l_rack;
        private VoiceRack voice_r1_rack;
        private VoiceRack voice_r2_rack;

         // Arranger Data
        private Style[] styles;
        private Style next_style;
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
                .add_rack (main_dsp_rack)
                .add_rack (voice_l_rack)
                .add_rack (voice_r1_rack)
                .add_rack (voice_r2_rack);
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
        protected void add_style_search_path (string? enstl_dir_path) {
            if (style_search_paths == null) {
                style_search_paths = new List<string> ();
            }

            this.style_search_paths.append (enstl_dir_path + "");
        }

        protected unowned List<string> get_style_search_paths () {
            return style_search_paths;
        }

        protected async void load_data_async () throws ThreadError {
            SourceFunc callback = load_data_async.callback;
            ThreadFunc<void> run = () => {
                load_data ();
                Idle.add((owned) callback);
            };
            new Thread<void> ("ensembles-data-discovery", (owned) run);

            yield;
        }

        protected void load_data () {
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
                return false;
            });
        }

        protected unowned Style[] get_styles () {
            return styles;
        }

        protected unowned Voice[] get_voices () {
            return voices;
        }


        // SYNTHESIZER /////////////////////////////////////////////////////////



        // STYLE ENGINE ////////////////////////////////////////////////////////
        protected void style_engine_queue_style (Models.Style style) {
            Console.log ("Changing style to ");
            Console.log (style);
            next_style = style;
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

                    style_engine.queue_next_part (current_part);

                    if (was_playing) {
                        style_engine.play ();
                    }
                });
            }
        }

        protected void style_engine_queue_part (Ensembles.Models.StylePartType part) {
            if (style_engine != null) {
                style_engine.queue_next_part (part);
            }
        }

        protected void style_engine_toggle_playback () {
            if (style_engine != null) {
                style_engine.toggle_play ();
            }
        }

        protected void style_engine_sync () {
            if (style_engine != null) {
                style_engine.sync ();
            }
        }

        protected void style_engine_break () {
            if (style_engine != null) {
                style_engine.break_play ();
            }
        }


        // PLUGINS /////////////////////////////////////////////////////////////
        protected unowned List<AudioPlugins.AudioPlugin> get_audio_plugins () {
            return plugin_manager.audio_plugins;
        }

        protected unowned Racks.DSPRack get_main_dsp_rack () {
            return main_dsp_rack;
        }

        protected unowned Racks.VoiceRack get_voice_rack (
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
