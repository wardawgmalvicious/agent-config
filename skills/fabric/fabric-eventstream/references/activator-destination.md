# Activator destination — set alert from Eventstream

Preview. The in-place Rules pane, its condition shapes, and available actions.

Configure rules in-place without leaving Eventstream. Add an Activator destination, then select the **alert icon** on it to open the **Rules** pane:

- **View** all rules linked to this Eventstream's Activator item
- **Stop / start** a rule with the toggle
- **Edit / delete** via the `…` menu
- **Add rule** at the bottom of the pane
- **Open in Activator** to manage activation history and test notifications

Rule condition shapes:

| `Check` value | When the action fires |
|---|---|
| **on each event** | Every event flowing through the stream |
| **On each event when** | Events matching a single-field condition (e.g. `No_Empty_Docs == 0`) |
| **On each event grouped by** | Same condition, evaluated per group on a chosen field (e.g. `Neighborhood`) |

Actions: Teams message, email, webhook, Power Automate, custom action.
