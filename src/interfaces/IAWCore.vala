/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

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
        public signal void beat (bool is_measure, uint measure, uint8 beats_per_bar,
            uint8 bar_length);

        /**
         * When the beat goes back to zero.
         */
        public signal void beat_reset ();

        /**
         */
        public signal void chord_changed (Chord chord);

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
         * Load all data like voices, styles and plugins.
         */
        public abstract void load_data ();

        /**
         * Load all data like voices, styles and plugins.
         */
        public abstract async void load_data_async () throws ThreadError;

        /**
         * Returns an array of styles loaded by the arranger workstation.
         */
        public abstract unowned Style[] get_styles ();

        /**
         * Returns an array of voices loaded by the arranger workstation.
         */
        public abstract unowned Voice[] get_voices ();

        /**
         * Enables or disables chord interpretation for synthesizer and style engine.
         */
        public abstract void set_chords_on (bool on);

        /**
         * Sets how chord should be interpreted.
         */
        public abstract void set_chord_detection_mode (Analysers.ChordAnalyser.ChordDetectionMode mode);

        // MIDI HOST ///////////////////////////////////////////////////////////

        /* Signals ************************************************************/
        public signal bool configure_midi_device (uint32 route_sig, uint8 type, uint8 channel, uint8 cc);
        /**
         * Control the shell using connected MIDI device.
         */
        public signal void midi_device_on_ui_control (uint16 control_route, Models.MIDIEvent event);

        /* Methods ************************************************************/
        /**
         * Resets midi host and fetches a list of detected devices.
         */
        public abstract unowned MIDIDevice[] refresh_midi_devices ();

        /**
         * Connect to the specified MIDI device to receive MIDI signals from it.
         */
        public abstract void connect_midi_device (MIDIDevice device);

        /**
         * Disconnect MIDI device to stop getting MIDI signals from it.
         */
        public abstract void disconnect_midi_device (MIDIDevice device);

        /**
         * Map device channel to a synthesizer channel (Usually 17, 18 and 19
         * for layers R1, R2 and L respectively).
         */
        public abstract void map_device_channel (uint8 device_channel, uint8 destination_channel);

        /**
         * Map a cc signature to a UI control.
         */
        public abstract void map_cc_from_midi_device (uint32 route_sig, uint16 control_route);


        // SYNTHESIZER /////////////////////////////////////////////////////////

        /* Signals ************************************************************/
        public signal bool on_midi_receive (MIDIEvent event);
        public signal void on_synth_render (float* buffer_l, float* buffer_r, int len);

        /* Methods ************************************************************/
        public abstract bool send_midi (MIDIEvent event);
        public abstract void set_voice (VoiceHandPosition hand_position, uint8 bank, uint8 preset);
        public abstract void set_split_point (uint8 split_point);
        public abstract uint8 get_velocity (uint8 channel);

        // STYLE ENGINE ////////////////////////////////////////////////////////

        /* Signals ************************************************************/
        public signal void on_current_part_change (StylePartType part_type);
        public signal void on_next_part_change (StylePartType part_type);
        public signal void on_sync_change (bool active);
        public signal void on_break_change (bool active);
        public signal void on_tempo_change (uint8 tempo);


        /* Methods ************************************************************/
        /**
         * Adds a style to the queue to be played by a style engine. This will
         * replace any style that has already been added to the queue.
         *
         * @param style A Style descriptor
         */
        public abstract void style_engine_queue_style (Style style, bool autofill = false);
        public abstract void style_engine_queue_part (StylePartType part);
        public abstract void style_engine_toggle_playback ();
        public abstract void style_engine_sync ();
        public abstract void style_engine_break ();
        public abstract bool style_engine_is_playing ();
        public abstract void style_engine_set_auto_fill (bool autofill);
        public abstract uint8 style_engine_get_tempo ();
        public abstract void style_engine_set_tempo (uint8 tempo);



        // PLUGINS /////////////////////////////////////////////////////////////
        /* Signals ************************************************************/

        /* Methods ************************************************************/
        public abstract unowned List<AudioPlugins.AudioPlugin> get_audio_plugins ();

        public abstract unowned Racks.DSPRack get_main_dsp_rack ();

        public abstract unowned Racks.VoiceRack get_voice_rack (
            VoiceHandPosition position
        );
    }
}
