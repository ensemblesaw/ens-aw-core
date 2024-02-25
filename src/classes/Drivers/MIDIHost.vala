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
        private Gee.HashMap<uint8, uint8> channel_map;
        private Gee.HashMap<uint32, uint16> event_map;
        private Gee.HashMap<uint8, string> event_label_reverse_map;

        public signal bool configure_route (uint32 route_sig, uint8 type, uint8 channel, uint8 cc);
        public signal void on_receive (MIDIEvent event);
        public signal void control (uint16 route, MIDIEvent event);

        public MIDIHost (AudioEngine.ISynthEngine synth_engine, bool mapped_input) {
            Object (
                synth_engine: synth_engine,
                mapped_input: mapped_input
            );

            if (mapped_input) {
                active_inputs = new List<int> ();
                event_map = new Gee.HashMap<uint32, uint16> ();
                event_label_reverse_map = new Gee.HashMap<uint8, string> ();
                channel_map = new Gee.HashMap<uint8, uint8> ();

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

        public void map_channel (uint8 source_channel, uint8 destination_channel) {
            channel_map.set (source_channel, destination_channel);
        }

        public void map_control (uint32 route_sig, uint16 control_route) {
            event_map[route_sig] = control_route;
        }

        protected int handle_mapped_event (PortMidi.Message midi_message) {
            var configuring = false;

            uint8 status = (uint8) midi_message.status ();
            uint8 cc = (uint8) midi_message.data1 (); // cc / key
            uint8 value = (uint8) midi_message.data2 (); // value / velocity

            uint8 channel = status & 0x0F;
            uint8 type = status & 0xF0;

            uint32 route_sig = hash (channel, type, cc);

            if (type == MIDIEvent.EventType.NOTE_ON ||
                type == MIDIEvent.EventType.CONTROL_CHANGE
            ) {
                configuring = configure_route (route_sig, type, channel, cc);
            }

            if (configuring){
                print("Conf\n");
            }

            if (!configuring) {
                if (
                    type == MIDIEvent.EventType.NOTE_ON ||
                    type == MIDIEvent.EventType.NOTE_OFF
                ) {
                    Console.log(route_sig.to_string ());
                    if (event_map.has_key (route_sig)) {
                        // Process note as control signal
                        Console.log("Controlling[%u]".printf (event_map[route_sig]));
                        if (type == MIDIEvent.EventType.NOTE_ON) {
                            control (
                                event_map[route_sig],
                                new MIDIEvent()
                                .on_channel (channel)
                                .of_type (type)
                                .with_value (cc)
                            );
                        }
                    } else {
                        on_receive (
                            new MIDIEvent()
                            .on_channel (channel_map.get (channel))
                            .of_type (type)
                            .with_key (cc)
                            .of_velocity (value)
                        );
                    }
                } else if (type == MIDIEvent.EventType.CONTROL_CHANGE) {
                    if (event_map.has_key (route_sig)) {
                        control (
                            event_map[route_sig],
                            new MIDIEvent()
                            .on_channel (channel)
                            .of_type (type)
                            .with_value (value)
                        );
                    }
                }
            }

            return Fluid.OK;
        }

        private uint32 hash (uint8 a, uint8 b, uint8 c) {
            return (uint32)a << 16 | (uint32)b << 8 | c;
        }
    }
}
