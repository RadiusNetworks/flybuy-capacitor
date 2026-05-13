import { WebPlugin } from '@capacitor/core';
import type { FlybuyNotifyPlugin } from './definitions';

export class FlybuyNotifyWeb extends WebPlugin implements FlybuyNotifyPlugin {

  private notSupported(method: string): never {
    throw this.unimplemented(`${method} is not supported on web.`);
  }

  async updateCustomTemplateContent(_options: { content: Record<string, string> }): Promise<void> {
    return this.notSupported('updateCustomTemplateContent');
  }

  async sync(_options: { force: boolean }): Promise<void> {
    return this.notSupported('sync');
  }
}