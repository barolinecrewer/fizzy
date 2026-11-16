import type { PluginHostProps } from "@getpaseo/plugin/client";
import { useRpc } from "@getpaseo/plugin/client";
import { Icon, Modal, ScrollView, TextInput, useToast } from "@getpaseo/plugin/client/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { Pressable, Text, View } from "react-native";
import { callTool } from "../shared/fizzy";
import type { Board, Card, CardDetails, Field, Named, Step } from "../shared/fizzy";

type Styles = ReturnType<typeof useStyles>;

const TRIAGE = "triage";
const REFRESH_MS = 20_000;

function useStyles({ theme, layout }: PluginHostProps) {
  return useMemo(() => {
    const { colors } = theme;
    const input = { color: colors.foreground, borderColor: colors.border, borderWidth: 1, borderRadius: 8, padding: 8 };
    return {
      screen: { flex: 1, backgroundColor: colors.surface0, padding: layout.compact ? 12 : 20, gap: 12 },
      row: { flexDirection: "row" as const, flexWrap: "wrap" as const, alignItems: "center" as const, gap: 8 },
      columns: { flexDirection: layout.compact ? ("column" as const) : ("row" as const), gap: 12, alignItems: "flex-start" as const },
      column: { width: layout.compact ? ("100%" as const) : 280, backgroundColor: colors.surface1, borderRadius: 10, padding: 10, gap: 8 },
      card: { backgroundColor: colors.surface2, borderColor: colors.border, borderWidth: 1, borderRadius: 8, padding: 10, gap: 4 },
      chip: { borderColor: colors.border, borderWidth: 1, borderRadius: 999, paddingVertical: 4, paddingHorizontal: 10 },
      chipActive: { backgroundColor: colors.accent, borderColor: colors.accent },
      chipActiveText: { color: colors.accentForeground },
      title: { color: colors.foreground, fontSize: 16, fontWeight: "600" as const },
      text: { color: colors.foreground },
      muted: { color: colors.foregroundMuted, fontSize: 12 },
      danger: { color: colors.statusDanger },
      done: { color: colors.foregroundMuted, textDecorationLine: "line-through" as const },
      input,
      inputColor: colors.foregroundMuted,
      iconColor: colors.foreground,
      modal: { gap: 14, padding: 4 },
      section: { gap: 6 },
    };
  }, [theme, layout.compact]);
}

/** Calls one of Fizzy's MCP tools through the plugin's daemon process. */
function useFizzy() {
  const call = useRpc(callTool);
  return async <Result,>(tool: string, args: Record<string, unknown> = {}) => (await call({ tool, arguments: args })).data as Result;
}

/** Runs a tool that changes something, then refreshes everything on screen. */
function useAct() {
  const fizzy = useFizzy();
  const queries = useQueryClient();
  const toast = useToast();
  return useMutation({
    mutationFn: ({ tool, args }: { tool: string; args: Record<string, unknown> }) => fizzy(tool, args),
    onSuccess: () => queries.invalidateQueries({ queryKey: ["fizzy"] }),
    onError: (error) => toast.error(error.message),
  });
}

function Chip({ label, active, onPress, styles }: { label: string; active?: boolean; onPress(): void; styles: Styles }) {
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress} style={[styles.chip, active && styles.chipActive]}>
      <Text style={active ? styles.chipActiveText : styles.text}>{label}</Text>
    </Pressable>
  );
}

/** A one-line input that submits on Enter and clears itself. */
function QuickAdd({ placeholder, onSubmit, styles, initial = "" }: { placeholder: string; onSubmit(text: string): void; styles: Styles; initial?: string }) {
  const [text, setText] = useState(initial);
  return (
    <TextInput
      accessibilityLabel={placeholder}
      placeholder={placeholder}
      placeholderTextColor={styles.inputColor}
      value={text}
      onChangeText={setText}
      onSubmitEditing={() => {
        if (text.trim() || initial) onSubmit(text.trim());
        if (!initial) setText("");
      }}
      style={styles.input}
    />
  );
}

