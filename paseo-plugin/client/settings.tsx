import type { PluginSurfaceProps } from "@getpaseo/plugin/client";
import { useSettings } from "@getpaseo/plugin/client";
import { SettingsAction, SettingsCard, SettingsInput, SettingsSection, SettingsSwitch } from "@getpaseo/plugin/client/ui";
import { useState } from "react";
import { Text } from "react-native";
import { connection } from "../shared/fizzy";

export function ConnectionSettings({ theme }: PluginSurfaceProps) {
  const settings = useSettings(connection);
  const [draft, setDraft] = useState<Partial<{ url: string; token: string; attachToAgents: boolean }>>({});

  if (settings.status !== "ready") {
    return <Text style={{ color: theme.colors.foregroundMuted, padding: 16 }}>{settings.status === "loading" ? "Loading…" : settings.error}</Text>;
  }

  const values = { ...settings.values, ...draft };
  return (
    <SettingsSection title="Fizzy connection">
      <SettingsCard>
        <SettingsInput
          label="Account URL"
          hint="Your Fizzy address including the account number, like https://fizzy.example.com/1234567"
          initialValue={settings.values.url}
          placeholder="https://fizzy.example.com/1234567"
          onChangeText={(url) => setDraft((old) => ({ ...old, url }))}
        />
        <SettingsInput
          label="Access token"
          hint="A read and write personal access token from your Fizzy profile. Stored on this Paseo host."
          initialValue={settings.values.token}
          secureTextEntry
          onChangeText={(token) => setDraft((old) => ({ ...old, token }))}
        />
        <SettingsSwitch
          label="Give agents Fizzy tools"
          hint="Adds Fizzy's MCP server to every agent this host opens."
          value={values.attachToAgents}
          onValueChange={(attachToAgents) => setDraft((old) => ({ ...old, attachToAgents }))}
        />
        <SettingsAction
          label="Save"
          error={settings.saveError}
          actionLabel={settings.saving ? "Saving…" : "Save"}
          disabled={settings.saving}
          onPress={() => void settings.save(values, settings.revision).then((saved) => saved && setDraft({}))}
        />
      </SettingsCard>
    </SettingsSection>
  );
}
