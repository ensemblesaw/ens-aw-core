/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
/*
 * This file incorporates work covered by the following copyright and
 * permission notices:
 *
 * ---
 *
  Copyright 2008-2016 David Robillard <http://drobilla.net>

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THIS SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * ---
 */

using LV2;
using LV2.URID;
using Lilv;

namespace Ensembles.ArrangerWorkstation.Plugins.AudioPlugins.Lv2 {
    public class LV2URIDs : Object {
        public Urid atom_float;
        public Urid atom_int;
        public Urid atom_object;
        public Urid atom_path;
        public Urid atom_string;
        public Urid atom_event_transfer;
        public Urid bufsz_max_block_length;
        public Urid bufsz_min_block_length;
        public Urid bufsz_sequence_size;
        public Urid log_error;
        public Urid log_trace;
        public Urid log_warning;
        public Urid midi_midi_event;
        public Urid param_sample_rate;
        public Urid patch_get;
        public Urid patch_put;
        public Urid patch_set;
        public Urid patch_body;
        public Urid patch_property;
        public Urid patch_value;
        public Urid time_position;
        public Urid time_bar;
        public Urid time_bar_beat;
        public Urid time_beat_unit;
        public Urid time_beats_per_bar;
        public Urid time_beats_per_minute;
        public Urid time_frame;
        public Urid time_speed;
        public Urid ui_scale_factor;
        public Urid ui_update_rate;

        construct {
            atom_float = map_uri (Atom._Float);
            atom_int = map_uri (Atom._Int);
            atom_object = map_uri (Atom._Object);
            atom_path = map_uri (Atom._Path);
            atom_event_transfer = map_uri (Atom._eventTransfer);
            bufsz_max_block_length = map_uri (BufSize._maxBlockLength);
            bufsz_min_block_length = map_uri (BufSize._minBlockLength);
            bufsz_sequence_size = map_uri (BufSize._sequenceSize);
            log_error = map_uri (LV2.Log._Error);
            log_trace = map_uri (LV2.Log._Trace);
            log_warning = map_uri (LV2.Log._Warning);
            midi_midi_event = map_uri (LV2.MIDI._MidiEvent);
            param_sample_rate = map_uri (Parameters._sampleRate);
            patch_get = map_uri (Patch._Get);
            patch_put = map_uri (Patch._Put);
            patch_set = map_uri (Patch._Set);
            patch_body = map_uri (Patch._body);
            patch_property = map_uri (Patch._property);
            patch_value = map_uri (Patch._value);
            time_position = map_uri (LV2.Time._Position);
            time_bar = map_uri (LV2.Time._bar);
            time_bar_beat = map_uri (LV2.Time._barBeat);
            time_beat_unit = map_uri (LV2.Time._beatUnit);
            time_beats_per_bar = map_uri (LV2.Time._beatsPerBar);
            time_beats_per_minute = map_uri (LV2.Time._beatsPerMinute);
            time_frame = map_uri (LV2.Time._frame);
            time_speed = map_uri (LV2.Time._speed);
            ui_scale_factor = map_uri (LV2.UI._scaleFactor);
            ui_update_rate = map_uri (LV2.UI._updateRate);
        }

        private uint32 map_uri (string uri) {
            return LV2Manager.symap.map (uri);
        }
    }
}
