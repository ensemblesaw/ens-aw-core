/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Ensembles.ArrangerWorkstation.AudioEngine {

    /**
     * ## Synthesizer Instance Provider
     *
     * Manages FluidSynth instances and driver configurations.
     */
    public class SynthSettings : Object {
        public Fluid.Settings rendering_settings { get; owned construct; }
        public Fluid.Settings utility_settings { get; owned construct; }

        construct {
            rendering_settings = new Fluid.Settings ();
                utility_settings = new Fluid.Settings ();
        }

        public SynthSettings () {
            rendering_settings.setnum ("synth.gain", 1);
            rendering_settings.setnum ("synth.overflow.percussion", 5000.0);
            rendering_settings.setint ("synth.midi-channels", 64);
            rendering_settings.setstr ("synth.midi-bank-select", "gs");
            rendering_settings.setint ("synth.polyphony", 1024);

            utility_settings.setnum ("synth.overflow.percussion", 5000.0);
            utility_settings.setstr ("synth.midi-bank-select", "gs");
            utility_settings.setint ("synth.cpu-cores", 4);
        }
        /**
         * Sets driver configuration of synthesizer instance
         *
         * This should be called before accessing any synth
         */
        public int configure_driver (ISynthEngine.Driver driver, double buffer_length_multiplier) {
            switch (driver) {
                case ISynthEngine.Driver.ALSA:
                    rendering_settings.setstr ("audio.driver", "alsa");
                    rendering_settings.setint ("audio.periods", 8);
                    rendering_settings.setint ("audio.period-size", (int)(86.0 + (buffer_length_multiplier * 938.0)));
                    rendering_settings.setint ("audio.realtime-prio", 80);

                    utility_settings.setstr ("audio.driver", "alsa");
                    utility_settings.setint ("audio.periods", 16);
                    utility_settings.setint ("audio.period-size", (int)(64.0 + (buffer_length_multiplier * 938.0)));
                    utility_settings.setint ("audio.realtime-prio", 70);

                    return (int)(86.0 + (buffer_length_multiplier * 938.0));
                case ISynthEngine.Driver.PULSEAUDIO:
                    rendering_settings.setstr ("audio.driver", "pulseaudio");
                    rendering_settings.setint ("audio.periods", 8);
                    rendering_settings.setint ("audio.period-size",
                        (int)(1024.0 + (buffer_length_multiplier * 3072.0)));
                    rendering_settings.setint ("audio.realtime-prio", 80);
                    // rendering_settings.setint ("audio.pulseaudio.adjust-latency", 0);

                    utility_settings.setstr ("audio.driver", "pulseaudio");
                    utility_settings.setint ("audio.periods", 2);
                    utility_settings.setint ("audio.period-size", 512);
                    utility_settings.setint ("audio.realtime-prio", 90);
                    utility_settings.setint ("audio.pulseaudio.adjust-latency", 0);

                    return (int)(1024.0 + (buffer_length_multiplier * 3072.0));
                case ISynthEngine.Driver.PIPEWIRE_PULSE:
                    rendering_settings.setstr ("audio.driver", "pulseaudio");
                    rendering_settings.setint ("audio.periods", 8);
                    rendering_settings.setint ("audio.period-size", (int)(512.0 + (buffer_length_multiplier * 3584.0)));
                    rendering_settings.setint ("audio.pulseaudio.adjust-latency", 0);

                    utility_settings.setstr ("audio.driver", "pulseaudio");
                    utility_settings.setint ("audio.periods", 2);
                    utility_settings.setint ("audio.period-size", 512);

                    return (int)(512.0 + (buffer_length_multiplier * 3584.0));
                case ISynthEngine.Driver.JACK:
                    rendering_settings.setnum ("synth.gain", 0.005);
                    rendering_settings.setstr ("audio.driver", "jack");
                    rendering_settings.setstr ("audio.jack.id", "Ensembles Audio Output");

                    utility_settings.setstr ("audio.driver", "jack");
                    utility_settings.setstr ("audio.jack.id", "Ensembles Utility");

                    return 0;
                case ISynthEngine.Driver.PIPEWIRE:
                    rendering_settings.setstr ("audio.driver", "pipewire");
                    rendering_settings.setint ("audio.period-size", (int)(256.0 + (buffer_length_multiplier * 3584.0)));
                    rendering_settings.setint ("audio.realtime-prio", 80);
                    rendering_settings.setstr ("audio.pipewire.media-role", "Production");
                    rendering_settings.setstr ("audio.pipewire.media-type", "Audio");
                    rendering_settings.setstr ("audio.pipewire.media-category", "Playback");

                    utility_settings.setstr ("audio.driver", "pipewire");
                    utility_settings.setint ("audio.period-size", 256);
                    utility_settings.setint ("audio.realtime-prio", 90);
                    utility_settings.setstr ("audio.pipewire.media-role", "Game");
                    utility_settings.setstr ("audio.pipewire.media-type", "Audio");
                    utility_settings.setstr ("audio.pipewire.media-category", "Playback");

                    return (int)(256.0 + (buffer_length_multiplier * 3584.0));
            }

            return 0;
        }
    }
}
