using Ensembles.Models;

namespace Ensembles.ArrangerWorkstation.Drivers {
    /**
     * MIDI input / ouput host.
     */
    internal class MIDIInputHost : Object {
        public bool mapped_input { get; set construct; }

        public unowned AudioEngine.ISynthEngine synth_engine { get; construct; }

        private Fluid.Settings midi_driver_settings;
        private Fluid.MIDIDriver midi_driver;

        private Gee.HashMap<uint8, uint8> channel_layer_map;
        private Gee.HashMap<uint8, uint8> note_map;
        private Gee.HashMap<uint8, uint8> control_map;
        private Gee.HashMap<uint8, string> control_label_reverse_map;

        public signal bool configure (uint8 channel, uint8 value, uint8 type);
        public signal void on_note (uint8 key, bool pressed, uint8 velocity, uint8 layer);

        public MIDIInputHost (AudioEngine.ISynthEngine synth_engine, bool mapped_input) {
            Object (
                synth_engine: synth_engine,
                mapped_input: mapped_input
            );

            midi_driver = new Fluid.MIDIDriver (
                midi_driver_settings,
                (midi_input_host, midi_event) => {
                    var _midi_input_host = (MIDIInputHost) midi_input_host;
                    if (_midi_input_host.mapped_input) {
                        return _midi_input_host.handle_mapped_event (midi_event);
                    }

                    return _midi_input_host.synth_engine.send_f_midi (midi_event);
                },
                this
            );
        }

        construct {
            midi_driver_settings = new Fluid.Settings ();
            midi_driver_settings.setstr ("midi.portname", "Ensembles AW 300");

            if (mapped_input) {
                midi_driver_settings.setint ("midi.autoconnect", 1);
            }
        }

        protected int handle_mapped_event (Fluid.MIDIEvent midi_event) {
            var configuring = false;

            uint8 channel = (uint8) (midi_event.get_channel ());
            uint8 type = (uint8) (midi_event.get_type ());
            uint8 value = (uint8) (midi_event.get_value ());
            uint8 velocity = (uint8) (midi_event.get_channel ());
            uint8 key = (uint8) (midi_event.get_key ());

            if (type == MIDIEvent.EventType.NOTE_ON ||
                type == MIDIEvent.EventType.CONTROL_CHANGE
            ) {
                configuring = configure (channel, value | key, type);
            }

            if (!configuring) {
                uint8 hash = szudzik_hash (channel, value | key);
                if (
                    type == MIDIEvent.EventType.NOTE_ON ||
                    type == MIDIEvent.EventType.NOTE_OFF
                ) {
                    if (note_map.has_key (hash)) {

                    } else {
                        on_note (
                            key,
                            type == MIDIEvent.EventType.NOTE_ON,
                            velocity,
                            channel_layer_map.get (channel)
                        );
                    }
                }
            }

            return Fluid.OK;
        }

        private uint8 szudzik_hash (uint8 a, uint8 b) {
            return a >= b ? a * a + a + b : a + b * b;
        }
    }
}
