import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

export default class FedoraHibernateExtension extends Extension {
    enable() {
        this._hibernateItem = new PopupMenu.PopupMenuItem('Hibernate...');
        this._hibernateItem.connect('activate', () => {
            // Use loginctl to trigger hibernate via logind, which respects
            // PolicyKit permissions configured by the setup script.
            GLib.spawn_command_line_async('loginctl hibernate');
        });

        // Locate the system power submenu in Quick Settings.
        // The internal structure varies slightly between GNOME versions,
        // so we try both known layouts before giving up.
        const systemGroup = Main.panel.statusArea.quickSettings._system;
        if (!systemGroup) {
            console.error('[FedoraHibernate] Could not find Quick Settings system group.');
            return;
        }

        // GNOME 45-48 uses _systemItem.child; GNOME 49+ may expose child directly.
        const container =
            (systemGroup._systemItem && systemGroup._systemItem.child)
                ? systemGroup._systemItem.child
                : systemGroup.child;

        if (!container) {
            console.error('[FedoraHibernate] Could not find system menu container.');
            return;
        }

        // Find the shutdown/power submenu item to attach our button to.
        let shutdownItem = null;
        for (const child of container.get_children()) {
            if (child.constructor.name === 'ShutdownItem') {
                shutdownItem = child;
                break;
            }
        }

        if (shutdownItem && shutdownItem.menu) {
            // Position 2 places the button after Suspend, before Restart.
            shutdownItem.menu.addMenuItem(this._hibernateItem, 2);
        } else {
            console.error('[FedoraHibernate] Could not find power submenu to attach hibernate button.');
        }
    }

    disable() {
        if (this._hibernateItem) {
            this._hibernateItem.destroy();
            this._hibernateItem = null;
        }
    }
}
