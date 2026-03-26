import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

export default class FedoraHibernateExtension extends Extension {
    enable() {
        this._hibernateItem = new PopupMenu.PopupMenuItem('Hibernate...');
        this._hibernateItem.connect('activate', () => {
            GLib.spawn_command_line_async('systemctl hibernate');
        });
        const systemGroup = Main.panel.statusArea.quickSettings._system;
        const container = (systemGroup._systemItem && systemGroup._systemItem.child) ? systemGroup._systemItem.child : systemGroup.child;
        let shutdownItem = null;
        for (const child of container.get_children()) {
            if (child.constructor.name === 'ShutdownItem') { shutdownItem = child; break; }
        }
        if (shutdownItem && shutdownItem.menu) {
            shutdownItem.menu.addMenuItem(this._hibernateItem, 2);
        }
    }
    disable() { if (this._hibernateItem) this._hibernateItem.destroy(); }
}
