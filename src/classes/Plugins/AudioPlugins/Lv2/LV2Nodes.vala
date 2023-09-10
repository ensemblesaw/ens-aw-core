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
    public class LV2Nodes : Object {
        public Lilv.Node atom_port;
        public Lilv.Node atom_chunk;
        public Lilv.Node atom_float;
        public Lilv.Node atom_path;
        public Lilv.Node atom_sequence;
        public Lilv.Node lv2_audio_port;
        public Lilv.Node lv2_cvport;
        public Lilv.Node lv2_control_port;
        public Lilv.Node lv2_input_port;
        public Lilv.Node lv2_output_port;
        public Lilv.Node lv2_connection_optional;
        public Lilv.Node lv2_control;
        public Lilv.Node lv2_default;
        public Lilv.Node lv2_enumeration;
        public Lilv.Node lv2_extension_data;
        public Lilv.Node lv2_integer;
        public Lilv.Node lv2_maximum;
        public Lilv.Node lv2_minimum;
        public Lilv.Node lv2_name;
        public Lilv.Node lv2_reports_latency;
        public Lilv.Node lv2_sample_rate;
        public Lilv.Node lv2_symbol;
        public Lilv.Node lv2_toggled;
        public Lilv.Node midi_midi_event;
        public Lilv.Node pg_group;
        public Lilv.Node pprops_logarithmic;
        public Lilv.Node pprops_no_on_gui;
        public Lilv.Node pprops_range_steps;
        public Lilv.Node pset_preset;
        public Lilv.Node pset_bank;
        public Lilv.Node rdfs_comment;
        public Lilv.Node rdfs_label;
        public Lilv.Node rdfs_range;
        public Lilv.Node rsz_minimim_size;
        public Lilv.Node ui_show_interface;
        public Lilv.Node work_interface;
        public Lilv.Node work_schedule;
        public Lilv.Node end;

        public LV2Nodes (World world) {
            atom_port = new Lilv.Node.uri (world, Atom._AtomPort);
            atom_chunk = new Lilv.Node.uri (world, Atom._Chunk);
            atom_float = new Lilv.Node.uri (world, Atom._Float);
            atom_path = new Lilv.Node.uri (world, Atom._Path);
            atom_sequence = new Lilv.Node.uri (world, Atom._Sequence);
            lv2_audio_port = new Lilv.Node.uri (world, Core._AudioPort);
            lv2_cvport = new Lilv.Node.uri (world, Core._CVPort);
            lv2_control_port = new Lilv.Node.uri (world, Core._ControlPort);
            lv2_input_port = new Lilv.Node.uri (world, Core._InputPort);
            lv2_output_port = new Lilv.Node.uri (world, Core._OutputPort);
            lv2_connection_optional = new Lilv.Node.uri (world, Core._connectionOptional);
            lv2_control = new Lilv.Node.uri (world, Core._control);
            lv2_default = new Lilv.Node.uri (world, Core._default);
            lv2_enumeration = new Lilv.Node.uri (world, Core._enumeration);
            lv2_extension_data = new Lilv.Node.uri (world, Core._extensionData);
            lv2_integer = new Lilv.Node.uri (world, Core._integer);
            lv2_maximum = new Lilv.Node.uri (world, Core._maximum);
            lv2_minimum = new Lilv.Node.uri (world, Core._minimum);
            lv2_name = new Lilv.Node.uri (world, Core._name);
            lv2_reports_latency = new Lilv.Node.uri (world, Core._reportsLatency);
            lv2_sample_rate = new Lilv.Node.uri (world, Core._sampleRate);
            lv2_symbol = new Lilv.Node.uri (world, Core._symbol);
            lv2_toggled = new Lilv.Node.uri (world, Core._toggled);
            midi_midi_event = new Lilv.Node.uri (world, MIDI._MidiEvent);
            pg_group = new Lilv.Node.uri (world, PortGroups._group);
            pprops_logarithmic = new Lilv.Node.uri (world, PortProps._logarithmic);
            pprops_no_on_gui = new Lilv.Node.uri (world, PortProps._notOnGUI);
            pprops_range_steps = new Lilv.Node.uri (world, PortProps._rangeSteps);
            pset_preset = new Lilv.Node.uri (world, Presets._Preset);
            pset_bank = new Lilv.Node.uri (world, Presets._bank);
            rdfs_comment = new Lilv.Node.uri (world, NS.RDFS + "comment");
            rdfs_label = new Lilv.Node.uri (world, NS.RDFS + "label");
            rdfs_range = new Lilv.Node.uri (world, NS.RDFS + "range");
            rsz_minimim_size = new Lilv.Node.uri (world, ResizePort._minimumSize);
            ui_show_interface = new Lilv.Node.uri (world, LV2.UI._showInterface);
            work_interface = new Lilv.Node.uri (world, Worker._interface);
            work_schedule = new Lilv.Node.uri (world, Worker._schedule);
            end = null;
        }
    }
}
