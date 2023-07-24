/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Ensembles.ArrangerWorkstation.Plugins;
using Ensembles.ArrangerWorkstation.Racks;
using Ensembles.Models;

namespace Ensembles.ArrangerWorkstation {
    /**
     * @TODO Should be a proper facade pattern
     */
    /**
     * ## Arranger Workstation Core
     *
     * This forms the core of the app. This houses all the behind the scenes
     * stuff that make every beat beat and every sound sound.
     */
    public interface IAWCore : Object {
        // WORKSTATION /////////////////////////////////////////////////////////
        /* Signals ************************************************************/
        /**
         * Signals when the arranger is done loading data.
         */
        public signal void ready();

        /**
         * Sends verbose status for loading screen.
         */
        public signal void send_loading_status(string status);

        /**
         * Sends a beat signal, from style player, metronome or song player.
         */
        public signal void beat (bool measure, uint8 beats_per_bar,
            uint8 bar_length);

        /**
         * When the beat goes back to zero.
         */
        public signal void beat_reset ();


        /* Methods ************************************************************/
        /**
         * Add directory path where styles are present.
         *
         * Must be called before calling `load_data_async ()`.
         * @param enstl_dir_path path to the directory containing
         * `.enstl` files
         */
        public abstract void add_style_search_path (string? enstl_dir_path);

        /**
         * Get a list of paths from where the styles are searched.
         */
        public abstract unowned List<string> get_style_search_paths ();

        /**
         * Returns an array of styles loaded by the arranger workstation.
         */
        public abstract unowned Style[] get_styles ();

        /**
         * Returns an array of voices loaded by the arranger workstation.
         */
        public abstract unowned Voice[] get_voices ();



        // SYNTHESIZER /////////////////////////////////////////////////////////
        /* Signals ************************************************************/

        /* Methods ************************************************************/


        // STYLE ENGINE ////////////////////////////////////////////////////////
        /* Signals ************************************************************/
        public signal void on_current_part_change (StylePartType part_type);

        public signal void on_next_part_change (StylePartType part_type);

        public signal void on_sync_change (bool active);

        public signal void on_break_change (bool active);


        /* Methods ************************************************************/
        /**
         * Adds a style to the queue to be played by a style engine. This will
         * replace any style that has already been added to the queue.
         *
         * @param style A Style descriptor
         */
        public abstract void add_style_to_queue (Models.Style style);



        // PLUGINS /////////////////////////////////////////////////////////////
        /* Signals ************************************************************/

        /* Methods ************************************************************/
        public abstract unowned List<AudioPlugins.AudioPlugin> get_audio_plugins ();

        public abstract unowned Racks.DSPRack get_main_dsp_rack ();

        public abstract unowned Racks.VoiceRack get_voice_rack (
            VoiceHandPosition position
        );

        // Module Interfaces ///////////////////////////////////////////////////
        public abstract AudioEngine.ISynthEngine get_synth_engine ();
        public abstract MIDIPlayers.IStyleEngine get_style_engine ();
    }
}
