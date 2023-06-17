/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Ensembles.ArrangerWorkstation.MIDIPlayers;
using Ensembles.ArrangerWorkstation.Plugins;
using Ensembles.ArrangerWorkstation.Racks;
using Ensembles.ArrangerWorkstation.Models;

namespace Ensembles.ArrangerWorkstation {
    /**
     * ## Arranger Workstation
     *
     * This forms the core of the app. This houses all the behind the scenes
     * stuff that make every beat beat and every sound sound.
     */
    public class AWCore : Object, IAWCore {
        private static AWCore _instance;
        public static AWCore instance {
            get {
                if (_instance != null) {
                    _instance = new AWCore ();
                }

                return _instance;
            }
        }

        private AudioEngine.SynthProvider synth_provider;
        private AudioEngine.SynthEngine synth_engine;
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

        private string sf_path;
        private string sf_schema_path;
        private List<string> style_paths;

        construct {
            #if PIPEWIRE_CORE_DRIVER
            Pipewire.init (null, null);
            #endif
            synth_provider = new AudioEngine.SynthProvider ();
            synth_provider.init_driver ("pulseaudio", 0.3);
            synth_provider.get_synth (AudioEngine.SynthType.UTILITY).sfload (sf_path, true);
            Console.log ("Loading Soundfont from %s".printf (sf_path));
            try {
                synth_engine = new AudioEngine.SynthEngine (synth_provider, sf_path);
            } catch (FluidError e) {
                Console.log (e.message, Console.LogLevel.ERROR);
            }

            Console.log ("Initializing Plugin Racks");
            main_dsp_rack = new DSPRack ();
            synth_engine.add_rack (main_dsp_rack);

            voice_l_rack = new VoiceRack ();
            synth_engine.add_rack (voice_l_rack);

            voice_r1_rack = new VoiceRack ();
            synth_engine.add_rack (voice_r1_rack);

            voice_r2_rack = new VoiceRack ();
            synth_engine.add_rack (voice_r2_rack);

            build_events ();
        }

        private AWCore () {

        }

        public AWCore load_soundfont_from_path (string sf2_dir) {
            sf_path = sf2_dir + "/EnsemblesGM.sf2";
            sf_schema_path = sf2_dir + "/EnsemblesGMSchema.csv";

            return this;
        }

        public AWCore load_style_from_path (string enstl_path) {
            if (style_paths == null) {
                style_paths = new List<string> ();
            }

            style_paths.append (enstl_path);

            return this;
        }

        /**
         * Load all data like voices, styles and plugins
         */
        public async void load_data_async () {
            new Thread<void> ("ensembles-data-discovery", load_data);
        }

        public void load_data () {
            Thread.usleep (500000);
            // Load Styles
            Console.log ("Searching for styles…");
            var style_loader = new FileLoaders.StyleFileLoader (this);
            styles = style_loader.get_styles ();
            Console.log (
                "Found %u styles".printf (styles.length),
                Console.LogLevel.SUCCESS
            );

            // Load Voices
            Console.log ("Loading voices…");
            var voice_loader = new Analysers.VoiceAnalyser (
                this,
                synth_provider,
                sf_path,
                sf_schema_path
            );
            Console.log (
                "Voices loaded successfully!",
                Console.LogLevel.SUCCESS
            );
            voices = voice_loader.get_voices ();

            // Load Plugins
            Console.log ("Loading Audio Plugins…");
            plugin_manager = new PluginManager (this);
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

        private void build_events () {
            //  Application.event_bus.style_play_toggle.connect (() => {
            //      if (style_engine != null) {
            //          style_engine.toggle_play ();
            //      }
            //  });

            //  Application.event_bus.style_set_part.connect (
            //      (part) => {
            //          if (style_engine != null) {
            //              style_engine.queue_next_part (part);
            //          }
            //      }
            //  );

            //  Application.event_bus.style_break.connect (() => {
            //      if (style_engine != null) {
            //          style_engine.break_play ();
            //      }
            //  });

            //  Application.event_bus.style_sync.connect (() => {
            //      if (style_engine != null) {
            //          style_engine.sync ();
            //      }
            //  });

            //  Application.event_bus.style_change.connect (
            //      (style) => {
            //      queue_change_style (style);
            //  });
        }

        /**
         * Creates a style engine with given style
         *
         * @param style A Style descriptor
         */
        public void queue_change_style (Models.Style style) {
            Console.log ("Changing style to the " + style.to_string ());
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
                        synth_provider,
                        synth_engine,
                        next_style,
                        current_tempo
                    );
                    stopping_style = false;

                    style_engine.queue_next_part (current_part);

                    if (was_playing) {
                        style_engine.play ();
                    }
                });
            }
        }

        public unowned List<string> get_style_paths () {
            return style_paths;
        }

        /**
         * Returns an array of styles loaded by the arranger workstation.
         */
        public unowned Style[] get_styles () {
            return styles;
        }

        /**
         * Returns an array of voices loaded by the arranger workstation.
         */
        public unowned Voice[] get_voices () {
            return voices;
        }

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