function Steps({ steps, number, depth, styles }: { steps: Step[]; number: number; depth: number; styles: Styles }) {
  const act = useAct();
  const [addingTo, setAddingTo] = useState<string | null>(null);
  return (
    <View style={{ gap: 6, paddingLeft: depth ? 20 : 0 }}>
      {steps.map((step) => (
        <View key={step.id} style={{ gap: 6 }}>
          <View style={styles.row}>
            {step.section ? null : (
              <Pressable
                accessibilityRole="checkbox"
                accessibilityState={{ checked: step.completed }}
                accessibilityLabel={step.content}
                onPress={() => act.mutate({ tool: "update_step", args: { number, step_id: step.id, completed: !step.completed } })}
              >
                <Icon name={step.completed ? "SquareCheck" : "Square"} size={18} color={styles.iconColor} />
              </Pressable>
            )}
            <Text style={[step.section ? styles.title : step.completed ? styles.done : styles.text, { flexShrink: 1 }]}>{step.content}</Text>
            {step.assignee ? <Text style={styles.muted}>{step.assignee}</Text> : null}
            <Pressable accessibilityRole="button" accessibilityLabel={`Add a sub-step to ${step.content}`} onPress={() => setAddingTo(addingTo === step.id ? null : step.id)}>
              <Icon name="Plus" size={16} color={styles.inputColor} />
            </Pressable>
          </View>
          <Steps steps={step.steps} number={number} depth={depth + 1} styles={styles} />
          {addingTo === step.id ? (
            <View style={{ paddingLeft: 20 }}>
              <QuickAdd placeholder="Add a sub-step…" styles={styles} onSubmit={(content) => act.mutate({ tool: "add_step", args: { number, content, parent_id: step.id } })} />
            </View>
          ) : null}
        </View>
      ))}
    </View>
  );
}

function FieldEditor({ field, number, styles }: { field: Field; number: number; styles: Styles }) {
  const act = useAct();
  const set = (value: string) => act.mutate({ tool: "set_custom_field", args: { number, field_id: field.id, value } });
  return (
    <View style={styles.section}>
      <Text style={styles.muted}>{field.name}</Text>
      {field.kind === "select" ? (
        <View style={styles.row}>
          {field.options.map((option) => (
            <Chip key={option} label={option} active={field.value === option} styles={styles} onPress={() => set(field.value === option ? "" : option)} />
          ))}
        </View>
      ) : (
        <QuickAdd key={field.value ?? ""} initial={field.value ?? ""} placeholder={field.kind === "date" ? "YYYY-MM-DD" : field.kind === "number" ? "0" : "—"} styles={styles} onSubmit={set} />
      )}
    </View>
  );
}

function CardModal({ number, board, onClose, styles }: { number: number; board: Board; onClose(): void; styles: Styles }) {
  const fizzy = useFizzy();
  const act = useAct();
  const card = useQuery({ queryKey: ["fizzy", "card", number], queryFn: () => fizzy<CardDetails>("get_card", { number }) });
  const templates = useQuery({ queryKey: ["fizzy", "templates"], queryFn: () => fizzy<Named[]>("list_step_templates") });
  const place = card.data ? (card.data.closed ? "closed" : card.data.not_now ? "not_now" : (card.data.column_id ?? TRIAGE)) : null;
  const places: Named[] = [{ id: TRIAGE, name: "Maybe?" }, ...board.columns, { id: "not_now", name: "Not now" }, { id: "closed", name: "Done" }];

  return (
    <Modal title={card.data ? `#${number} ${card.data.title}` : `#${number}`} open onOpenChange={(open) => !open && onClose()}>
      <Modal.Content contentContainerStyle={styles.modal}>
        {card.error ? <Text style={styles.danger}>{card.error.message}</Text> : null}
        {card.data ? (
          <>
            {card.data.description ? <Text style={styles.text}>{card.data.description}</Text> : null}
            <View style={styles.row}>
              {places.map(({ id, name }) => (
                <Chip key={id} label={name} active={place === id} styles={styles} onPress={() => act.mutate({ tool: "move_card", args: { number, destination: id } })} />
              ))}
            </View>

            <View style={styles.section}>
              <Text style={styles.muted}>Steps {card.data.steps_completed}/{card.data.steps_total}</Text>
              <Steps steps={card.data.steps} number={number} depth={0} styles={styles} />
              <QuickAdd placeholder="Add a step… (end with : for a section)" styles={styles} onSubmit={(content) => act.mutate({ tool: "add_step", args: { number, content } })} />
              <View style={styles.row}>
                {templates.data?.map((template) => (
                  <Chip key={template.id} label={`+ ${template.name}`} styles={styles} onPress={() => act.mutate({ tool: "apply_step_template", args: { number, template_id: template.id } })} />
                ))}
              </View>
            </View>

            {card.data.custom_fields.map((field) => (
              <FieldEditor key={field.id} field={field} number={number} styles={styles} />
            ))}

            <View style={styles.section}>
              <Text style={styles.muted}>Assignees</Text>
              <View style={styles.row}>
                {board.users.map((user) => (
                  <Chip key={user.id} label={user.name} active={card.data.assignees.includes(user.name)} styles={styles} onPress={() => act.mutate({ tool: "assign_card", args: { number, user_id: user.id } })} />
                ))}
              </View>
            </View>

            <View style={styles.section}>
              <Text style={styles.muted}>Comments</Text>
              {card.data.comments.map((comment) => (
                <Text key={comment.id} style={styles.text}>
                  <Text style={styles.muted}>{comment.author}: </Text>
                  {comment.body}
                </Text>
              ))}
              <QuickAdd placeholder="Add a comment…" styles={styles} onSubmit={(body) => act.mutate({ tool: "comment_on_card", args: { number, body } })} />
            </View>
          </>
        ) : null}
      </Modal.Content>
    </Modal>
  );
}

