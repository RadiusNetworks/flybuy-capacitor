export interface FlybuyNotifyPlugin {

  /**
   * Update custom template content for Notify campaigns.
   * Call whenever app-specific values change (e.g. loyalty points, user name).
   * Values are available in notification templates as {{ app.key }}.
   *
   * Requires iOS SDK v2.11.6+ and Android SDK v2.15.2+
   *
   * Example template: "Welcome {{ app.name | default: 'valued customer' }}!"
   */
  updateCustomTemplateContent(options: {
    content: Record<string, string>;
  }): Promise<void>;
}
