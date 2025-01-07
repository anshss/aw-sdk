import prompts from 'prompts';
import type { LitNetwork } from '@lit-protocol/full-self-signing';

export const promptSelectLitNetwork = async (): Promise<LitNetwork> => {
  const { network } = await prompts({
    type: 'select',
    name: 'network',
    message: 'Select a Lit network:',
    choices: [
      {
        title: 'Datil Dev',
        description: 'Development network',
        value: 'datil-dev',
      },
      {
        title: 'Datil Test',
        description: 'Pre-production test network',
        value: 'datil-test',
      },
      {
        title: 'Datil',
        description: 'Production network',
        value: 'datil',
      },
    ],
  });

  if (!network) {
    console.log('❌ Lit network selection is required to proceed.');
    process.exit(1);
  }

  return network;
};
