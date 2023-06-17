using Ensembles.ArrangerWorkstation.Models;

namespace Ensembles.ArrangerWorkstation.MIDIPlayers {
    public interface IStyleEngine : Object {
        // State signals
        public signal void on_current_part_change (StylePartType part_type);
        public signal void on_next_part_change (StylePartType part_type);
        public signal void on_sync_change (bool active);
        public signal void on_break_change (bool active);

        // Beats
        public signal void beat (bool measure, uint8 beats_per_bar, uint8 bar_division);
        public signal void beat_reset ();
    }
}
