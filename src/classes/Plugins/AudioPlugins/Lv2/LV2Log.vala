namespace Ensembles.ArrangerWorkstation.Plugins.AudioPlugins.Lv2 {
    public class LV2Log {
        public unowned LV2URIDs urids;
        public bool tracing;

        public LV2Log () {
            urids = LV2Manager.urids;
        }

        public int printf (LV2.URID.Urid type, string fmt, ...) {
            var args = va_list();

            return vprintf (type, fmt, args);
        }

        public int vprintf (LV2.URID.Urid type, string fmt, va_list ap) {
            if (type == urids.log_warning) {
                Console.log(fmt.printf (ap), Console.LogLevel.WARNING);
                return 0;
            } else if (type == urids.log_error) {
                Console.log(fmt.printf (ap), Console.LogLevel.ERROR);
                return -1;
            } else if (tracing) {
                Console.log(fmt.printf (ap));
                return 0;
            }

            return 0;
        }
    }
}

[CCode (cname="LV2_LogPrintFunc", instance_pos = 0)]
delegate int LV2LogPrintFunc (LV2.URID.Urid type, string fmt, ...);