function CardTile({ card, onPress, styles }: { card: Card; onPress(): void; styles: Styles }) {
  const details = [card.steps_total ? `☑ ${card.steps_completed}/${card.steps_total}` : "", ...card.assignees, ...card.tags.map((tag) => `#${tag}`)].filter(Boolean);
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={`Open card ${card.number}, ${card.title}`} onPress={onPress} style={styles.card}>
      <Text style={styles.text}>{card.title}</Text>
      <Text style={styles.muted}>{[`#${card.number}`, ...details].join(" · ")}</Text>
    </Pressable>
  );
}

export function BoardView(props: PluginHostProps & { openSettings(): void }) {
  const styles = useStyles(props);
  const fizzy = useFizzy();
  const act = useAct();
  const [chosenBoard, setChosenBoard] = useState<string | null>(null);
  const [openCard, setOpenCard] = useState<number | null>(null);

  const boards = useQuery({ queryKey: ["fizzy", "boards"], queryFn: () => fizzy<Named[]>("list_boards"), retry: false });
  const boardId = chosenBoard ?? boards.data?.[0]?.id;
  const board = useQuery({ queryKey: ["fizzy", "board", boardId], queryFn: () => fizzy<Board>("get_board", { board_id: boardId }), enabled: !!boardId });
  const cards = useQuery({
    queryKey: ["fizzy", "cards", boardId],
    queryFn: () => fizzy<Card[]>("list_cards", { board_id: boardId }),
    enabled: !!boardId,
    refetchInterval: REFRESH_MS,
  });
  const error = boards.error ?? board.error ?? cards.error;
  const columns: Named[] = [{ id: TRIAGE, name: "Maybe?" }, ...(board.data?.columns ?? [])];

  return (
    <ScrollView style={{ flex: 1, backgroundColor: styles.screen.backgroundColor }} contentContainerStyle={styles.screen}>
      <View style={styles.row}>
        {boards.data?.map(({ id, name }) => <Chip key={id} label={name} active={id === boardId} styles={styles} onPress={() => setChosenBoard(id)} />)}
        <Chip label="Settings" styles={styles} onPress={props.openSettings} />
      </View>

      {error ? <Text style={styles.danger}>{error.message}</Text> : null}
      {boards.isLoading || cards.isLoading ? <Text style={styles.muted}>Loading…</Text> : null}

      {board.data && cards.data ? (
        <ScrollView horizontal={!props.layout.compact} contentContainerStyle={styles.columns}>
          {columns.map((column) => {
            const inColumn = cards.data.filter((card) => (card.column_id ?? TRIAGE) === column.id);
            return (
              <View key={column.id} style={styles.column}>
                <Text style={styles.title}>{column.name} <Text style={styles.muted}>{inColumn.length}</Text></Text>
                {inColumn.map((card) => <CardTile key={card.number} card={card} styles={styles} onPress={() => setOpenCard(card.number)} />)}
                <QuickAdd
                  placeholder="Add a card…"
                  styles={styles}
                  onSubmit={(title) => act.mutate({ tool: "create_card", args: { board_id: boardId, title, ...(column.id === TRIAGE ? {} : { column_id: column.id }) } })}
                />
              </View>
            );
          })}
        </ScrollView>
      ) : null}

      {openCard !== null && board.data ? <CardModal number={openCard} board={board.data} styles={styles} onClose={() => setOpenCard(null)} /> : null}
    </ScrollView>
  );
}
