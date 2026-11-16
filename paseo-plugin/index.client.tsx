import type { PluginClientContext, PluginHostProps, PluginSidebarItemProps } from "@getpaseo/plugin/client";
import { SidebarRow } from "@getpaseo/plugin/client/ui";
import { BoardView } from "./client/board";
import { ConnectionSettings } from "./client/settings";

export default function contribute(client: PluginClientContext) {
  const Board = (props: PluginHostProps) => <BoardView {...props} openSettings={() => client.openSettings("connection")} />;

  function BoardItem({ currentScreen, openScreen }: PluginSidebarItemProps) {
    return <SidebarRow icon="Kanban" label="Fizzy" active={currentScreen?.screenId === "board"} onPress={() => openScreen({ screenId: "board" })} />;
  }

  client.addSettingsScreen({ id: "connection", title: "Fizzy", icon: "Kanban", Component: ConnectionSettings });
  client.addScreen({ id: "board", title: "Fizzy", Component: Board });
  client.addSidebarHeaderItem({ id: "board", title: "Fizzy", Component: BoardItem });
  client.addWorkspacePanel({ id: "board", title: "Fizzy", icon: "Kanban", Component: Board });
  client.addCommandCenterItem({
    id: "open-board",
    title: "Open Fizzy board",
    icon: "Kanban",
    keywords: ["kanban", "cards", "tasks"],
    context: "global",
    onSelect: ({ openScreen }) => openScreen({ screenId: "board" }),
  });
  return () => {};
}
