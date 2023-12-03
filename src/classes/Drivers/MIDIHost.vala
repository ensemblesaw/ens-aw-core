using Ensembles.Models;
using PortMidi;

namespace Ensembles.ArrangerWorkstation.Drivers {
    /**
     * MIDI input / ouput host.
     */
    internal class MIDIHost : Object {
        public const uint16 BUFFER_SIZE = 256;
        public bool mapped_input { get; set construct; }

        public unowned AudioEngine.ISynthEngine synth_engine { get; construct; }

        private Fluid.Settings midi_driver_settings;
        private Fluid.MIDIDriver midi_driver;

        private Thread device_monitor_thread;
        private bool input_stream_connected;
        private MIDIDevice[] midi_devices;
        private List<int> active_inputs;
        private PortMidi.Stream[] streams;
        private Gee.HashMap<uint8, uint8> channel_layer_map;
        private Gee.HashMap<uint8, uint8> note_map;
        private Gee.HashMap<uint8, uint8> control_map;
        private Gee.HashMap<uint8, string> control_label_reverse_map;

        public signal bool configure (uint8 channel, uint8 value, uint8 type);
        //  public signal void on_note (uint8 key, bool pressed, uint8 velocity, uint8 layer);
        public signal void on_receive (MIDIEvent event);

        public MIDIHost (AudioEngine.ISynthEngine synth_engine, bool mapped_input) {
            Object (
                synth_engine: synth_engine,
                mapped_input: mapped_input
            );

            if (mapped_input) {
                active_inputs = new List<int> ();
                note_map = new Gee.HashMap<uint8, uint8> ();
                control_map = new Gee.HashMap<uint8, uint8> ();
                control_label_reverse_map = new Gee.HashMap<uint8, string> ();

                PortMidi.initialize ();
            } else {
                midi_driver = new Fluid.MIDIDriver (
                    midi_driver_settings,
                    (midi_input_host, midi_event) => {
                        var _midi_input_host = (MIDIHost) midi_input_host;
                        return _midi_input_host.synth_engine.send_f_midi (midi_event);
                    },
                    this
                );
            }
        }

        construct {
            if (!mapped_input) {
                midi_driver_settings = new Fluid.Settings ();
                midi_driver_settings.setstr ("midi.portname", "Ensembles AW 300");
            }
        }

        public unowned MIDIDevice[] refresh () {
            if (!mapped_input) {
                midi_devices = new MIDIDevice[0];
                return midi_devices;
            }

            PortMidi.terminate ();
            Thread.usleep(200);
            PortMidi.initialize ();
            int n = PortMidi.count_devices ();
            // Let's not search more than 128 devices
            if (n > 127) {
                n = 127;
            }

            midi_devices = new MIDIDevice[n];

            for (uint8 i = 0; i < n; i++) {
                unowned PortMidi.DeviceInfo dev_info = PortMidi.DeviceInfo.from_id (i);
                midi_devices[i] = new MIDIDevice (
                    i,
                    dev_info.name,
                    dev_info.interf,
                    dev_info.input
                );
            }

            streams = new PortMidi.Stream[n];

            return midi_devices;
        }

        public void connect_dev (MIDIDevice device) {
            // Connect new device only if not connected
            if (mapped_input && device.input) {
                if (active_inputs.index (device.id) < 0 && active_inputs.length () < 128) {
                    active_inputs.append (device.id);
                    PortMidi.Stream.open_input (
                        out streams[device.id],
                        device.id,
                        null,
                        BUFFER_SIZE,
                        null);
                }

                //If there are active input devices, start monitoring for MIDI signals
                if (active_inputs.length () > 0 && !input_stream_connected) {
                    input_stream_connected = true;
                    device_monitor_thread = new Thread<void> ("mididevmon", monitor_input);
                }
            }
        }

        public void disconnect_dev (MIDIDevice device) {
            if (mapped_input && device.input) {
                active_inputs.remove (device.id);
                streams[device.id] = null; // This calls Pm_Close

                if (active_inputs.length () == 0) {
                    input_stream_connected = false;
                }
            }
        }

        private void monitor_input () {
            while (input_stream_connected) {
                uint8 n = (uint8) active_inputs.length();
                for (uint8 i = 0; i < n; i++) {
                    if (streams[active_inputs.nth_data (i)].poll() > 0) {
                        var buffer = new PortMidi.Event[BUFFER_SIZE];
                        int nEvents = streams[active_inputs.nth_data (i)].read (buffer);

                        Idle.add (() => {
                            for (int j = 0; j < nEvents; j++) {
                                handle_mapped_event (buffer[j].message);
                            }

                            return false;
                        });

                        Thread.yield ();
                        Thread.usleep (200);
                    }
                }
            }

            // Close all connections when stream ends
            for (int i = 0; i < active_inputs.length (); i++) {
                streams[active_inputs.nth_data (i)] = null;
            }
        }

        protected int handle_mapped_event (PortMidi.Message midi_message) {
            var configuring = false;

            uint8 status = (uint8) midi_message.status ();
            uint8 data1 = (uint8) midi_message.data1 (); // value / key
            uint8 data2 = (uint8) midi_message.data2 (); // velocity

            uint8 channel = status & 0x0F;
            uint8 type = status & 0xF0;

            if (type == MIDIEvent.EventType.NOTE_ON ||
                type == MIDIEvent.EventType.CONTROL_CHANGE
            ) {
                configuring = configure (channel, data1, type);
            }

            if (!configuring) {
                uint8 hash = szudzik_hash (channel, data1);
                if (
                    type == MIDIEvent.EventType.NOTE_ON ||
                    type == MIDIEvent.EventType.NOTE_OFF
                ) {
                    if (note_map.has_key (hash)) {
                        // Process control signal
                    } else {
                        on_receive (
                            new MIDIEvent()
                            .on_channel (17)
                            .of_type (type)
                            .with_key (data1)
                            .of_velocity (data2)
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
