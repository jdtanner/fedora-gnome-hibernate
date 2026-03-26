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

        let shutdownItem = null;
        const systemGroup = Main.panel.statusArea.quickSettings._system;
        if (systemGroup) {
            const container = (systemGroup._systemItem && systemGroup._systemItem.child) 
                              ? systemGroup._systemItem.child 
                              : systemGroup.child;

            if (container && typeof container.get_children === 'function') {
                for (const child of container.get_children()) {
                    if (child.constructor.name === 'ShutdownItem') {
                        shutdownItem = child;
                        break;
                    }
                }
            }
        }

        if (shutdownItem && shutdownItem.menu) {
            let insertIndex = 2; 
            let items = shutdownItem.menu._getMenuItems();
            for (let i = 0; i < items.length; i++) {
                if (items[i] instanceof PopupMenu.PopupSeparatorMenuItem) {
                    insertIndex = i;
                    break;
                }
            }
            shutdownItem.menu.addMenuItem(this._hibernateItem, insertIndex);
        } else {
            Main.panel.statusArea.quickSettings.menu.addMenuItem(this._hibernateItem);
        }
    }

    disable() {
        if (this._hibernateItem) {
            this._hibernateItem.destroy();
            this._hibernateItem = null;
        }
    }
}
